# test_core.Hello.tcl
#
# Testing drcl.inet.data.InterfaceInfo, drcl.inet.contract.IFQuery
# and component drcl.inet.core.Hello
#
# Topology:
# n0 --------- n1
# |\           |
# | \--------\ +---n4
# |           \|
# n2 --------- n3
#
# Note: n1, n3 and n4 are connected on a single wire,
# 	The NIC is not ethernet thought.  Assume that no collision will ever occur.
#
# - Normal operations:
#   - After the simulation runs, one can see the "neighbor up" events fired by each node.
#   - Use "cat n?/.../hello" to observe the neighbors the nodes come up.
#
# - Topology dynamics:
#   - Use "disconnect n4/0@" to bring down one link and observe the "neighbor down" events.
#   - Use "connect n4/0@ -and .link3/2@" to bring back the link and observe the "neighbor up" events.

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 4 {{1 2 3} {3 0} {0 3} {0 1 2}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_

# add node 4
mkdir drcl.inet.Node n4
! n4 addAddress 4
connect -c .link3/2@ -and n4/0@

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder nodeBuilder]
mkdir $nb/.if@
$nb build [! n?]

# observe interface events at tester
watch -label NEIGHBOR -add n?/csl/.if@

# simulator
puts "simulator..."
set sim [attach_simulator 2 .]
run n?
puts "Done!"
