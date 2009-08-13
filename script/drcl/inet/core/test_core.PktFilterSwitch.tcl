# test_core.PktFilterSwitch.tcl
#
# Testing component drcl.inet.core.PktFilterSwitch and contract
# drcl.inet.contract.ConfigSwitch
#
# Connections between ComponentTester and PktFilterSwitch:
#                  |1@0 ------------------------------ 1@0|
#  ComponentTester |2@1 ------------------------------ 2@1| PktFilterSwitch
#                  |0@2 ------------------------------ 0@2|
#                  |config@ ------- .service_configswitch@|

# test root
cd [mkdir drcl.comp.Component /test]

# the testee
set swtch [mkdir drcl.inet.core.PktFilterSwitch sw]
mkdir $swtch/1@0 $swtch/2@1 $swtch/0@2

# create tester and hookup
set tester [mkdir drcl.comp.tool.ComponentTester tester]
set config [mkdir $tester/config@]
set p10 [mkdir $tester/1@0]
set p21 [mkdir $tester/2@1]
set p02 [mkdir $tester/0@2]
connect $config -and $swtch/.service_configswitch@
connect $p10 -and $swtch/1@0
connect $p21 -and $swtch/2@1
connect $p02 -and $swtch/0@2

# set up simulator
set sim [attach_simulator .]

# setup requests
set req1 "REQUEST1"
set req2 "REQUEST2"
set req3 "REQUEST3"
set reply1 "REPLY1"
set reply2 "REPLY2"
set reply3 "REPLY3"
set sreq1 [java::new drcl.inet.contract.ConfigSwitch\$Message 1 2 $req1]
set sreq2 [java::new drcl.inet.contract.ConfigSwitch\$Message 0 1 $req2]
set sreq3 [java::new drcl.inet.contract.ConfigSwitch\$Message 2 0 $req3]

# setup test
$tester clearBatch
$tester reset; # reset the component and simulator
$tester addEvent "send"         0.0 $sreq1 $config
$tester addEvent "rr-request"   0.0 $req1 $p21
$tester addEvent "rr-reply"    10.0 $reply1 $p21
$tester addEvent "send"        10.0 $sreq2 $config
$tester addEvent "send"        10.0 $sreq3 $config
$tester addEvent "rcv"         10.0 $reply1 $config
$tester addEvent "rr-request"  10.0 $req2 $p10
$tester addEvent "rr-request"  10.0 $req3 $p02
$tester addEvent "rr-reply"    20.0 $reply2 $p10
$tester addEvent "rcv"         20.0 $reply2 $config
$tester addEvent "rr-reply"    30.0 $reply3 $p02
$tester addEvent "rcv"         30.0 $reply3 $config
$tester addEvent "finish"     100.0
$tester run

wait_until "$sim isStopped"
exit
