# Week 7 lab: rectArea and rectOverlaps
# Write two procs, then use them to check a floorplan.
# Do one step at a time, and press Run after every step.

# The input. Keep this line exactly as it is:
# the checker changes it to test that your script works for any floorplan.
# Each block is a pair: its name, then its rectangle {x1 y1 x2 y2} in um.
set plan {{ALU {30 30 90 80}} {REGS {90 30 140 80}} {CTRL {141 30 200 79}} {CACHE {140 80 200 170}} {FPU {30 90 145 170}}}

# Step 1: write the proc rectArea. It takes one rectangle and returns its area.

# Step 2: write the proc rectOverlaps. It takes two rectangles and returns 1 if they
# overlap OR TOUCH (touching counts), and 0 if there is space between them.

# Step 3: print one line per block with its area.

# Step 4: check every pair of blocks once, and print one line per conflict.

# Step 5: print the number of conflicts.

