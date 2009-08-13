# mg1.tcl
#
# A simple M/G/1 queue where it is a constant-rate server
# rho (utilization) = 0.6 ==> avg number of packets in queue ~ 0.45

cd [mkdir drcl.comp.Component /mm1]

set src [java::new drcl.net.traffic.traffic_Poisson]
$src setPacketSize 120
$src setRate 4800000
puts "[$src oneline], period=[$src getPeriod], load=[$src getLoad]"

set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg source

set server [mkdir drcl.inet.core.ni.DropTailPointopointNI server]
$server setBandwidth 8000000
$server setMode pkt

connect -c $pg/down@ -to $server/up@

puts "Set up TrafficMonitor & Plotter....."
set plot [mkdir drcl.comp.tool.Plotter .plot]
set tm [mkdir drcl.net.tool.TrafficMonitor2 .tm]
#$tm setPktModeEnabled true

connect -c $server/down@ -to $tm/in@

connect -c $tm/bytecount@ -to $plot/0@0
connect -c $tm/byteloss@ -to $plot/0@1

set qavg [mkdir drcl.comp.tool.RunningAverage qavg]
setflag timeAverage true $qavg
attach -c $qavg/p@ -to $server/.q@
connect -c $qavg/p@ -to $plot/0@2
! .plot setTitle 2 "Average Number of Pkts in Queue"

puts "simulation begins..."
set sim [attach_simulator event .]
$sim stop
run .
script {puts [$sim getTime]} -period 50.0 -on $sim


$sim resumeTo 1000
