# Week 4 lab: Is this wire wide enough?
# Make this script print the lines shown on the lab page.
# Do one step at a time, and press Run after every step.

# The inputs, in um. Keep these five lines exactly as they are:
# the checker changes them to test your decisions and your loop.
set wireName CLK
set wireWidth 2
set minWidth 3
set minSpace 2
set channelWidth 20

# Step 1: print the wire line: its name, its width and the minimum width.

# Step 2: print the result line. It says TOO NARROW, or OK, AT THE MINIMUM, or OK.

# Step 3: print one line per track that fits in the channel.
# The first track starts minSpace away from CORE, at x = minSpace.
# A track fits if x + minWidth + minSpace is not more than channelWidth.

# Step 4: print how many tracks fit.

