# DVMRP0.tcl
#
# Testing if the route exchange performs correctly under one link failure
# on a virtual network.
#
# The virtual links will be back on once the unicast routing protocol gets
# all updated after the link fails.
#
# Can also be used to test fragmentation with packet-in-packets.
# See the line where "MTU" is set.
#
# This script can be sourced by other scripts to share the same physical and/or 
# virtual topologies.
# Other scripts must define "DVMRP0_CALLED_PHYSICAL_ONLY" or "DVMRP0_CALLED_VIRTUAL"
# before sourcing this script.
#
# Physical Topology:
# n0 --\   ___/----- n2
#  |    \ /          /
# (x) ___X          /
#   \/    \        /
#   n8 --- n9 --- n10
#   /       \ ___/\
#  /      ___X     \
# n4 ----/    \--- n6
#
# Virtual Topology:
# n0 ---(x)--- n2
# |\           |
# | \--------\ |
# |           \|
# n4 --------- n6
#
# Link failure:
# 201.0: the link (marked "x") between n0 and n4 fails.
#
# Observations by "cat n?/.../dvmrp"
# At time 300.0: several virtual links are broken.
# At time 500.0: virtual links are recovered once unicast routings all update.

# If the file is not sourced by other scripts, then run the scenario
# Other scripts must define "DVMRP0_CALLED_PHYSICAL_ONLY" or "DVMRP0_CALLED_VIRTUAL"
# before sourcing this script.
set no_called_physical_only [catch {set tmp $DVMRP0_CALLED_PHYSICAL_ONLY}]
set no_called_virtual [catch {set tmp $DVMRP0_CALLED_VIRTUAL}]
catch {unset DVMRP0_CALLED_PHYSICAL_ONLY}
catch {unset DVMRP0_CALLED_VIRTUAL}

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
# To create router 0, 2, 4, 6, 8-10.  Imagine that 1, 3, 5, 7 are hosts
# (but not actually created) and connected to 0, 2, 4 and 6 respectively.
set adjMatrix_ [java::new {int[][]} 11 {{8 9} {} {8 10} {} {8 10} {} {9 10} {} {0 2 4 9} {0 6 8 10} {2 4 6 9}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
if $no_called_physical_only {
	$nb build [! n0-6] {
		dv 		drcl.inet.protocol.dv.DV
		dvmrp 	drcl.inet.protocol.dvmrp.DVMRP
	}
	$nb build [! n8-10] {
		dv 		drcl.inet.protocol.dv.DV
	}
} else {
	$nb build [! n*] {
		dv 		drcl.inet.protocol.dv.DV
		dvmrp 	drcl.inet.protocol.dvmrp.DVMRP
	}
}

puts "Configuring interfaces..."
if $no_called_physical_only {
	for {set i 2} {$i < 5} {incr i} {
		! n0 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 0 -2]
		! n6 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 6 -2]
	}
	for {set i 2} {$i < 4} {incr i} {
		! n2 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 2 -2]
		! n4 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 4 -2]
	}
} else {
	for {set i 0} {$i < 2} {incr i} {
		! n0 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 0 -2]
		! n2 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 2 -2]
		! n4 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 4 -2]
		! n6 setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo 6 -2]
	}
}

if $no_called_physical_only {

# set up virtual interfaces
puts "set up VIFs..."
#set MTU -1; # This turn off fragmentation
set MTU 52;
	# Set to 52 for testing fragmentation with PIP.
	# Inet packet header size is 20 bytes, 52 = 2 headers + payload of 12.
! n0 setMTUs [expr $MTU - 20 - 2];
	# This makes n0 do twice fragment on virtual ifs
! n8 setMTU 1 [expr $MTU - 20 - 4];
	# This makes n8 do fragment (again) on packet from n8 to n2
java::call drcl.inet.InetUtil setupVIF [! n0] 2 $MTU [! n2] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [! n0] 3 $MTU [! n4] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [! n0] 4 $MTU [! n6] 2 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [! n2] 3 $MTU [! n6] 3 $MTU; # node, vifindex, MTU
java::call drcl.inet.InetUtil setupVIF [! n4] 3 $MTU [! n6] 4 $MTU; # node, vifindex, MTU
! n0,n6/dvmrp setIfset [java::new drcl.data.BitSet [java::new {int[]} 3 {2 3 4}]]
! n2-4/dvmrp setIfset [java::new drcl.data.BitSet [java::new {int[]} 2 {2 3}]]

}

# simulator
puts "simulator..."
set sim [attach_simulator .]

#setflag trace true n8; # watch initially dropped packet-in-packets 

if {$no_called_physical_only & $no_called_virtual } {

setflag debug true -at "debug_timeout debug_route" n*/dvmrp

# watch for fragments: (a lot of debug printouts)
set cmd {
setflag debug true -at debug_fragment n0,n8/.../pd
setflag debug true -at debug_reassemble n2/.../pd
#setflag trace true n0-2
}

# start DV/DVMRP
puts "Simulation starts..."
run n*
#script -at  21.0 {eval $cmd} -on $sim;
	# Watch fragmenting on n0 and reassembling on n1
	# Note: Before time 20.0, the unicast routes are not all established,
	# the packets sent on virtual links are all dropped.
script -at  200.0 {puts [cat n?/.../dvmrp]} -on $sim
script -at  201.0 {setflag component false n0/0@/-/..} -on $sim
script -at  300.0 {puts [cat n?/.../dvmrp]} -on $sim
script -at  500.0 {puts [cat n?/.../dvmrp]} -on $sim
$sim stopAt 501.0
}
