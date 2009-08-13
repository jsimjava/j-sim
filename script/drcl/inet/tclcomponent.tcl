# ping.tcl
#
# Test drcl.inet.TclComponent with ping in Tcl
#
# Topology:
# 
# h0 ----- n1 ----- h2
#	

cd [mkdir -q drcl.comp.Component /test]

# create the topology
puts "create topology..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.3; # 300ms
set adjMatrix_ [java::new {int[][]} 3 {{1} {0 2} {1}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "create builders..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e7; #10Mbps

puts "build..."
$nb build [! n?]
$nb build [! h?] {
	ping	1111/csl		drcl.inet.TclComponent
}

# Configure the bottleneck bandwidth and buffer size
! n1 setBandwidth 1 1.0e4; # 10Kbps at interface 1
! n1 setBufferSize 1 6000; # ~10 packets at interface 1

puts "setup static routes..."
java::call drcl.inet.InetUtil setupRoutes [! h0] [! h2] "bidirection"

puts "set up simulator..."
set sim [attach_simulator event .]

# application hooks:
# - tclcomp_process: process data that arrives at "down" port
# - tclcomp_cmd: execute some command on behalf of the component
# msg format: request|reply <time>
proc tclcomp_process {id comp data inPort} {
	set ipkt [!!! data]; # cast to InetPacket
	set src [$ipkt getSource]
	set pkt [$ipkt getBody]
	set s [$pkt toString]
	set cmd [lindex $s 0]
	set time [lindex $s 1]
	puts "[$inPort toString]: recv $cmd from $src with time $time"
	if [string match "request" $cmd] {
		set pkt "reply $time"; # ping reply
		set pktsize 10
		set destination_ $src
		$comp forward $pkt $pktsize $destination_ 
	} else {
		puts "ping result from $src: [expr [$comp getTime]-$time] seconds"
	}
}

proc tclcomp_cmd args {
	set id [lindex $args 0]
	set comp [lindex $args 1]
	set cmd [lindex $args 2]
	if [string match ping $cmd] {
		set pkt "request [$comp getTime]"; # ping request
		set pktsize 10
		set destination_ [lindex $args 3]
		$comp forward $pkt $pktsize $destination_
	} else {
		puts "Unknown command: $cmds"
	}
}

# set up TclComponents:
# - we're sharing the interpreter with the terminal, so get Jacl Interpreter
#   instance from current shell
set interp [[!!! __shell] getInterp];
# the lock makes sure only one of the simulation processes and terminal
# can access the interpreter
set lock $__shell;
foreach n "h0 h2" {
	! $n/ping init $interp $lock $n
}

$sim stop
! h0/ping exec "ping 2"
script {! h2/ping exec "ping 0"} -at 10.0 -on $sim
$sim resume

