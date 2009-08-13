# traffic_poo.tcl
# Scenario:
#       Source (traffic_ParetoOnOff)
#          |--------------> TrafficMonitor --------|
#                                                  |
#                                                  V
#                                               Plotter

# test root
cd [mkdir drcl.comp.Component /test_paroo]

# set source
set src [java::new drcl.net.traffic.traffic_ParetoOnOff]
$src setPacketSize 150
$src setBurstRate 100000
$src setAveOnTime 10
$src setAveOffTime 20
$src setShapeParaOn 2
$src setShapeParaOff 1.2
set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg generator
puts "ParetoOnOffTraffic: [$src oneline], period=[$src getPeriod], load=[$src getLoad]"

# Traffic monitors and plotter
set m_paroo [mkdir drcl.comp.tool.CountMonitor .paroo]
set plot [mkdir drcl.comp.tool.Plotter .plot]
# connect monitors
connect -c $pg/down@ -to $m_paroo/down@pg
# connect monitors to plotter
connect -c $m_paroo/sizecount@ -to $plot/0@0
#connect -c $m_paroo/sizeloss@-to $plot/0@1

# set up simulator
set sim [attach_simulator .]

puts "Simulation running..."
$pg run
$sim stop 300
