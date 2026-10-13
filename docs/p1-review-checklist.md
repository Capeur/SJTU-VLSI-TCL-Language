# P1 manual review checklist

Run `npm run dev` and open <http://localhost:4321/SJTU-VLSI-TCL-Language/demo/>.

## Keyboard only (no mouse)
1. Press Tab from the top of the page. Focus should always be visible and should reach every control, then continue to the footer (no trap).
2. Playground: Tab into the code box, type, press Ctrl+Enter. Output appears below.
3. Predict → Run: Run stays disabled until you type a prediction.
4. Faded example: Tab between the blanks; each blank turns green/red as you type.
5. Hints: Enter/Space shows the next hint (max 3).
6. Run-where tabs: Left/Right arrows switch tabs; the disabled tab is skipped.
7. Glossary terms: Tab to a term; the tooltip shows. Enter follows the link.
8. Worked example: Tab to a note; its code line highlights.
9. Quizzes: choose with arrows/Space, Check with Enter, Next with Enter. Order-steps uses the ↑/↓ buttons.

## Things to eyeball
- Light and dark theme (Starlight toggle): all boxes readable, buttons have clear contrast.
- Phone width (~400 px): code scrolls sideways inside its box, nothing overflows the page.
- Type `while {1} {}` in the playground and press Run: after about 5 s you get the "infinite loop?" message and the playground still works.
- Wrong quiz answers show up in "Flashcards" after a reload.
- Browser with site data blocked: the page still works and ProgressTracker shows a warning.
