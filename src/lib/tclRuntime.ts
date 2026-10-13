// The TclRuntime interface hides which Tcl-in-the-browser engine is used (PRD §16):
// swap WaclRuntime for another implementation without touching any component.
// Every component that runs learner code (TclPlayground, PredictOutput, the LayoutCanvas of P5) must
// go through this runtime, usually via useTclRun, so that the timeout, the output limit and the
// restart after an out-of-memory crash protect it too.

export interface TclRunResult {
    ok: boolean;
    stdout: string;
    stderr: string;
    error: string;
    timedOut: boolean;
    /** The script printed more than the worker's limit and was stopped (stdout holds the start). */
    outputLimit: boolean;
    /** The engine ran out of memory. It has been thrown away; the next run starts a fresh one. */
    crashed: boolean;
}

export interface TclRunOptions {
    timeoutMs?: number;
    /** Reserved for P5: preload DRV-Lite before running. */
    drvlite?: boolean;
    /** Text made available as the Tcl variable `stdinText` (the browser has no real stdin). */
    stdin?: string;
}

export interface TclRuntime {
    /** Start the engine. Safe to call many times. */
    init(): Promise<void>;
    run(code: string, options?: TclRunOptions): Promise<TclRunResult>;
}

export const DEFAULT_TIMEOUT_MS = 5000;

interface WorkerReply {
    id?: number;
    ready?: boolean;
    fatal?: string;
    ok?: boolean;
    stdout?: string;
    stderr?: string;
    error?: string;
    outputLimit?: boolean;
    crashed?: boolean;
}

function cleanLines(text: string | undefined): string {
    return (text ?? '').replace(/\r/g, '');
}

export class WaclRuntime implements TclRuntime {
    private worker: Worker | null = null;
    private ready: Promise<void> | null = null;
    private nextId = 1;
    private pending = new Map<number, (reply: WorkerReply) => void>();
    private readonly workerUrl: string;

    constructor(workerUrl: string) {
        this.workerUrl = workerUrl;
    }

    init(): Promise<void> {
        if (this.ready) return this.ready;
        this.ready = new Promise<void>((resolve, reject) => {
            const worker = new Worker(this.workerUrl);
            this.worker = worker;
            worker.onmessage = (event: MessageEvent<WorkerReply>) => {
                const msg = event.data;
                if (msg.ready) {
                    resolve();
                } else if (msg.fatal) {
                    this.ready = null;
                    reject(new Error(msg.fatal));
                } else if (msg.id !== undefined) {
                    const done = this.pending.get(msg.id);
                    this.pending.delete(msg.id);
                    if (done) done(msg);
                }
            };
            worker.onerror = (event) => {
                if (this.worker !== worker) return;   // an old worker that was already replaced
                // Before ready: the engine could not start. After ready: the worker itself died
                // (for example out of memory outside Wacl), so finish every waiting run as crashed.
                for (const done of this.pending.values()) done({ ok: false, crashed: true });
                this.kill();
                reject(new Error(event.message || 'The Tcl engine failed to start.'));
            };
        });
        return this.ready;
    }

    private send(code: string): Promise<WorkerReply> {
        return new Promise((resolve) => {
            const id = this.nextId++;
            this.pending.set(id, resolve);
            this.worker!.postMessage({ id, code });
        });
    }

    private kill(): void {
        this.worker?.terminate();
        this.worker = null;
        this.ready = null;
        this.pending.clear();
    }

    async run(code: string, options: TclRunOptions = {}): Promise<TclRunResult> {
        await this.init();
        const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
        let script = code;
        if (options.stdin !== undefined) {
            script = `set stdinText ${tclQuote(options.stdin)}\n${code}`;
        }
        const timeout = new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), timeoutMs));
        const outcome = await Promise.race([this.send(script), timeout]);
        if (outcome === 'timeout') {
            this.kill(); // a runaway script can only be stopped by killing the worker
            return { ok: false, stdout: '', stderr: '', error: '', timedOut: true, outputLimit: false, crashed: false };
        }
        if (outcome.crashed) {
            // Out of memory: that interpreter can never run again. Drop it; the next run() starts a
            // fresh worker through init(), so the learner does not have to reload the page.
            this.kill();
            return { ok: false, stdout: '', stderr: '', error: '', timedOut: false, outputLimit: false, crashed: true };
        }
        return {
            ok: outcome.ok ?? false,
            stdout: cleanLines(outcome.stdout),
            stderr: cleanLines(outcome.stderr),
            error: cleanLines(outcome.error),
            timedOut: false,
            outputLimit: outcome.outputLimit ?? false,
            crashed: false,
        };
    }
}

let shared: TclRuntime | null = null;

/** One shared interpreter per page, created lazily so Wacl only downloads on first Run. */
export function getRuntime(): TclRuntime {
    if (!shared) {
        const base = (import.meta.env?.BASE_URL ?? '/').replace(/\/?$/, '/');
        shared = new WaclRuntime(`${base}wacl/worker.js`);
    }
    return shared;
}

/**
 * Turn any text into one Tcl word that evaluates back to exactly that text. Inside double quotes,
 * backslash substitution removes the backslashes again. (Escaping braces inside a braced word does
 * NOT work: Tcl keeps the backslashes.) Keep in sync with tclQuote in src/lib/labs.mjs.
 */
export function tclQuote(text: string): string {
    return `"${text.replace(/[\\$[\]"]/g, '\\$&')}"`;
}

/** Normalise output for comparison: trim trailing whitespace on every line and at the end. */
export function normaliseOutput(text: string): string {
    return text.replace(/\r/g, '').split('\n').map((line) => line.replace(/\s+$/, '')).join('\n').replace(/\s+$/, '');
}

/** Code that touches the host machine cannot run in the browser (PRD §7 RunWhere). */
export function hostFeatureProblem(code: string): string | null {
    const checks: [RegExp, string][] = [
        [/(^|[\s;\[{])exec\s/m, 'uses exec (runs other programs)'],
        [/(^|[\s;\[{])open\s/m, 'uses open (real files)'],
        [/(^|[\s;\[{])glob\s/m, 'uses glob (searches real folders)'],
        [/(^|[\s;\[{])socket\s/m, 'uses socket (network)'],
        [/\bgets\s+stdin\b/, 'reads from stdin'],
    ];
    for (const [pattern, reason] of checks) {
        if (pattern.test(code)) return reason;
    }
    return null;
}
