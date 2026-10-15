# Week 6 lab: Sort cells by area
# Make this script print the lines shown on the lab page.
# Do one step at a time, and press Run after every step.

# The inputs. Keep these three lines exactly as they are:
# the checker changes them to test that your script works for any cell library.
# Each cell is a pair: its name, then its rectangle {x1 y1 x2 y2} in um.
set cells {{INV {0 0 3 10}} {NAND2 {0 0 5 10}} {DFF {0 0 14 10}} {NOR2 {0 0 6 10}} {BUF {0 0 4 10}}}
# How many of the largest cells to name on the "Largest" line.
set topCount 3
# The cell whose rank to look up.
set findCell NOR2

# Step 1: print how many cells there are.

# Step 2: build a list of {name area} pairs, one per cell.

# Step 3: sort the pairs, largest area first, and print one numbered line per cell.

# Step 4: make a list of the names in sorted order, with lmap.

# Step 5: print the names of the topCount largest cells, separated by ", ".

# Step 6: print the rank of findCell, or that it was not found.

