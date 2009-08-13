# dv3.tcl
#
# Overlay network constructed from end hosts by setting VIFs between end hosts
# - DV runs on routers (n*)
# - DV also runs on end hosts but only on the overlay network
#
# Physical Topology:
# h1 -- n0 --\   ___/----- n8 -- h9
#        |    \ /          /
#        \  ___X          /
#         \/    \        /
#        n50 -- n51 -- n52
#         /       \ ___/\
#        /      ___X     \
# h17-- n16 ----/    \-- n24 -- h25
#
# Overlay network:
# h1 -------- h9
# |\           |
# | \--------\ |
# |           \|
# h17 ------- h25
#
# At the end of simulation, print out the routing tables for the overlay network
#

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
$nb build [! n*] {
	dv 		drcl.inet.protocol.dv.DV
}
java::call drcl.inet.InetUtil configureFlat [! .] false false; # set up route entries at routers to end hosts

# build overlay network with DV
puts "Overlay network ..."
# 1. create DV to run on overlay network
$nb build [! h*] {
	dv 		drcl.inet.protocol.dv.DV
}
! h*/dv setMode VIRTUAL; # only on VIF

# 2. set up dedicate RT for end-host DV
#    (don't mess up RT in CSL with overlay network routes)
foreach h [ls -q h*] {
	set rt [mkdir drcl.inet.core.RT $h/rt]
	disconnect $h/dv/.service_rt@
	connect -c $h/dv/.service_rt@ -and $h/rt/.service_rt@
}

# 3. set up VIFs...overlay network topology
set MTU -1; # This turn off fragmentation
java::call drcl.inet.InetUtil setupVIF [!  h1] 2 $MTU [!  h9] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [!  h1] 3 $MTU [! h17] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [!  h1] 4 $MTU [! h25] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [!  h9] 3 $MTU [! h25] 3 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [! h17] 3 $MTU [! h25] 4 $MTU; # node, vifindex, MTU

# 4. add default route for end hosts
set key_ [java::new drcl.inet.data.RTKey 0 0 0 0 0 0]
set bs_ [java::new drcl.data.BitSet 1]
$bs_ set 0
set entry_ [java::new drcl.inet.data.RTEntry $bs_]
! h* addRTEntry $key_ $entry_ -1.0

# simulator
puts "simulator..."
set sim [attach_simulator .]

setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} h*/dv
run n*,h*
script "cat h*/rt" -at 100.0 -on $sim
$sim stopAt 100

