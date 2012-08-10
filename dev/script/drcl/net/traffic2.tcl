# traffic2.tcl
# Scenario:
#    Shaped Source (traffic_PeakRate/traffic_TokenBucket)
#          |
#          |
#          ---------------> TrafficMonitor ----> Plotter

# test root
cd [mkdir drcl.comp.Component /test]

# set up pg
set src [java::new drcl.net.traffic.traffic_PeakRate 100 150 .01 .04]
# set up token bucket
set token [java::new drcl.net.traffic.traffic_TokenBucket 600 600 40000 8000000 600]

set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficSource $src $token]
mkdir $pg source
puts "Source: [$pg info]"

set count [mkdir drcl.comp.tool.DataCounter counter]
connect -c $pg/down@ -to $count/in@

$pg setBufferSize 600

# Traffic monitors and plotter
set m_token [mkdir drcl.comp.tool.CountMonitor2 .token]
$m_token setSizeEventNames "Throughput (bps)" "Byte Loss Rate (%)"
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $pg/down@ -to $m_token/down@pg
# connect monitors to plotter
connect -c $m_token/sizecount@ -to $plot/1@0
connect -c $m_token/sizeloss@ -to $plot/1@1
if 1 {
$pg setSendUnshapedTrafficEnabled true
set m_peakrate [mkdir drcl.comp.tool.CountMonitor2 .peakrate]
$m_peakrate setSizeEventNames "Throughput (bps)" "Byte Loss Rate (%)"
connect -c $pg/.timer@ -to $m_peakrate/timer@pg
connect -c $m_peakrate/sizecount@ -to $plot/0@0
#connect -c $m_peakrate/sizeloss@-to $plot/0@1
}

# set up simulator
set sim [attach_simulator .]

puts "Simulation running..."
run $pg 
$sim stop 100
