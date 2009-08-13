# test_fragmentation.tcl
#
# Testing fragmentation in CoreServiceLayer.
# Other fragmentation tests can be found in the following scripts:
# - test_protocol.DVMRP2.tcl
#
# Topology:
# n0---n1---n2---n3
#   \     \    \--> c23 (count packets output from n2)
#    \     \--> c12 (count packets output from n1)
#     \--> c01 (count packets output from n0)
#
# - n0 is configured to fragment packets into 200-byte fragments,
#   n1 120-byte and n2 60.
# - At the end of the script, it sends a 1780-byte packet from n0 to n2.
#   At n0, the packet gets fragmented into 10 packets, each of which
#   gets further fragmented at n1 into 2 packets each of which gets
#   fragmented again at n2 into 3 packets.
# - Use "cat c??" to see the output packet counts at n0 and n1.
#   One should see 10 at c01, 20 at c12 and 60 at c23.

cd [mkdir drcl.comp.Component /test]

# Nodes:
puts "create nodes..."
set linkTemplate_ [java::new drcl.inet.Link]
$linkTemplate_ setPropDelay 1.0
set adjMatrix_ [java::new {int[][]} 4 {{1} {2 0} {3 1} {2}}]
java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $adjMatrix_ $linkTemplate_
mkdir drcl.comp.tool.DataCounter c01 c12 c23
connect -c n0/0@ -to c01
connect -c n1/0@ -to c12
connect -c n2/0@ -to c23

puts "build..."
[mkdir drcl.inet.NodeBuilder nodeBuilder] build [! n?]
! n0 setMTU 0 200
! n1 setMTU 0 120
! n2 setMTU 0 60

# up port
mkdir n?/csl/11@up
setflag trace true n?/csl/11@up

# setup routing tables
puts "set up routes..."
java::call drcl.inet.InetUtil setupRoutes [! n0] [! n2]
java::call drcl.inet.InetUtil setupRoutes [! n0] [! n3]

# simulator
puts "simulator..."
set sim [attach_simulator .]

# data
set small_data1 [java::call drcl.inet.contract.PktSending getForwardPack "Small Hello To Node 2!" 1060 [java::field drcl.net.Address NULL_ADDR] 2 false 10 333]
set small_data2 [java::call drcl.inet.contract.PktSending getForwardPack "Small Hello To Node 3!" 1060 [java::field drcl.net.Address NULL_ADDR] 3 false 10 333]
set large_data1 [java::call drcl.inet.contract.PktSending getForwardPack "Large Hello To Node 2!" 1780 [java::field drcl.net.Address NULL_ADDR] 2 false 10 333]
set large_data2 [java::call drcl.inet.contract.PktSending getForwardPack "Large Hello To Node 3!" 1780 [java::field drcl.net.Address NULL_ADDR] 3 false 10 333]

set scmd1 {inject $small_data1 n0/csl/11@up}
set scmd2 {inject $small_data2 n0/csl/11@up}
set lcmd1 {inject $large_data1 n0/csl/11@up}
set lcmd2 {inject $large_data2 n0/csl/11@up}
#setflag trace true n?
eval $lcmd2
