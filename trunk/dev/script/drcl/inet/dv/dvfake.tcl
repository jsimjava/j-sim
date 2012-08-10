# dvfake.tcl
#
# Network Topology:
# h1 -- n0 --\   ___/----- n8 -- h9
#        |    \ /          /
#        \  ___X          /
#         \/    \        /-- DVFake
#        n50 -- n51 -- n52
#         /       \ ___/\
#        /      ___X     \
# h17-- n16 ----/    \-- n24 -- h25
#
#

set SETUP_FAKE 1

cd [mkdir drcl.comp.Component /test]

puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 11 {{4 5 7} {4 6 8} {4 6 9} {5 6 10} {0 1 2 5} {0 3 4 6} {1 2 3 5} 0 1 2 3}]
set ids_ [java::new {long[]} 11 {0 8 16 24 50 51 52 1 9 17 25}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
$nb build [! h*]
$nb build [! n*] {
	dv 		drcl.inet.protocol.dv.DV
}
java::call drcl.inet.InetUtil configureFlat [! .] false true; # set up route entries at routers to end hosts

if $SETUP_FAKE {
# set up fake DV component and connect it to n52/0@
setflag component false n52/0@/-/..
set fake [mkdir DVFake fake]
connect -c $fake/p@ -and n52/0@
$fake setAddress 10; # fake address
$fake addRTE 0 -2 0; # fake route entry of (dest=0, mask=-2, metric=0)
}

# simulator
puts "simulator..."
set sim [attach_simulator event .]
$sim stop
run n*
script {cat n52} -at 100.0 -on $sim
script {puts done} -at 100.0 -on $sim
$sim resumeTo 100

