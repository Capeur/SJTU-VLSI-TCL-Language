// Builds the Tcl scripts that grade a lab (PRD §11), for the browser "Check" button and for CI.
// A gradable lab folder has:
//   starter.tcl          the learner's starting file
//   data/*               input files; each becomes the Tcl variable labData(<file name>)
//   tests/checker.tcl    pure Tcl (no file I/O): defines `labCheck learnerCode`, returns the report text
//   tests/test.tcl       terminal wrapper: reads the files, calls labCheck, prints the report
//   tests/selftest.tcl   optional: pure Tcl checks of the checker itself (run on 8.6, 9.0 and Wacl)
// The browser cannot read files, so the same file contents are embedded into the script here.
import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();

/** Same rule as tclQuote in src/lib/tclRuntime.ts: one Tcl word that evaluates to exactly `text`. */
export function tclQuote(text) {
    return `"${text.replace(/[\\$[\]"]/g, '\\$&')}"`;
}

export function labDir(id) {
    // id like "m10/week-03"
    return path.join(root, 'labs', id);
}

export function isGradable(dir) {
    return fs.existsSync(path.join(dir, 'tests', 'checker.tcl'));
}

function read(file) {
    return fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
}

export function labStarter(id) {
    return read(path.join(labDir(id), 'starter.tcl'));
}

/** Sets labData(...) and labStarter, then defines the checker procs. */
export function labPrelude(dir) {
    const lines = [];
    const dataDir = path.join(dir, 'data');
    if (fs.existsSync(dataDir)) {
        for (const name of fs.readdirSync(dataDir).sort()) {
            lines.push(`set labData(${name}) ${tclQuote(read(path.join(dataDir, name)))}`);
        }
    }
    lines.push(`set labStarter ${tclQuote(read(path.join(dir, 'starter.tcl')))}`);
    lines.push(read(path.join(dir, 'tests', 'checker.tcl')));
    return lines.join('\n');
}

/** Script for TclPlayground's `check` prop: expects the variable learnerCode. */
export function labCheckScript(id) {
    return `${labPrelude(labDir(id))}\nputs [labCheck $learnerCode]\n`;
}

/** Script that tests the checker itself, or null if the lab has no selftest. */
export function labSelftestScript(dir) {
    const file = path.join(dir, 'tests', 'selftest.tcl');
    if (!fs.existsSync(file)) return null;
    return `${labPrelude(dir)}\n${read(file)}`;
}
