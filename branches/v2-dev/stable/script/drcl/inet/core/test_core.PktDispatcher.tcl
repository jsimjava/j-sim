# test_core.PktDispatcher.tcl
#
# Testing component drcl.inet.core.PktDispatcher and contracts
# drcl.inet.contract.PktSending/PktDelivery using drcl.comp.tool.ComponentTester.
#
# Connections between ComponentTester and PktDispatcher:
#                 |down0@pd ------------------ 0@down|
#                 |down1@pd ------------------ 1@down|
#                 |down2@pd ------------------ 2@down|
#                 |up3@pd ---------------------- 3@up|
# ComponentTester |up6@pd ---------------------- 6@up| PktDispatcher
#                 |pktarrival@ ----<---- .pktarrival@|
#                 |rt_query@ ----+------ .mcastquery@|
#                                 \----- .ucastquery@|
#              
# Note: This script does not test fragmentation and route query.

# root for testing
cd [mkdir drcl.comp.Component /test]
# the testee
set pd [mkdir drcl.inet.core.PktDispatcher pd]
set id [mkdir drcl.inet.core.Identity id]
set rt [mkdir drcl.inet.core.RT rt]
$pd bind $id
$pd bind $rt

# create three down ports and two ports for testing
mkdir $pd/1@down $pd/2@down $pd/3@up $pd/6@up
#mkdir $pd/.ucastquery@ $pd/.mcastquery@

# create tester and hookup
set serverType [java::field drcl.comp.Port PortType_SERVER]
set tester [mkdir drcl.comp.tool.ComponentTester tester]
setflag garbage true tester; # to match garbage events
# create and connect, at tester, down0@pd down1@pd, down2@pd, up3@pd, up6@pd
foreach i {0 1 2} {
	set down$i [mkdir $tester/down$i@pd]
	connect $tester/down$i@pd -and $pd/$i@down
}
foreach i {3 6} {
	set up$i [mkdir $tester/up$i@pd]
	connect $tester/up$i@pd -and $pd/$i@up
}
# create and connect, at tester, pktarrival@, service_id@, service_rt@, rtquery@
# the last three are server ports
set pktarrival [mkdir $tester/pktarrival@]
#set service_id [mkdir $tester/service_id@]
#set service_rt [mkdir $tester/service_rt@]
set rtquery [mkdir $tester/rtquery@]
#foreach port_ "$service_id $service_rt $rtquery" { $port_ setType $serverType }
connect $pktarrival -and $pd/.pktarrival@
#connect $service_id -and $pd/.service_id@
#connect $service_rt -and $pd/.service_rt@
connect $rtquery -and $pd/.mcastquery@ $pd/.ucastquery@

# simulator
set sim [attach_simulator .]

# create the packet for testing
set hd [java::new drcl.inet.InetPacket]
$hd setSource 1
$hd setTOS 777
$hd setTTL 10
$hd setHops 0
$hd setProtocol 3

# Test 1: delivers to local: unicast+router alert
# 0.0: Send the packet to pd/1@down, it will be delivered to pd/3@up
#      without querying identity (routerAlert)
if 1 {
puts "Test1"
$hd setDestination 10
$hd setRouterAlertEnabled true
set pkt [$hd clone]
$tester clearBatch
$tester addEvent "Test 1: Deliver to local, unicast + router alert."
$tester addEvent "send"  0.0 $pkt $down1
$tester addEvent "rcv"   0.0 [java::null] $pktarrival
$tester addEvent "rcv"   0.0 $pkt $up3
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# Test 2: delivers to local: unicast+identity lookup
#  0.0: Send the packet to pd/2@down, pd will query identity at .service_id@
# 50.0: tester replies with positive and the packet is delivered to pd/6@up
if 1 {
puts "Test2"
$tester clearBatch
$tester reset;
$hd setDestination 10
$hd setRouterAlertEnabled false
$hd setProtocol 6
$id add 10
set pkt [$hd clone]
$tester clearBatch
$tester addEvent "Test 2: Deliver to local, unicast + identity lookup."
$tester addEvent "send"   0.0 $pkt $down2
$tester addEvent "rcv"    0.0 [java::null] $pktarrival
#$tester addEvent "rr-request"  0.0 [java::new {long[]} 1 10] $service_id
#$tester addEvent "rr-reply"   50.0 [java::new {boolean[]} 1 true] $service_id
#$tester addEvent "rcv"   50.0 $pkt $up6
$tester addEvent "rcv"    0.0 $pkt $up6
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 3: routing forwarding: multicast
if 1 {
puts "Test3"
$tester clearBatch
$tester reset;
$hd setDestination -2; # mcast address
$hd setRouterAlertEnabled false
set pkt [$hd clone]
set key [java::new drcl.inet.data.RTKey 0 0 -2 -1 0 0]; # -2: mcast address
set ifs [java::new drcl.data.BitSet [java::new {int[]} 2 {2 0}]]
set entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]
$rt add $key $entry
$tester addEvent "Test 3: Routing forwarding: multicast."
$tester addEvent "send"        0.0 $pkt $down1
$tester addEvent "rcv"         0.0 [java::null] $pktarrival
#$tester addEvent "rr-request"  0.0 [java::new {long[]} 1 -2] $service_id
#$tester addEvent "rr-reply"    0.0 [java::new {boolean[]} 1 false] $service_id
#$tester addEvent "rr-request"  0.0 [java::null] $service_rt
#$tester addEvent "rr-reply"  100.0 [java::new {int[]} 2 {2 0}] $service_rt
#$tester addEvent "rcv"       100.0 $pkt $down2
#$tester addEvent "rcv"       100.0 $pkt $down0
$tester addEvent "rcv"         0.0 $pkt $down2
$tester addEvent "rcv"         0.0 $pkt $down0
$tester addEvent "finish"   1000.0
$tester run
}

wait_until "$sim isStopped"

# test 4: broadcast forwarding
if 1 {
puts "Test 4"
$tester clearBatch
$tester reset;
# argument: pktbody, src, dest, ra, ttl, tos, excluded
set req_ [java::call drcl.inet.contract.PktSending getBcastPack [java::null] 0 0 11 false 10 777 0]
$tester addEvent "Test 4: broadcast forwarding."
$tester addEvent "send"   0.0 $req_ $up3
$tester addEvent "rcv"    0.0 [java::null] pkt*@
$tester addEvent "rcv"    0.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "rcv"    0.0 [java::null] "drcl.inet.InetPacket" $down2
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 5: explicit mcast forwarding
if 1 {
puts "Test 5"
$tester clearBatch
$tester reset;
set req_ [java::call drcl.inet.contract.PktSending getMcastPack [java::null] 0 0 -3 false 10 777 [java::new {int[]} 2 {1 0}]]
$tester addEvent "Test 5: explicit multicast forwarding."
$tester addEvent "send"   0.0 $req_ $up6
$tester addEvent "rcv"    0.0 [java::null] pkt*@
$tester addEvent "rcv"    0.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "rcv"    0.0 [java::null] "drcl.inet.InetPacket" $down0
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 6: delivers to local and route-lookup multicast forwarding, from network
if 1 {
puts "Test 6"
$tester clearBatch
$tester reset;
$hd setDestination -20;# multicast addr
$hd setRouterAlertEnabled false
$hd setProtocol 6
set pkt [$hd clone]
$id add -20
set key [java::new drcl.inet.data.RTKey 0 0 -20 -1 0 0]; # -20: mcast address
set ifs [java::new drcl.data.BitSet [java::new {int[]} 3 {2 1 0}]]
set entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]
$rt add $key $entry
$tester addEvent "Test 6: Delivers to local + mcast forwarding, from network"
$tester addEvent "send"          0.0 $pkt $down1
$tester addEvent "rcv"           0.0 [java::null] pkt*@
#$tester addEvent "rr-request"    0.0 [java::new {long[]} 1 -20] $service_id
#$tester addEvent "rr-reply"     50.0 [java::new {boolean[]} 1 true] $service_id
#$tester addEvent "rcv"          50.0 $pkt $up6
$tester addEvent "rcv"           0.0 $pkt $up6
#$tester addEvent "rr-request"   50.0 [java::null] $service_rt
#$tester addEvent "rr-reply"    100.0 [java::new {int[]} 3 {2 1 0}] $service_rt
#$tester addEvent "rcv"         100.0 $pkt $down2
#$tester addEvent "rcv"         100.0 $pkt $down0
$tester addEvent "rcv"           0.0 $pkt $down2
$tester addEvent "rcv"           0.0 $pkt $down0
$tester addEvent "finish"     1000.0
$tester run
}

wait_until "$sim isStopped"

# test 7: delivers to local and route-lookup multicast forwarding, from local
if 1 {
puts "Test 7"
$tester clearBatch
$tester reset;
set req_ [java::call drcl.inet.contract.PktSending getForwardPack [java::null] 0 0 -11 false 10 777]
$id add -11
set key [java::new drcl.inet.data.RTKey 0 0 -11 -1 0 0]; # -11: mcast address
set ifs [java::new drcl.data.BitSet [java::new {int[]} 3 {2 0 1}]]
set entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]
$rt add $key $entry
$tester addEvent "Test 7: Delivers to local + mcast forwarding, from local"
$tester addEvent "send"          0.0 $req_ $up3
$tester addEvent "rcv"           0.0 [java::null] pkt*@
#$tester addEvent "rr-request"    0.0 [java::new {long[]} 1 -11] $service_id
#$tester addEvent "rr-reply"     50.0 [java::new {boolean[]} 1 true] $service_id
#$tester addEvent "rcv"          50.0 [java::null] "drcl.inet.InetPacket" $up3
$tester addEvent "rcv"           0.0 [java::null] "drcl.inet.InetPacket" $up3
#$tester addEvent "rr-request"   50.0 [java::null] $service_rt
#$tester addEvent "rr-reply"    100.0 [java::new {int[]} 3 {2 0 1}] $service_rt
#$tester addEvent "rcv"         100.0 [java::null] "drcl.inet.InetPacket" $down2
#$tester addEvent "rcv"         100.0 [java::null] "drcl.inet.InetPacket" $down0
#$tester addEvent "rcv"         100.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "rcv"           0.0 [java::null] "drcl.inet.InetPacket" $down2
$tester addEvent "rcv"           0.0 [java::null] "drcl.inet.InetPacket" $down0
$tester addEvent "rcv"           0.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 8: ttl exceeds
if 1 {
puts "Test 8"
$tester clearBatch
$tester reset;
$hd setDestination 33
$hd setRouterAlertEnabled false
$hd setHops 10
set pkt [$hd clone]
$tester addEvent "Test 8: TTL exceeds"
$tester addEvent "send"          0.0 $pkt $down2
$tester addEvent "rcv"           0.0 [java::null] pkt*@
#$tester addEvent "rr-request"    0.0 [java::new {long[]} 1 33] $service_id
#$tester addEvent "rr-reply"    50.0 [java::new {boolean[]} 1 false] $service_id
#$tester addEvent "rcv"          50.0 [java::null] [! $tester/.info@]
$tester addEvent "rcv"           0.0 [java::null] [! $tester/.info@]
$tester addEvent "finish"     1000.0
setflag garbage true $pd
$tester run
}

wait_until "$sim isStopped"

#test 9: src addr. unspecified
if 1 {
puts "Test 9"
$tester clearBatch
$tester reset;
set req_ [java::call drcl.inet.contract.PktSending getForwardPack [java::null] 0 [java::field drcl.net.Address NULL_ADDR] 111 false 10 777]
set key [java::new drcl.inet.data.RTKey 0 0 111 -1 0 0]; # 111: ucast address
set ifs [java::new drcl.data.BitSet [java::new {int[]} 1 1]]
set entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]
$rt add $key $entry
$tester addEvent "Test 10: src addr unspecified"
$tester addEvent "send"   0.0 $req_  $up3
$tester addEvent "rcv"    0.0 [java::null] pkt*@
#$tester addEvent "rr-request"    0.0 [java::null] $service_id
#$tester addEvent "rr-reply"   50.0 [java::new drcl.data.LongObj 55] $service_id
#$tester addEvent "rr-request"   50.0 [java::new {long[]} 1 111] $service_id
#$tester addEvent "rr-reply"   100.0 [java::new {boolean[]} 1 false] $service_id
#$tester addEvent "rr-request"  100.0 [java::null] $service_rt
#$tester addEvent "rr-reply"    150.0 [java::new {int[]} 1 1] $service_rt
#$tester addEvent "rcv"         150.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "rcv"           0.0 [java::null] "drcl.inet.InetPacket" $down1
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"
exit

