# socket_ftp.tcl
#
# Testing ftp/ftpd
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

set MULTISESSION 0

set SOURCE_FILE "../foo.jpg"
set DEST_FILE 	"result.jpg"
# test root
cd [mkdir -q drcl.comp.Component /test]

# Nodes:
puts "create routers and hosts..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
#$link_ setPropDelay 0.1
set adjMatrix_ [java::new {int[][]} 6 {{1 2 3} {3 0 4} {0 3 5} {0 1 2} {1} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
$nb build [! n?]
if $MULTISESSION {
$nb build [! h4] {
	tcp					drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp
}
$nb build [! h5] {
	tcp					drcl.inet.socket.TCP_full
	ftpd	-/tcp		ftpd
}
} else {
$nb build [! h4] {
	tcp					drcl.inet.socket.TCP_socket
	ftp		-/tcp		ftp
}
$nb build [! h5] {
	tcp					drcl.inet.socket.TCP_socket
	ftpd	-/tcp		ftpd
}
}

puts "set up ftp/ftpd..."
! h4/ftp bind 4 5 21
! h5/ftpd bind 5 21
! h5/ftpd setup $DEST_FILE 1024
! h4/ftp setup $SOURCE_FILE 10240
! h?/ftp* setMultiSessionEnabled $MULTISESSION

# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5] "bidirection"

# simulator
puts "simulator..."
set sim [attach_simulator event .]

# turn on ftp/ftpd's debug flag: they will send out start/end of transfer debug messages
setflag debug true h?/ftp*

#mkdir drcl.comp.tool.DataCounter h4/counter
#connect -c h4/ftp/down@ -to h4/counter/in@
run h?
