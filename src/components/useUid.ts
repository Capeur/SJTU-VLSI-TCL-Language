import { useState } from 'preact/hooks';

let counter = 0;

/** A document-unique id per component instance, so ids and radio-group names never collide. */
export function useUid(prefix: string): string {
    const [uid] = useState(() => `${prefix}-${++counter}`);
    return uid;
}
