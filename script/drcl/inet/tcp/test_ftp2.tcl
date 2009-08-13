# test_ftp2.tcl
#
# Testing drcl.inet.application.ftp/ftpd
# using drcl.ruv.TclAction
#
# Topology:
# n0 --------- n1--h4
# |\           |
# | \--------\ |
# |           \|
# n2 --------- n3
# |
# \--h5
#


global N

proc ftpStart {} {

	global N

	if {$N == 10} {
		ftpEndOfSimulation
		return
	}

	incr N

	reset h*/ftp*
	! h4/ftp setup ../foo.jpg 1024
	! h5/ftpd setup result$N.jpg 1024
	run h?
}

proc ftpEndOfSimulation {} {

	global N
	puts "$N full file transfers in [rt . getWallTimeElapsed] ms"
	exit
}

set SOURCE_FILE "foo.jpg"
set DEST_FILE 	"result.jpg"
# test root
cd [mkdir -q drcl.comp.Component /test]

# Nodes:
puts "create routers and hosts..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 6 {{1 2 3} {3 0 4} {0 3 5} {0 1 2} {1} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
$nb build [! n?]
$nb build [! h4] {
	tcp					drcl.inet.transport.TCP
	ftp		-/tcp		drcl.inet.application.ftp
}
$nb build [! h5] {
	tcpsink				drcl.inet.transport.TCPSink
	ftpd	-/tcpsink	drcl.inet.application.ftpd
}
! h4/tcp setPeer 5
#puts "set up ftp/ftpd..."
#! h5/ftpd setup $DEST_FILE 1024
#! h4/ftp setup $SOURCE_FILE 10240

# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5] "bidirection"

# simulator
puts "simulator..."
set sim [attach_simulator .]

# turn on ftp/ftpd's debug flag: they will send out start/end of transfer debug messages
setflag debug true h?/ftp*

#mkdir drcl.comp.tool.DataCounter h4/counter
#connect -c h4/ftp/down@ -to h4/counter/in@
#run h?

puts "set up TclAction..."
mkdir drcl.ruv.TclAction tclaction
connect -c h5/ftpd/notify@ -to tclaction/in@
# set up TclAction:
# - we're sharing the interpreter with the terminal, so get Jacl Interpreter
#   instance from current shell
set interp [[!!! __shell] getInterp];
# the lock makes sure only one of the simulation processes and terminal
# can access the interpreter
set lock $__shell;
! tclaction init $interp $lock
#! tclaction setUniversalAction "ftpStart"
! tclaction addAction "done" "ftpStart"

set N 0
ftpStart
