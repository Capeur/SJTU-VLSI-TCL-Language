# Week 9 lab: The layer table
# Make this script print the lines shown on the lab page.
# Do one step at a time, and press Run after every step.

# The inputs. Keep these three lines exactly as they are:
# the checker changes the last two to test that your script works for any list of shapes.
# The teaching layers of Lumen-1 and their GDS numbers (layer.datatype). This is a dict.
set layerNumbers {ACTIVE 1.0 POLY 2.0 CONTACT 3.0 METAL1 4.0 VIA1 5.0 METAL2 6.0 TEXT 63.0}
# The layer of each shape in a small layout, one element per shape.
set shapeLayers {METAL1 POLY METAL1 ACTIVE VIA1 METAL7 METAL1 METAL2 ACTIVE}
# The layer to look up in the table.
set lookUp METAL1

# Step 1: print the names of the layers, in table order.

# Step 2: build the dict "layers": for each layer, a record {number N datatype D purpose drawing}.

# Step 3: print the record of lookUp, or that it is not in the table.

# Step 4: count the shapes on each layer of the table, with an array. Remember the unknown layers too.

# Step 5: print one line per layer of the table, in table order, with its GDS number and its count.

# Step 6: print the unknown layers, sorted, then the totals.
