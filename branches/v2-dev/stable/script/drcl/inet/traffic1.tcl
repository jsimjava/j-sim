# traffic1.tcl
# Use drcl.inet.InetUtil.createTrafficSource to create traffic source with
# specified traffic model
#
# Adds a source at h4 and a sink at h5
# Topology
#      n0 ----- n1 - h4
#       |       |
#       |       |
# h5 - n2 ----- n3

cd [mkdir drcl.comp.Component scene]

# Create topology:
set adjMatrix_ [java::new {int[][]} 6 {{1 3 2} {3 0 4} {0 3 5} {0 1 2} 1 2}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_

# Build nodes:
set nodeBuilder_ [mkdir drcl.inet.NodeBuilder .nodeBuilder]
$nodeBuilder_ build [!! n* h4]
$nodeBuilder_ build [! h5] "sink  20/csl  drcl.comp.tool.DataCounter"

# Set up traffic source/sink:
set packetSize_ 512
set period_ .1;		# send a packet of size 512 bytes every .1 second
set trafficModel_ [java::new drcl.net.traffic.traffic_PacketTrain $packetSize_ $period_]
# arguments: traffic_model id source_node dest_node ToS protocol(ID)
set source_ [java::call drcl.inet.InetUtil createTrafficSource $trafficModel_ "source" [! h4] [! h5] 0 20]

java::call drcl.inet.InetUtil setupRoutes [! h4] [! h5]

set sim [attach_simulator .]
run .
puts "Simulation is running..."
puts "Use 'cat h4/source' to check the source"
puts "Use 'cat h5/sink' to check bytes received"
