# diffserv_ex4.tcl
#
# observe the route "swing" problem" with the dynamic routing DV, n0->n8->n4 and
# n0->n9->n4 are equally good
# to remedy the problem, add traffic conditioner to interface 1 of n0 as well
#
# Topology:
#
#           |-----n9------|
# h1 --\    |     |       |   /-- h6
#      |-- n0 --- n8 --- n4-- |
# h2 --/ (edge) (core)        \-- h7
#
# (1) random sources at h2 and h1, sending rate of h1 is twice of that of h2
# (2) connection h2-h7 is tagged as "EF", h1-h6 as "AF", this is done at the edge router n0
# (3) core router n8 is equipped with a priority queue to actually differentiate the two classes of traffic

set bandwidth 1.5e6; # bps
set propDelay 0.5;   # second


cd [mkdir -q drcl.comp.Component /test]

# Create topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay $propDelay
set adjMatrix_ [java::new {int[][]} 8 {{1 3 2} {0 3 4 5} {0 3 6 7} {1 0 2} {1} {1} {2} {2}}]
set ids_ [java::new {long[]} 8 {8 0 4 9 1 2 6 7}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

############################## protocol stack ########################
#   Sender(h3,h1)   |   EdgeRouter(n0)  | CoreRouter(n8) |  Other Router(n4)
#                   |                   |                |  Receiver(h2,h6)
#-------------------|-------------------|----------------|-------------
#   Generator(s)    |                   |                |
#-------------------|-------------------|----------------|-------------
#   PktDispatcher   |   PktDispatcher   | PktDispatcher  | PktDispatcher
#-------------------|-------------------|----------------|--------------
#                   |TrafficConditioner |                |
#                   |(ingress)(egress)  |                |
#-------------------|-------------------|----------------|--------------
#    DropTail       |     DropTail      |   HQS stack    |	DropTail     
#-------------------|-------------------|----------------|--------------
#      NIC          |       NIC         |      NIC       |    NIC

# set up traffic parameters for sources at h1, h2
puts "Setting up traffic parameters"
#Traffic parameters: minPktSize, maxPktSize, minInterPktInterval, maxInterPktInterval
#the last para in random is the time when the source begins to generate packets. 
set random(1) "1250 1250 0.01 0.01 10.0"
set random(2) "1000 1000 0.01 0.01 10.0"
#fixed time points
#set timepoints(0) "0.0 2.5 3.0 3.5 4.5 "
#set timepoints(1) "0.0 0.1 0.2 0.3 0.4"
set timepoints(1) [java::new {double[]} 1 "0.0"]
set timepoints(2) [java::new {double[]} 1 "0.0"]

puts "Create builders..."
# CSLBuilder:
set ccb [mkdir drcl.inet.core.CSLBuilder .coreCSLBuilder]
mkdir drcl.diffserv.scheduling.pq $ccb/q2;  # at interface 2
mkdir drcl.diffserv.scheduling.pq $ccb/q1; # at interface 1

set ecb [mkdir drcl.inet.core.CSLBuilder .edgeCSLBuilder]
mkdir drcl.diffserv.TrafficConditioner $ecb/pf0_0 $ecb/pf1_0; # at interface 0-1
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth [expr $bandwidth*2];#$bandwidth

puts "build..."

$nb build [! h?]
$nb build [! n8,n9] $ccb "dv drcl.inet.protocol.dv.DV"
$nb build [! n0] $ecb "dv drcl.inet.protocol.dv.DV"
$nb build [! n4] "dv drcl.inet.protocol.dv.DV"


#puts "Set up routing algorithm..."

# should I keep these lines. I try to remove it as the routing is now dynamic, but it didn't work
#java::call drcl.inet.InetUtil setupRoutes [! h1] [! h6]
#java::call drcl.inet.InetUtil setupRoutes [! h2] [! h7]

! n8-9 setBandwidth 2 $bandwidth;#[expr $bandwidth/2]
# traffic generators
set port_ 100
foreach i {1 2} {
	eval [subst -nocommands {set traffic($i) [java::new drcl.net.traffic.traffic_FixedPoints $random($i) $timepoints($i)]}]
	set dest_ [expr $i+5]
	java::call drcl.inet.InetUtil createTrafficSource $traffic($i) "source" [! h$i] [! h$dest_] 0 $port_
}

java::call drcl.inet.InetUtil configureFlat [! .] false true

if 1 {
# TrafficMonitor & Plotter
puts "Traffic monitor & plotter..."
mkdir drcl.comp.Component .monitor
set plot_ [mkdir drcl.comp.tool.Plotter .monitor/plot]
set tms_ {EF_src AF_src EF_dest AF_dest}
set targets_ "h1/source/down@ h2/source/down@ h6/csl/100@up h7/csl/100@up"
for {set i 0} {$i < [llength $tms_]} {incr i} {
	set tm_ [lindex $tms_ $i]
	set tm($i) [mkdir drcl.net.tool.TrafficMonitor2 .monitor/$tm_]
	$tm($i) setOutputInterval 0.1
	$tm($i) setWindowSize 2.0
	connect -c [lindex $targets_ $i] -to $tm($i)/in@
	connect -c $tm($i)/bytecount@ -to $plot_/$i@0
}
connect -c n4/csl/ni2/.q@ -to $plot_/1@1
connect -c n4/csl/ni3/.q@ -to $plot_/2@1
connect -c n0/csl/ni0/.q@ -to $plot_/3@1
connect -c n0/csl/ni1/.q@ -to $plot_/4@1
};# end if claus


# START CONFIGURE PROFILER & HQS
#set up TC at edge router
puts "Setting up TC"

proc ConfigProfile {meterType markerType source trafficConditioner} {
	if [string match "Meter" $meterType] {
		set meter [java::null]
	} else {
		set meter [java::new drcl.diffserv.$meterType]
	}
	set profile [java::new drcl.diffserv.DFProfile]
	$profile set [java::new drcl.diffserv.Marker $markerType] $meter 
	! $trafficConditioner addProfile [! $source getDefaultAddress] $profile
	return $profile
}

ConfigProfile "Meter" "SET_EF"   h1 n0/csl/pf0_0
ConfigProfile "Meter" "SET_AF11" h2 n0/csl/pf0_0
ConfigProfile "Meter" "SET_EF"   h1 n0/csl/pf1_0
ConfigProfile "Meter" "SET_AF11" h2 n0/csl/pf1_0
! n0/csl/pf0_0,pf1_0 addDefaultProfile

#set up HQS with EF, AF11 and BS FIFO queue served by pq
puts "Setting up HQS"
set bs_queue1 [java::new drcl.inet.core.queue.DropTail "bs_q1"]
set af1x_queue1 [java::new drcl.inet.core.queue.DropTail "af1x_q1"]
set ef_queue1 [java::new drcl.inet.core.queue.DropTail "ef_q1"]

set bs_queue2 [java::new drcl.inet.core.queue.DropTail "bs_q2"]
set af1x_queue2 [java::new drcl.inet.core.queue.DropTail "af1x_q2"]
set ef_queue2 [java::new drcl.inet.core.queue.DropTail "ef_q2"]

set bs_queue3 [java::new drcl.inet.core.queue.DropTail "bs_q3"]
set af1x_queue3 [java::new drcl.inet.core.queue.DropTail "af1x_q3"]
set ef_queue3 [java::new drcl.inet.core.queue.DropTail "ef_q3"]

set bs_queue4 [java::new drcl.inet.core.queue.DropTail "bs_q4"]
set af1x_queue4 [java::new drcl.inet.core.queue.DropTail "af1x_q4"]
set ef_queue4 [java::new drcl.inet.core.queue.DropTail "ef_q4"]

$bs_queue1 setCapacity 4000
$af1x_queue1 setCapacity 4000
$ef_queue1 setCapacity 4000

$bs_queue2 setCapacity 4000
$af1x_queue2 setCapacity 4000
$ef_queue2 setCapacity 4000

$bs_queue3 setCapacity 4000
$af1x_queue3 setCapacity 4000
$ef_queue3 setCapacity 4000

$bs_queue4 setCapacity 4000
$af1x_queue4 setCapacity 4000
$ef_queue4 setCapacity 4000

! n8/csl/q1 setClassIDMask [java::field drcl.diffserv.DFConstants DSCPMask]
! n8/csl/q1 addQueueSet $ef_queue1 0xffff [java::field  drcl.diffserv.DFConstants EF_TOS]
connect -c n8/csl/q1/ef_q1/.q@ -to $plot_/1@2
! n8/csl/q1 addQueueSet $af1x_queue1 0xfff8 [java::field drcl.diffserv.DFConstants AF11_TOS]
connect -c n8/csl/q1/af1x_q1/.q@ -to $plot_/2@2
! n8/csl/q1 addQueueSet $bs_queue1 0xffff [java::field drcl.diffserv.DFConstants BE_TOS]

! n8/csl/q2 setClassIDMask [java::field drcl.diffserv.DFConstants DSCPMask]
! n8/csl/q2 addQueueSet $ef_queue2 0xffff [java::field  drcl.diffserv.DFConstants EF_TOS]
connect -c n8/csl/q2/ef_q2/.q@ -to $plot_/3@2
! n8/csl/q2 addQueueSet $af1x_queue2 0xfff8 [java::field drcl.diffserv.DFConstants AF11_TOS]
connect -c n8/csl/q2/af1x_q2/.q@ -to $plot_/4@2
! n8/csl/q2 addQueueSet $bs_queue2 0xffff [java::field drcl.diffserv.DFConstants BE_TOS]

! n9/csl/q1 setClassIDMask [java::field drcl.diffserv.DFConstants DSCPMask]
! n9/csl/q1 addQueueSet $ef_queue3 0xffff [java::field  drcl.diffserv.DFConstants EF_TOS]
connect -c n9/csl/q1/ef_q3/.q@ -to $plot_/5@2
! n9/csl/q1 addQueueSet $af1x_queue3 0xfff8 [java::field drcl.diffserv.DFConstants AF11_TOS]
connect -c n9/csl/q1/af1x_q3/.q@ -to $plot_/6@2
! n9/csl/q1 addQueueSet $bs_queue3 0xffff [java::field drcl.diffserv.DFConstants BE_TOS]

! n9/csl/q2 setClassIDMask [java::field drcl.diffserv.DFConstants DSCPMask]
! n9/csl/q2 addQueueSet $ef_queue4 0xffff [java::field  drcl.diffserv.DFConstants EF_TOS]
connect -c n9/csl/q2/ef_q4/.q@ -to $plot_/7@2
! n9/csl/q2 addQueueSet $af1x_queue4 0xfff8 [java::field drcl.diffserv.DFConstants AF11_TOS]
connect -c n9/csl/q2/af1x_q4/.q@ -to $plot_/8@2
! n9/csl/q2 addQueueSet $bs_queue4 0xffff [java::field drcl.diffserv.DFConstants BE_TOS]

# END CONFIGURE PROFILER & HQS

# Simulator
puts "Attach simulator runtime..."
set sim [attach_simulator event .]

# start the traffic source and run the simulation for $time_
puts "Simulation starts..."
$sim stop
run n?
script {run h1-2} -at 10 -on $sim
$sim resumeTo 50
#script {puts [$sim diag]; quit} -at 20 -on $sim
