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
