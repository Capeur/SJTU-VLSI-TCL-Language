// The TclRuntime interface hides which Tcl-in-the-browser engine is used (PRD §16):
// swap WaclRuntime for another implementation without touching any component.

export interface TclRunResult {
    ok: boolean;
    stdout: string;
    stderr: string;
    error: string;
    timedOut: boolean;
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

// Tcl run before every script so one run cannot see variables, procs or namespaces from another.
const RESET_SCRIPT = `
foreach __v [info vars ::*] { if {[lsearch -exact $::__keepVars $__v] < 0} { catch {unset $__v} } }
foreach __p [info procs ::*] { if {[lsearch -exact $::__keepProcs $__p] < 0} { catch {rename $__p {}} } }
foreach __n [namespace children ::] { if {[lsearch -exact $::__keepNs $__n] < 0} { catch {namespace delete $__n} } }
unset -nocomplain __v __p __n
`;
const SNAPSHOT_SCRIPT = `
set ::__keepVars [concat [info vars ::*] ::__keepVars ::__keepProcs ::__keepNs]
set ::__keepProcs [info procs ::*]
set ::__keepNs [namespace children ::]
`;

interface WorkerReply {
    id?: number;
    ready?: boolean;
    fatal?: string;
    ok?: boolean;
    stdout?: string;
    stderr?: string;
    error?: string;
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
                    // Snapshot the pristine interpreter, then report ready.
                    this.send(SNAPSHOT_SCRIPT).then(() => resolve());
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
                this.ready = null;
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
        await this.send(RESET_SCRIPT);
        let script = code;
        if (options.stdin !== undefined) {
            script = `set stdinText {${options.stdin.replace(/[{}\\]/g, '\\$&')}}\n${code}`;
        }
        const timeout = new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), timeoutMs));
        const outcome = await Promise.race([this.send(script), timeout]);
        if (outcome === 'timeout') {
            this.kill(); // a runaway script can only be stopped by killing the worker
            return { ok: false, stdout: '', stderr: '', error: '', timedOut: true };
        }
        return {
            ok: outcome.ok ?? false,
            stdout: cleanLines(outcome.stdout),
            stderr: cleanLines(outcome.stderr),
            error: cleanLines(outcome.error),
            timedOut: false,
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
