# socket_ftp4.tcl
#
# Testing ftp/ftpd
#
# Topology:
# /--h7,h8
# |
# n0 --------- n1--h4,h9
# |\           |
# | \--------\ |
# |           \|
# n2 --------- n3--h6
# |
# \--h5
#

set MULTISESSION 1

set SOURCE_FILE "../foo.jpg"
set DEST_FILE 	"result.jpg"
# test root
cd [mkdir -q drcl.comp.Component /test]

# Nodes:
puts "create routers and hosts..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 1.0
#$link_ setPropDelay 0.1
set adjMatrix_ [java::new {int[][]} 10 {{1 2 3 7 8} {3 0 4 9} {0 3 5} {0 1 2 6} {1} {2} {3}  {0}  {0}  {1} }]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

puts "build..."
# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nb setBandwidth 1.0e6; #1Mbps
$nb build [! n?]
if $MULTISESSION {
$nb build [! h4] {
	tcp				drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp2
}
$nb build [! h6] {
	tcp				drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp2
}
$nb build [! h7] {
	tcp				drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp2
}
$nb build [! h8] {
	tcp				drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp2
}
$nb build [! h9] {
	tcp				drcl.inet.socket.TCP_full
	ftp		-/tcp		ftp2
}
$nb build [! h5] {
	tcp				drcl.inet.socket.TCP_full
	ftpd		-/tcp		ftpd2
}
} else {
$nb build [! h4] {
	tcp				drcl.inet.socket.TCP_socket
	ftp		-/tcp		ftp2
}
$nb build [! h5] {
	tcp				drcl.inet.socket.TCP_socket
	ftpd		-/tcp		ftpd2
}
}

puts "set up ftp/ftpd..."
! h4/ftp bind 4 5 21
! h6/ftp bind 6 5 21
! h7/ftp bind 7 5 21
! h8/ftp bind 8 5 21
! h9/ftp bind 9 5 21
! h5/ftpd bind 5 21
! h5/ftpd setup 40960
! h4/ftp setup $SOURCE_FILE 10240 h4_$DEST_FILE
! h6/ftp setup $SOURCE_FILE 10240 h6_$DEST_FILE
! h7/ftp setup $SOURCE_FILE 10240 h7_$DEST_FILE
! h8/ftp setup $SOURCE_FILE 10240 h8_$DEST_FILE
! h9/ftp setup $SOURCE_FILE 10240 h9_$DEST_FILE
! h?/ftp* setMultiSessionEnabled $MULTISESSION

#setflag trace true h?/ftp* .
#setflag trace true h?/tcp* .
#setflag debug true h?/tcp* .
#setflag debug true h?/ftp* .

if 0 {
setflag trace true h4/ftp*
setflag trace true h4/tcp*
setflag debug true h4/tcp*
setflag debug true h4/ftp*
setflag trace true h5/ftp*
setflag trace true h5/tcp*
setflag debug true h5/tcp*
setflag debug true h5/ftp*
}



# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h6] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h7] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h8] [! h5] "bidirection"
java::call drcl.inet.InetUtil setupRoutes [! h9] [! h5] "bidirection"

# simulator
puts "simulator..."
set sim [attach_simulator event .]

# turn on ftp/ftpd's debug flag: they will send out start/end of transfer debug messages
setflag debug true h?/ftp*

#mkdir drcl.comp.tool.DataCounter h4/counter
#connect -c h4/ftp/down@ -to h4/counter/in@
if $MULTISESSION {
	run h?
} else {
	run h4 h5
}
