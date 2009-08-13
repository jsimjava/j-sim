# DVMRP2.tcl
#
# Provides a more complicated topology for testing virtual network setup
# and 2-level (host-router) hierarchical network setup
#
# Before other scripts can "source" this script, one should define either
# "DVMRP2_PHYSICAL" or "DVMRP2_VIRTUAL".  Default is DVMRP2_PHYSICAL.
#
# Physical Topology:
# n0 --\   ___/----- n8
#  |    \ /          /
#  \  ___X          /
#   \/    \        /
#  n50 -- n51 -- n52
#   /       \ ___/\
#  /      ___X     \
# n16 ----/    \-- n24
#
# Virtual Topology:
# n0 -------- n8
# |\           |
# | \--------\ |
# |           \|
# n16 ------- n24
#

# Other scripts must define "DVMRP2_PHYSICAL" or "DVMRP2_VIRTUAL"
# before sourcing this script.
set __virtual [catch {set tmp $DVMRP2_PHYSICAL}]
set __physical [catch {set tmp $DVMRP2_VIRTUAL}]
if {$__virtual && $__physical} {
	set __virtual 0; # default is not set up virtual network
}
catch {unset DVMRP2_PHYSICAL}
catch {unset DVMRP2_VIRTUAL}

cd [mkdir drcl.comp.Component /test]

puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 7 {{4 5} {4 6} {4 6} {5 6} {0 1 2 5} {0 3 4 6} {1 2 3 5}}]
set ids_ [java::new {long[]} 7 {0 8 16 24 50 51 52}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
if $__virtual {
	# virtual network: needs DV
	$nb build [! n0-24] {
		dv 		drcl.inet.protocol.dv.DV
		dvmrp 	drcl.inet.protocol.dvmrp.DVMRP
	}
	$nb build [! n50-52] {
		dv 		drcl.inet.protocol.dv.DV
	}
	watch -c -label FC -add n0-24/csl/.rt_mcast@

	puts "Configuring interfaces..."
	for {set i 2} {$i < 5} {incr i} {
		! n0 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 0 -8]
		! n24 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 24 -8]
	}
	for {set i 2} {$i < 4} {incr i} {
		! n8 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 8 -8]
		! n16 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 16 -8]
	}

	puts "set up VIFs..."
	set MTU -1; # This turn off fragmentation
	java::call drcl.inet.InetUtil setupVIF [!  n0] 2 $MTU [!  n8] 2 $MTU; # node, vifindex, MTU
	java::call drcl.inet.InetUtil setupVIF [!  n0] 3 $MTU [! n16] 2 $MTU; # node, vifindex, MTU
	java::call drcl.inet.InetUtil setupVIF [!  n0] 4 $MTU [! n24] 2 $MTU; # node, vifindex, MTU
	java::call drcl.inet.InetUtil setupVIF [!  n8] 3 $MTU [! n24] 3 $MTU; # node, vifindex, MTU
	java::call drcl.inet.InetUtil setupVIF [! n16] 3 $MTU [! n24] 4 $MTU; # node, vifindex, MTU
	! n0,n24/dvmrp setIfset [java::new drcl.data.BitSet [java::new {int[]} 3 {2 3 4}]]
	! n8,n16/dvmrp setIfset [java::new drcl.data.BitSet [java::new {int[]} 2 {2 3}]]
} else {
	# DVMRP runs on physical interfaces only
	$nb build [! n*] "dvmrp drcl.inet.protocol.dvmrp.DVMRP"
	watch -c -label FC -add n*/csl/.rt_mcast@

	puts "Configuring interfaces..."
	foreach id_ "0 8 16 24" {
		for {set i 0} {$i < 2} {incr i} {
			! n$id_ setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo $id_ -8]
		}
	}
}

# simulator
puts "simulator..."
set sim [attach_simulator .]
$sim stop
run n*

setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} n*/dvmrp
source DVMRP_common.tcl
