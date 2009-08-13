# diffserv_ex1.tcl
#
# Test priority queue on AF and EF differentiation.
# Topology:
# h3 --\                      /-- h5
#      |-- n1 --- n0 --- n2-- |
# h4 --/ (edge) (core)        \-- h6
#
# (1) random sources at h3 and h4, sending rate of h4 is twice of that of h3
# (2) connection h3-h5 is tagged as "EF", h4-h6 as "AF", this is done at the edge router n1
# (3) core router n0 is equipped with a priority queue to actually differentiate the two classes of traffic

source "../../test/include.tcl"

set bandwidth 1.5e6; # bps
set propDelay 0.5;   # second


cd [mkdir -q drcl.comp.Component /test]

# Create topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay $propDelay
set adjMatrix_ [java::new {int[][]} 7 {{1 2} {0 3 4} {0 5 6} {1} {1} {2} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

############################## protocol stack ########################
#   Sender(h3,h4)   |   EdgeRouter(n1)  | CoreRouter(n0) |  Other Router(n2)
#                   |                   |                |  Receiver(h5,h6)
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

# set up traffic parameters for sources at h3, h4
puts "Setting up traffic parameters"
#Traffic parameters: minPktSize, maxPktSize, minInterPktInterval, maxInterPktInterval
#the last para in random is the time when the source begins to generate packets. 
set random(3) "1000 1000 0.02 0.02 10.0"
set random(4) "1000 1000 0.01 0.01 10.0"
#fixed time points
#set timepoints(0) "0.0 2.5 3.0 3.5 4.5 "
#set timepoints(1) "0.0 0.1 0.2 0.3 0.4"
set timepoints(3) [java::new {double[]} 1 "0.0"]
set timepoints(4) [java::new {double[]} 1 "0.0"]

puts "Create builders..."
# CSLBuilder:
set ccb [mkdir drcl.inet.core.CSLBuilder .coreCSLBuilder]
mkdir drcl.diffserv.scheduling.pq $ccb/q1; # only at interface 1
set ecb [mkdir drcl.inet.core.CSLBuilder .edgeCSLBuilder]
mkdir drcl.diffserv.TrafficConditioner $ecb/pf0_0; # only at interface 0
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth $bandwidth

puts "build..."
$nb build [! n0] $ccb
$nb build [! n1] $ecb
$nb build [! n2,h?]
! n0 setBandwidth 1 [expr $bandwidth/2]
# traffic generators
set port_ 100
foreach i {3 4} {
	eval [subst -nocommands {set traffic($i) [java::new drcl.net.traffic.traffic_FixedPoints $random($i) $timepoints($i)]}]
	set dest_ [expr $i+2]
	java::call drcl.inet.InetUtil createTrafficSource $traffic($i) "source" [! h$i] [! h$dest_] 0 $port_
}

# Set up static routes
puts "Set up static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h3] [! h5]
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h6]

if 1 {
# TrafficMonitor & Plotter
puts "Traffic monitor & plotter..."
mkdir drcl.comp.Component .monitor
set plot_ [mkdir drcl.comp.tool.Plotter .monitor/plot]
set tms_ {EF_src AF_src EF_dest AF_dest}
set targets_ {h3/source/down@ h4/source/down@ n2/1@ n2/2@}
for {set i 0} {$i < [llength $tms_]} {incr i} {
	set tm_ [lindex $tms_ $i]
	set tm($i) [mkdir drcl.net.tool.TrafficMonitor2 .monitor/$tm_]
	$tm($i) setOutputInterval 0.1
	$tm($i) setWindowSize 2.0
	connect -c [lindex $targets_ $i] -to $tm($i)/in@
	connect -c $tm($i)/bytecount@ -to $plot_/$i@0
	if { $testflag } {
		attach -c $testfile/in@ -to $tm($i)/bytecount@
	}
}
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

# for best effort traffic to go thru
proc AddDefaultProfile trafficConditioner {
	set profile [java::new drcl.diffserv.DFProfile]
	$profile set [java::null] [java::null]
	! $trafficConditioner addProfile 0 0 0 0 0 0 $profile
}

ConfigProfile "Meter" "SET_EF"   h3 n1/csl/pf0_0
ConfigProfile "Meter" "SET_AF11" h4 n1/csl/pf0_0
AddDefaultProfile n1/csl/pf0_0

#set up HQS with EF, AF11 and BS FIFO queue served by pq
puts "Setting up HQS"
set bs_queue [java::new drcl.inet.core.queue.DropTail "bs_q"]
set af1x_queue [java::new drcl.inet.core.queue.DropTail "af1x_q"]
set ef_queue [java::new drcl.inet.core.queue.DropTail "ef_q"]
$bs_queue setCapacity 4000
$af1x_queue setCapacity 4000
$ef_queue setCapacity 4000

! n0/csl/q1 setClassIDMask [java::field drcl.diffserv.DFConstants DSCPMask]
! n0/csl/q1 addQueueSet $ef_queue 0xffff [java::field  drcl.diffserv.DFConstants EF_TOS]
! n0/csl/q1 addQueueSet $af1x_queue 0xfff8 [java::field drcl.diffserv.DFConstants AF11_TOS]
! n0/csl/q1 addQueueSet $bs_queue 0xffff [java::field drcl.diffserv.DFConstants BE_TOS]

if 0 {
# plot instant queue size
connect -c $bs_queue/.q@ -to $plot_/0@1
connect -c $af1x_queue/.q@ -to $plot_/1@1
connect -c $ef_queue/.q@ -to $plot_/2@1
}
if 0 {
# count dropped packets
disconnect $bs_queue/.info@
disconnect $af1x_queue/.info@
disconnect $ef_queue/.info@
set counter [mkdir drcl.comp.tool.DataCounter .count]
attach -c $counter/bs@ -to $bs_queue/.info@
attach -c $counter/af1x@ -to $af1x_queue/.info@
attach -c $counter/ef@ -to $ef_queue/.info@
setflag garbage true n0/csl/q1/*_q
}

# END CONFIGURE PROFILER & HQS

# Simulator
puts "Attach simulator runtime..."
set sim [attach_simulator event .]
$sim stop

# start the traffic source and run the simulation for $time_
puts "Simulation starts..."
run h3-4
#$sim stopAt 20
#script {puts [$sim diag]; quit} -at 20 -on $sim

$sim resumeTo 20
