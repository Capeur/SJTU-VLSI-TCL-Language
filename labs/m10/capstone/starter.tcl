# M10 capstone: Mini Floorplan Checker
# Make this script print the report shown on the capstone page.
# Work one step at a time, and press Run after every step.

# The inputs. Keep these four lines exactly as they are:
# the checker changes them to test that your script works for any chip and any list of blocks.
set chipName Lumen-1
set chipWidth 400
set chipHeight 300
# Each block is {name x y w h} in um: its bottom-left corner, then its width and height.
# The first five are Lumen-1's blocks; the others are proposed new blocks, and some entries are bad.
set blocks {{CORE 20 20 200 160} {SRAM 240 20 140 160} {ADC 20 200 120 80} {SENSOR 160 200 100 80} {PADS 280 200 100 80} {TIMER 220 40 20 40} {LDO 382 20 18 60} {BIAS 150 150 40 40} {TEST 300 285 120 10} {FUSE 10 10 20} {LOGO 5 290 ten 8} {SPARE 0 0 -5 10}}

# Step 1: the procs. The checker calls each one with its own test cases, so use exactly these names.
#   rectArea rect          area of {x1 y1 x2 y2}                          (Week 7)
#   rectOverlaps a b       1 if they overlap OR TOUCH, 0 if not           (Week 7)
#   blockRect block        {name x y w h} -> {x1 y1 x2 y2}
#   rectInside rect boundary   1 if inside; touching the boundary is allowed
#   checkBlock block       returns nothing for a good block, or raises an error with the exact message

# Step 2: print the first line.

# Step 3: check every block with checkBlock inside try. Keep the good ones; print a Skipped line
# for each bad one. Then print the Skipped count.

# Step 4: print one area line per good block, then the Total of the blocks INSIDE the chip.

# Step 5: print the Outside lines, then the Conflict lines (every pair of good blocks once),
# then the number of Problems.
