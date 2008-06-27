# traffic52.tcl
# Test SimpleTrace with UDP
#
# Topology:
# h1 -- n0 --\   ___/----- n8 -- h9
#        |    \ /          /
#        \  ___X          /
#         \/    \        /
#        n50 -- n51 -- n52
#         /       \ ___/\
#        /      ___X     \
# h17-- n16 ----/    \-- n24 -- h25


# test root
cd [mkdir drcl.comp.Component /test]

# create topology
puts "create nodes..."
set link_ [java::new drcl.inet.Link]
$link_ setPropDelay 0.2
set adjMatrix_ [java::new {int[][]} 11 {{4 5 7} {4 6 8} {4 6 9} {5 6 10} {0 1 2 5} {0 3 4 6} {1 2 3 5} 0 1 2 3}]
set ids_ [java::new {long[]} 11 {0 8 16 24 50 51 52 1 9 17 25}]
java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $ids_ $link_

# NodeBuilder:
set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder];
puts "build..."
$nb build [! n*]
$nb build [! h*] {
	 udp			drcl.inet.transport.UDP
}

# connection parameters
set src 1
set dest 25
set port 101
set tos 0

# set up routes
java::call drcl.inet.InetUtil setupRoutes [! h$src] [! h$dest] "unidirection"

# set up source
set srccomp [mkdir drcl.net.traffic.SimpleTrace h$src/source]
connect -c $srccomp/down@ -and h$src/udp/$port@up

$srccomp load traffic5.txt
setflag loop true $srccomp
$srccomp setLoopPeriod 10.0

set wrapper [java::call drcl.inet.contract.DatagramContract getForwardPack [java::null] 0 $src $dest $port $tos]
$srccomp setPacketWrapper $wrapper

# set up sink
set count [mkdir drcl.comp.tool.DataCounter h$dest/counter]
connect -c h$dest/udp/$port@up -to $count/in@

# Traffic monitors and plotter
set src_monitor [mkdir drcl.comp.tool.CountMonitor .src_monitor]
set dest_monitor [mkdir drcl.comp.tool.CountMonitor .dest_monitor]
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $srccomp/down@ -to $src_monitor/down@src
attach -c $dest_monitor/dest@ -with h$dest/0@
# connect monitors to plotter
connect -c $src_monitor/sizecount@ -to $plot/0@0
connect -c $dest_monitor/sizecount@ -to $plot/1@0

# set up simulator
set sim [attach_simulator event .]

puts "Simulation running..."
run $srccomp 
$sim stop 30
