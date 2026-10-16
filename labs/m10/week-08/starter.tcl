# Week 8 lab: Check the layer names
# Make this script print the lines shown on the lab page.
# Do one step at a time, and press Run after every step.

# The inputs. Keep these three lines exactly as they are:
# the checker changes them to test that your script works for any list of names.
# The layer names, as people typed them.
set rawNames {METAL1_drawing { poly_drawing } METAL2_pin VIA1-drawing METAL7_drawing Metal1_Pin ACTIVE CONTACT_fill}
# The layers of Lumen-1.
set knownLayers {ACTIVE POLY CONTACT METAL1 VIA1 METAL2 TEXT}
# The purposes this check accepts.
set knownPurposes {drawing pin}

# Step 1: loop over rawNames. Clean each name: trim the spaces at both ends,
# then replace every - with _.

# Step 2: if the clean name has no _, print that it has no purpose (name in capitals).

# Step 3: otherwise, cut it at the first _ into a layer (in capitals) and a purpose (in lower case).

# Step 4: check the layer, then the purpose, and print one OK or BAD line. Count the OK names.

# Step 5: after the loop, print how many names are valid, with the share in % rounded to 1 decimal.
