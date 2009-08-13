# traffic_poisson.tcl
# Scenario:
#       Source (traffic_Poisson)
#          |--------------> TrafficMonitor --------|
#                                                  |
#                                                  V
#                                               Plotter

source "../../test/include.tcl"

# test root
cd [mkdir drcl.comp.Component /test_expoo]

set src [java::new drcl.net.traffic.traffic_Poisson]
$src setPacketSize 150
$src setRate 100000
puts "[$src oneline], period=[$src getPeriod], load=[$src getLoad]"

set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg generator

# Traffic monitors and plotter
set m_poisson [mkdir drcl.comp.tool.CountMonitor .poisson]
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $pg/down@ -to $m_poisson/down@pg
# connect monitors to plotter
connect -c $m_poisson/sizecount@ -to $plot/0@0

if { $testflag } {
	attach -c $testfile/in@ -to $m_poisson/sizecount@
}

# set up simulator
set sim [attach_simulator event .]

puts "Simulation running..."
$pg run

$sim resumeTo 300
