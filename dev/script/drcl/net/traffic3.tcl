# traffic3.tcl
# Scenario:
#    Source (traffic_OnOff)
#      |
#      ---------> TrafficMonitor ----> Plotter

# test root
cd [mkdir drcl.comp.Component /test]

# set up on-off source: pktsize, avg sending rate, on period, off period
set src [java::new drcl.net.traffic.traffic_OnOff 100 4000 .01 .99]

set pg [java::call drcl.net.traffic.TrafficAssistant getTrafficComponent $src]
mkdir $pg source
puts "Source: [$pg info]"

set count [mkdir drcl.comp.tool.DataCounter counter]
connect -c $pg/down@ -to $count/in@

if 1 {
# Traffic monitors and plotter
set m_source [mkdir drcl.comp.tool.CountMonitor .source]
set plot [mkdir drcl.comp.tool.Plotter .plot]
if 0 {
set file [mkdir drcl.comp.io.FileComponent .file]
$file open "traffic3.plot"
connect -c $plot/.output@ -to $file/in@
setflag plot false $plot
}
connect -c $pg/down@ -to $m_source/down@pg
connect -c $m_source/sizecount@ -to $plot/1@0
}

# set up simulator
set sim [attach_simulator .]

puts "Simulation running..."
run $pg 
$sim stop 3000
