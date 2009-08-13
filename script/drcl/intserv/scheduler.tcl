# File: scheduler.tcl
#
# Scenario: multiple traffic sources on one scheduler
#
#  | TrafficSource0 |   | TrafficSource1 |
#  | TrafficShaper0 |   | TrafficShaper1 |  ......
#          |                    |              |
#          |--------\  /--------|              |
#                    \//-----------------------|
#                     |
#                Scheduler .......\
#                     |            \
#                    NI ........... NamTrace
#                     |            /
#                   Link          /
#                     | ........./
#                DataCounter
#

if {$argc < 1} {
	puts "args: <scheduler_class_name> ?<admission_class_name>?"
	exit
}

set SCHEDULER_CLASS "drcl.intserv.scheduler.scheduler_[lindex $argv 0]"
set scheduler [java::new $SCHEDULER_CLASS]; # test if the class exists
if {$argc > 1} {
	set ADMISSION_CLASS "drcl.intserv.scheduler.admission_[lindex $argv 1]"
	set admission [java::new $ADMISSION_CLASS]; # test if the class exists
	$scheduler setAdmission $admission
}
set BANDWIDTH  8000;   # link bandwidth (bps)
set BUFFER     65536;  # scheduler buffer (byte)
set PROP_DELAY 2.0;   # link propagation delay (second)
# set propagation delay appropriately so that the schedule is displayed nicely in NAM

#------------------------------------------------------------------
# create	Just a convenient procedure to create traffic objects and reservation resource 
#
# id_		source ID, an integer
# type_		data type: 0:best-efforts, 1:control, 3:QoS
# random_	parameters (list) for drcl.net.traffic.traffic_OnOff
# token_	parameters (list) for drcl.net.traffic.traffic_TokenBucket
#
# Global variables: source shaper rspec fspec tos.
# Created traffic objects are put in source(), token(), 
# created flowspec and rspec are put in fspec(), rspec(), 
# ToS values are put in tos()
proc create {id_ type_ random_ token_} {
	global source shaper rspec fspec tos
	# Create traffic source and shaper:
	eval [subst -nocommands \
		{set source($id_) [java::new drcl.net.traffic.traffic_OnOff $random_]}]
	set mtu_ [expr "[$source($id_) getMTU]+20"]; # 20: InetPacket header size
	eval [subst -nocommands \
		{set shaper($id_) [java::new drcl.net.traffic.traffic_TokenBucket $token_ $mtu_]}]

	# tos = type_ (0, 1, 3) + $id_ << 2(source $id_)
	set tos_ [expr {$type_ + ($id_ << 2)}]

	# Reservation for source $id_:
	set bw_ [expr int(ceil([$shaper($id_) getLoad]))]
	set buffer_ [$shaper($id_) getBurst]
	set rspec($id_) [java::new drcl.intserv.scheduler.SpecR_GR $bw_ $buffer_ $mtu_]
	set fspec($id_) [java::new drcl.intserv.SpecFlow $shaper($id_) $rspec($id_)]
	set tos($id_) $tos_
}

#------------------------------------------------------------------
# main procedure
#--------------------

# test root
cd [mkdir -q drcl.comp.Component /test]
cd /test

#----------------------------------------------------
# Set up scheduler, ni, link and receiving component
#----------------------------------------------------

puts "Set up scheduler, ni, link and counter..."
mkdir $scheduler scheduler
$scheduler configure $BANDWIDTH 1.0 $BUFFER 1.0; # bw bwRatio buffer bufferRatio
set ni [mkdir drcl.inet.core.ni.PointopointNI ni]
$ni setBandwidth $BANDWIDTH
set link [mkdir drcl.inet.Link link]
$link setPropDelay $PROP_DELAY
set counter [mkdir drcl.comp.tool.DataCounter counter]

connect $scheduler/output@ -and $ni/pull@
connect -c $ni/down@ -to $link/0@
connect -c $link/1@ -to $counter/in@

#--------------------
# Traffic Parameters
#--------------------

puts "Set up traffic parameters..."
foreach array_ "random token source shaper rspec fspec tos" { 
	catch {unset $array_} 
}
# To create token bucket source, we set up a "on-off" source and a token bucket shaper
# parameter for random source: pktSize, SendingRate, OnTime, OffTime
# parameter for token bucket shaper: max bucket size, init bucket size, token gen. rate, output rate
set random(0) "80 3200 .01 .99"
set token(0)  "500 500 4000 8e20"; # accounts for InetPacket header 20
set random(1) "80 640 .01 .99"
set token(1)  "100 100 800 8e20"
set random(2) "80 640 .01 .99"
set token(2)  "100 100 800 8e20"
set random(3) "80 640 .01 .99"
set token(3)  "100 100 800 8e20"
set random(4) "80 640 .01 .99"
set token(4)  "100 100 800 8e20"
set random(5) "80 640 .01 .99"
set token(5)  "100 100 800 8e20"

set type 	"3 3 3 3 3 3"; # flow type: 0: best-efforts, 1:control, 3:QoS; one for each flow

#-----------------------
# Set up traffic source
#-----------------------

puts "Set up traffic source components..."
set nsrc_ [array size random]
for {set i 0} {$i < $nsrc_} {incr i} { 
	# Create random and token-bucket traffic objects, reservation, and tos 
	# 	in source(), shaper(), fspec(), rspec() and tos():
	# proc create {id_ type_ random_ token_}
	create $i [lindex $type $i] $random($i) $token($i)

	# parameter to call createTrafficSource(): Traffic src dest protocol tos
	set tsrc_ [java::call drcl.inet.InetUtil createTrafficSource $source($i) $shaper($i) 0 1 $tos($i)]
	mkdir $tsrc_ "source$i"
	connect $tsrc_/down@ -to $scheduler/up@

	# Reserve resource for flows:
	! $scheduler addFlowspec $tos($i) $fspec($i)
}

set sim [attach_simulator .]

#------------
# NAM Traces
#------------

puts "Set up NamTrace..."

# Name of the file to which traces are written:
regexp {\.([^\.]+)$} $SCHEDULER_CLASS tmp outfile
append outfile ".nam"

# create NamTrace and FileComponent
set nam [mkdir -q drcl.intserv.NamTrace .nam]
set file [mkdir drcl.comp.io.FileComponent .file]
connect -c $nam/output@ -to $file/in@
$file open $outfile

# attach NamTrace to components
attach -c "$nam/+ -s 0 -d 1@" -with $scheduler/up@;     # enqueue
attach -c "$nam/- -s 0 -d 1@" -to   $scheduler/output@; # dequeue
attach -c "$nam/h -s 0 -d 1@" -to   $scheduler/output@; # hop
attach -c "$nam/r -s 0 -d 1@" -to   $link/1@;           # receive
attach -c "$nam/d -s 0 -d 1@" -to   $scheduler/.info@;  # drop
setflag garbage true $scheduler

# write head block to the nam trace file
$nam addColors [_to_string_array "red blue yellow green black orange"]; # six flows at most
$nam addNode 0 UP circle OliveDrab src
$nam addNode 1 UP circle blue sink
$nam addLink 0 1 UP $BANDWIDTH $PROP_DELAY right
$nam addQueue 0 1 0

puts "Running..."

#setflag debug true $scheduler
#setflag trace true -at send $scheduler/output@
#setflag trace true -at data $scheduler/up@
#setflag trace true *
setflag garbagedisplay true $scheduler
rt . stop
run source0; run .
script {puts "Done!"} -at 10.0 -on $sim
$sim resumeTo 10
