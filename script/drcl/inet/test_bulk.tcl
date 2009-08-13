# test_bulk.tcl
#
# Testing drcl.inet.application.BulkSource/BulkSink
#
# Topology:
# source -- sink
# 
# Or
# source -- net peer -- net peer -- sink
#

set NET_PEER 1

# test root
cd [mkdir -q drcl.comp.Component /test]

# source/sink
puts "set up source/sink..."
[mkdir drcl.inet.application.BulkSource source] setDataUnit 512
[mkdir drcl.inet.application.BulkSink sink] setDataUnit 512
if $NET_PEER {
	set server [mkdir drcl.comp.lib.bytestream.ByteStreamNetPeer netserver]
	set client [mkdir drcl.comp.lib.bytestream.ByteStreamNetPeer netclient]
	connect source/down@ -and $client/up@
	connect $server/up@ -and sink/down@
} else {
	connect source/down@ -and sink/down@
}

# simulator
puts "runtime..."
if $NET_PEER {
	attach_runtime 5 .
} else {
	attach_runtime 3 .
}

if $NET_PEER {
	$server accept 10001	
	$client connect localhost 10001	
}
run s*
rt . stopAt 3
wait_until {rt . isStopped}
rt .
