# traffic_eoo.tcl
# Scenario:
#       Source (traffic_ExpOnOff)
#          |--------------> TrafficMonitor --------|
#                                                  |
#                                                  V
#                                               Plotter

source "../../test/include.tcl"

# test root
cd [mkdir drcl.comp.Component /test_expoo]

set src [java::new drcl.net.traffic.traffic_ExpOnOff]
$src setPacketSize 150
$src setBurstRate 100000
$src setAveOnTime 10
$src setAveOffTime 20
puts "[$src oneline], period=[$src getPeriod], load=[$src getLoad]"

set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg generator

# Traffic monitors and plotter
set m_expoo [mkdir drcl.comp.tool.CountMonitor .expoo]
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $pg/down@ -to $m_expoo/down@pg
# connect monitors to plotter
connect -c $m_expoo/sizecount@ -to $plot/0@0

if { $testflag } {
	attach -c $testfile/in@ -to $m_expoo/sizecount@
}

# set up simulator
set sim [attach_simulator .]
$sim stop

puts "Simulation running..."
$pg run

$sim resumeTo 300
