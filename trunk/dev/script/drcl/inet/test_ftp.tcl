# test_ftp.tcl
#
# Testing drcl.inet.application.ftp/ftpd
#
# [CAUTION] this script is not a *simulation* scenario. do not attach event
# simulation runtime to it.
#
# Topology:
# ftp -- ftpd
# 
# Or
# ftp -- net peer -- net peer -- ftpd
#

set NET_PEER 1

# test root
cd [mkdir -q drcl.comp.Component /test]

# ftp/ftpd
puts "set up ftp/ftpd..."
#[mkdir drcl.inet.application.ftpd ftpd] setup ftptest.jpg 6099
#[mkdir drcl.inet.application.ftp ftp] setup ffff.jpg 90010
[mkdir drcl.inet.application.ftpd ftpd] setup result.jpg 1024
[mkdir drcl.inet.application.ftp ftp] setup foo.jpg 1024
if $NET_PEER {
	set server [mkdir drcl.comp.lib.bytestream.ByteStreamNetPeer netserver]
	set client [mkdir drcl.comp.lib.bytestream.ByteStreamNetPeer netclient]
	connect ftp/down@ -and $client/up@
	connect $server/up@ -and ftpd/down@
} else {
	connect ftp/down@ -and ftpd/down@
}

# simulator
puts "simulator..."
if $NET_PEER {
	set sim [attach_simulator 5 .]
} else {
	set sim [attach_simulator 3 .]
}

# turn on ftp/ftpd's debug flag: they will send out start/end of transfer debug messages
setflag debug true ftp*

#mkdir drcl.comp.tool.DataCounter h4/counter
#connect -c h4/ftp/down@ -to h4/counter/in@
if $NET_PEER {
	$server accept 10001	
	$client connect localhost 10001	
}
run ftp*
