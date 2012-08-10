# DVMRP_problem.tcl
#
# Demonstrating a problem in DVMRP (fixed in J-Sim v1.2.1)
# 
# Problem:
# If a receiver and a source are connected to the same router,
# if the receiver joins a group before the source sends the first msg to
# the group, then the "group" route entry is created at the router and
# then when the msg is sent, the router finds the (group) route and forwards
# the packet with it, does not consult with DVMRP to flush the packet...
#
# Topology:
#       h3    h5
#        |     |
#  h0 -- n1 -- n4
#
#  h0:  source -- sends packets to mcast group -111
#  h3, h5: dests -- receive packets for mcast group -111
#  n1, n4: mcast routers
#
# Turn on "SHOW_PROBLEM" to see how the mcast packet is not routed to h5.
# Turn off "SHOW_PROBLEM" to enable the workaround: send a flush packet before
# the receivers join.
#

set SHOW_PROBLEM 1

source DVMRP_common.tcl

cd [mkdir drcl.comp.Component /project]

set link_ [java::new drcl.inet.Link]
$link_ setPropDelay .2
set adjMatrix_ [java::new {int[][]} 6 {{1} {0 4 3} {} {1} {1 5} {4}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

set hb [mkdir drcl.inet.NodeBuilder .hostBuilder]
$hb setBandwidth 1.0e5
mkdir $hb/.service_mcast@
$hb build [! h*]

set rb [mkdir drcl.inet.NodeBuilder .routerBuilder]
$rb setBandwidth 1.0e5
$rb build [! n*] "dvmrp mkdir drcl.inet.protocol.dvmrp.DVMRP"

#! n1 setInterfaceInfo 0 [java::new drcl.inet.data.InterfaceInfo 1 -8]
#! n1 setInterfaceInfo 1 [java::new drcl.inet.data.InterfaceInfo 1 -8]
#! n1 setInterfaceInfo 2 [java::new drcl.inet.data.InterfaceInfo 1 -8]

#! n2 setInterfaceInfo 0 [java::new drcl.inet.data.InterfaceInfo 2 -8]
#! n2 setInterfaceInfo 1 [java::new drcl.inet.data.InterfaceInfo 2 -8]

#mkdir n*/csl/100@up
mkdir h*/csl/100@up

java::call drcl.inet.InetUtil configureFlat [! .] false true

set sim [attach_simulator .]
$sim stop
run n*

setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} n*/dvmrp 
#watch -c -label ROUTER1 -add n1/csl/100@up 
#watch -c -label ROUTER2 -add n2/csl/100@up 
watch -c -label HOST3 -add h3/csl/100@up 
watch -c -label HOST5 -add h5/csl/100@up

if $SHOW_PROBLEM {
	script {! h3/csl/igmp join -111} -at 50.0 -on $sim
	script {! h5/csl/igmp join -111} -at 50.0 -on $sim
}

#script {host_event -join -111 -host none -router n1} -at 60.0 -on $sim script {host_event -join -111 -host none -router n2} -at 60.0 -on $sim

script -at 100.0 -on $sim {send_mcast_pkt -message "Hello world" -from h0/csl/100@up -to -111 -size 10000}
if !$SHOW_PROBLEM {
	script -at 110.0 -on $sim {
		! h3/csl/igmp join -111
		! h5/csl/igmp join -111
		script {send_mcast_pkt -message "Hello world" -from h0/csl/100@up -to -111 -size 10000}
	}
}
script -at 150.0 -on $sim {send_mcast_pkt -message "Data 1" -from h0/csl/100@up -to -111 -size 10000} 

$sim resumeTo 300.0

