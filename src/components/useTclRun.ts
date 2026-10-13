import { useState, useCallback } from 'preact/hooks';
import { getRuntime, type TclRunResult } from '../lib/tclRuntime';

export type RunPhase = 'idle' | 'loading' | 'running' | 'done';

/** Shared by TclPlayground and PredictOutput. The interpreter loads on the first run only. */
export function useTclRun() {
    const [phase, setPhase] = useState<RunPhase>('idle');
    const [result, setResult] = useState<TclRunResult | null>(null);
    const [failure, setFailure] = useState('');

    const run = useCallback(async (code: string, opts: { drvlite?: boolean; stdin?: string } = {}) => {
        setFailure('');
        setResult(null);
        const runtime = getRuntime();
        setPhase('loading');
        try {
            await runtime.init();
        } catch (e) {
            setPhase('idle');
            setFailure(`The Tcl engine could not start (${(e as Error).message}). Try reloading the page, or run the code with tclsh on your computer.`);
            return null;
        }
        setPhase('running');
        const res = await runtime.run(code, opts);
        setResult(res);
        setPhase('done');
        return res;
    }, []);

    return { phase, result, failure, run };
}

export const TIMEOUT_MESSAGE =
    'This took longer than 5 seconds, so we stopped it. Is there an infinite loop? Check that every while loop changes the thing it tests.';

export const OUTPUT_LIMIT_MESSAGE =
    'Your script printed far too much, so we stopped it. Does your loop ever stop? Check that every while loop changes the thing it tests. The start of the output is below.';

export const CRASH_MESSAGE =
    'Your script used up all the memory that Tcl has in this page, so we stopped it and started a fresh Tcl. Does your loop ever stop? Fix the script and press Run again: no need to reload the page.';

/** The friendly message for a run that was stopped, or '' for a normal run (shared by every component). */
export function runProblem(result: TclRunResult | null): string {
    if (!result) return '';
    if (result.timedOut) return TIMEOUT_MESSAGE;
    if (result.crashed) return CRASH_MESSAGE;
    if (result.outputLimit) return OUTPUT_LIMIT_MESSAGE;
    return '';
}
