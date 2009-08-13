# traffic1.tcl
# Scenario:
#       Source (traffic_PeakRate)
#          |--------------> TrafficMonitor --------|
#          V                                       |
#     TrafficShaper (traffic_TokenBucket)          |
#          |                                       V
#          ---------------> TrafficMonitor ----> Plotter

source "../../test/include.tcl"

# test root
cd [mkdir drcl.comp.Component /test]

# set up pg
set src [java::new drcl.net.traffic.traffic_PeakRate 100 150 .01 .04]
set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg random
puts "PeakRate: [$src oneline]"

# set up token bucket
set token [java::new drcl.net.traffic.traffic_TokenBucket 600 600 40000 8000000 600]
	# bucketSize, initBucketSize, tokenGenRate, outRate, MTU
mkdir [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $token] token_bucket
! token_bucket setBufferSize 600
puts "TokenBucket: [$token oneline], buffer size=[! token_bucket getBufferSize]"

# connect generator to shaper
connect $pg/down@ -to token_bucket/up@

# Traffic monitors and plotter
if 1 {
set m_peakrate [mkdir drcl.comp.tool.CountMonitor2 .peakrate]
set m_token [mkdir drcl.comp.tool.CountMonitor2 .token]
$m_peakrate setSizeEventNames "Throughput (bps)" "Byte Loss Rate (%)"
$m_token setSizeEventNames "Throughput (bps)" "Byte Loss Rate (%)"
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $pg/down@ -to $m_peakrate/down@pg
connect -c token_bucket/down@ -to $m_token/down@TokenBucket
# connect monitors to plotter
connect -c $m_peakrate/sizecount@ -to $plot/0@0
connect -c $m_peakrate/sizeloss@-to $plot/0@1
connect -c $m_token/sizecount@ -to $plot/1@0
connect -c $m_token/sizeloss@ -to $plot/1@1

if { $testflag } {
	attach -c $testfile/in@ -to $m_peakrate/sizecount@
	attach -c $testfile/in@ -to $m_peakrate/sizeloss@
	attach -c $testfile/in@ -to $m_token/sizecount@ 
	attach -c $testfile/in@ -to $m_token/sizeloss@
}
}

# set up simulator
set sim [attach_simulator event .]
$sim stop

puts "Simulation running..."
run $pg 

$sim resumeTo 100
