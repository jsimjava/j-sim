# test_core.RT.tcl
#
# Testing component drcl.inet.core.RT and contract drcl.inet.contract.RTLookup/RTConfig
# using drcl.comp.tool.ComponentTester.
#
# Connections between ComponentTester and RT:
#                 |rt@ ------------- .service_rt@|
# ComponentTester |rtchange@ -+----<-- .rt_ucast@| RT
#                 |            \---<-- .rt_mcast@|

# test root
cd [mkdir drcl.comp.Component /test]
# the testee and tester
set rt [mkdir -q drcl.inet.core.RT rt]
set tester [mkdir drcl.comp.tool.ComponentTester tester]
set port [mkdir $tester/rt@]
set rtchanged [mkdir $tester/rtchanged@]
connect $port -to $rt/.service_rt@
connect $rt/.rt_*@ -to $rtchanged

# set up simulator
set sim [attach_simulator .]

# create route configuration request for testing
set ifs [java::new drcl.data.BitSet [java::new {int[]} 3 {0 2 4}]]
set base_entry [java::new drcl.inet.data.RTEntry $ifs "Hello!"]

# test 1: add an entry w/o timeout
#   0.0: add (100,100,100),(0 2 4),"Hello!" w/o timeout
# 100.0: use both lookup and retrieve to verify
if 1 {
puts "Test 1"
set key [java::new drcl.inet.data.RTKey 100 100 100]
set entry_ [!!! [$base_entry clone]]
set req [java::call drcl.inet.contract.RTConfig createAddRequest $key $entry_ -1.0]
set lookupreq [java::call drcl.inet.contract.RTConfig createRetrieveRequest $key "exact match"]
$tester clearBatch
! . reset; # reset the component
$tester addEvent "Test: add an entry w/o timeout"
$tester addEvent "send"   0.0 $req $port
$tester addEvent "rcv"    0.0 [java::null] $rtchanged
$tester addEvent "rcv"    0.0 [java::null] $port
$tester addEvent "Test: look up the entry"
$tester addEvent "send" 100.0 $key $port
$tester addEvent "rcv"  100.0 [java::new {int[]} 3 {0 2 4}] $port
$tester addEvent "send" 100.0 $lookupreq $port
$tester addEvent "rcv"  100.0 $entry_ $port
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"
[java::field System out] println [$rt info]

# test 2: add an entry w/ timeout
#   0.0: add (200,-200,200),(0,4),"Hello!" w/ timeout duration 200.0
# 100.0: use "retrieve" to verify
# 199.0-201.0: the entry is timed out and removed at 200.0. use lookup to verify
# 300.0: add, again, (200,-200,200),(0,4),"Hello!" w/ timeout duration 200.0
# 499.0: lookup to verify and then extend timeout time to 699.0 by "modify" ("add" actually)
# 698.0-700.0: the entry is timed out and removed at 699.0. use lookup to verify
if 1 {
puts "Test 2"
# make request
set key2 [java::new drcl.inet.data.RTKey 200 -200 200]; # -200, mcast address
$ifs {clear int} 2; # 0, 4 remain
set entry2_ [!!! [$base_entry clone]]
set req [java::call drcl.inet.contract.RTConfig createAddRequest $key2 $entry2_ 200.0]
set lookupreq2 [java::call drcl.inet.contract.RTConfig createRetrieveRequest $key2 "exact match"]
$tester clearBatch
$tester reset; # reset the component
$tester addEvent "Test: add an entry with timeout 200.0"
$tester addEvent "send"   0.0 $req $port
$tester addEvent "rcv"    0.0 [java::null] $rtchanged
$tester addEvent "rcv"    0.0 [java::null] $port
$tester addEvent "send" 100.0 $lookupreq2 $port
$tester addEvent "rcv"  100.0 $entry2_ $port
$tester addEvent "Test: look up timed-out entry"
$tester addEvent "send" 199.0 $key2 $port
$tester addEvent "rcv"  199.0 [java::new {int[]} 2 {0 4}] $port
$tester addEvent "rcv"  200.0 [java::null] $rtchanged
$tester addEvent "send" 201.0 $key2 $port
$tester addEvent "rcv"  201.0 [java::null] $port
$tester addEvent "Test: add an entry with timeout 200.0 and extend it at 499.0"
$tester addEvent "send" 300.0 $req $port
$tester addEvent "rcv"  300.0 [java::null] $rtchanged
$tester addEvent "rcv"  300.0 [java::null] $port
$tester addEvent "send" 499.0 $key2 $port
$tester addEvent "rcv"  499.0 [java::new {int[]} 2 {0 4}] $port
$tester addEvent "send" 499.0 $req $port;# extend it
$tester addEvent "rcv"  499.0 [java::null] $rtchanged
$tester addEvent "rcv"  499.0 [java::null] $port
$tester addEvent "send" 698.0 $key2 $port
$tester addEvent "rcv"  698.0 [java::new {int[]} 2 {0 4}] $port
$tester addEvent "rcv"  699.0 [java::null] $rtchanged
$tester addEvent "send" 700.0 $key2 $port
$tester addEvent "rcv"  700.0 [java::null] $port
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 3: modify an entry 
# modify the entry added in test 1, with new interfaces and extension
#   0.0: send a "modify" request with new if set and extension
# 100.0: use "retrieve" to verify
if 1 {
puts "Test 3"
# make request
set entry3_ [!!! [$base_entry clone]]
$entry3_ setExtension "New Extension!"
set req [java::call drcl.inet.contract.RTConfig createAddRequest $key $entry3_ -1.0]
$tester clearBatch
$tester reset; # reset the component
$tester addEvent "Test: Modify the first entry"
$tester addEvent "send"   0.0 $req $port
$tester addEvent "rcv"    0.0 [java::null] $rtchanged
$tester addEvent "rcv"    0.0 [java::null] $port
$tester addEvent "send" 100.0 $lookupreq $port
$tester addEvent "rcv"  100.0 $entry3_ $port
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 4: graft/prune interfaces
# graft/prune interfaces of the entry from test 1 and 3
#   0.0: lookup the entry, should have if (0,4)
# 100.0: graft if (2)
# 200.0: use "lookup" to verify, should have if (0,2,4)
# 300.0: prune if (0,2)
# 400.0: use "lookup" to verify, should have if (4)
# 500.0: the entry is timed out and removed
if 1 {
puts "Test 4"
# make request: graft interface 2
set ifs [java::new drcl.data.BitSet [java::new {int[]} 1 {2}]]
set graftreq1 [java::call drcl.inet.contract.RTConfig createGraftRequest $key $ifs -1.0]
# make request: prune interface 0 and 2
set ifs [java::new drcl.data.BitSet [java::new {int[]} 2 {0 2}]]
set prunereq1 [java::call drcl.inet.contract.RTConfig createPruneRequest $key $ifs 200.0]

$tester clearBatch
$tester reset; 
$tester addEvent "Test: graft"
$tester addEvent "send"   0.0 $lookupreq $port
$tester addEvent "rcv"    0.0 [java::null] $port
$tester addEvent "send" 100.0 $graftreq1 $port
$tester addEvent "rcv"  100.0 [java::null] $rtchanged
$tester addEvent "rcv"  100.0 [java::null] $port
$tester addEvent "send" 200.0 $lookupreq $port
$tester addEvent "rcv"  200.0 [java::null] $port
$tester addEvent "Test: prune"
$tester addEvent "send" 300.0 $prunereq1 $port
$tester addEvent "rcv"  300.0 [java::null] $rtchanged
$tester addEvent "rcv"  300.0 [java::null] $port
$tester addEvent "send" 400.0 $lookupreq $port
$tester addEvent "rcv"  400.0 [java::null] $port
$tester addEvent "rcv"  500.0 [java::null] $rtchanged
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

puts "Test 5"
# test 5: retrieve/remove entries - all kinds of matches
# First, add 5 entries (1,2,5,6,7) to RT
#  0.0: use "get all" to verify the 5 entries
# 10.0: retrieve (5,6,7) by wildcard match (#0100, #1100)
# 20.0: retrieve (1,5) by match all of (#0101)
# 30.0: retrieve (5) by longest match all of (#0101)
# 40.0-41.0: remove (5,7) by wildcard match (#0101, #1101), verify by "get all"
# 50.0-51.0: remove (2,6) by match all of (#0110), verify by "get all"
# 60.0-61.0: remove (1) by exact match, verify by "get all"
set keys(1) [java::new drcl.inet.data.RTKey 1 -5 1 -5 1 -5]
set keys(2) [java::new drcl.inet.data.RTKey 2 -5 2 -5 2 -5]
set keys(5) [java::new drcl.inet.data.RTKey 5 5 5]
set keys(6) [java::new drcl.inet.data.RTKey 6 6 6]
set keys(7) [java::new drcl.inet.data.RTKey 7 7 7]

foreach i {1 2 5 6 7} {
	set entry_ [java::new drcl.inet.data.RTEntry [java::new drcl.data.BitSet [java::new {int[]} 2 "0 $i"]] "entry$i"]
	$rt add $keys($i) $entry_ -1.0
}
set get_all [java::call drcl.inet.contract.RTConfig createGetAllRequest]
set retrieve4 [java::call drcl.inet.contract.RTConfig createRetrieveRequest [java::new drcl.inet.data.RTKey 4 -4 4 -4 4 -4] "match *"];# match 5,6,7
set retrieve5 [java::call drcl.inet.contract.RTConfig createRetrieveRequest [java::new drcl.inet.data.RTKey 5 5 5] "match all"];# match 1,5
set retrieve5_2 [java::call drcl.inet.contract.RTConfig createRetrieveRequest [java::new drcl.inet.data.RTKey 5 5 5] "longest match"];# match 5
set remove5 [java::call drcl.inet.contract.RTConfig createRemoveRequest [java::new drcl.inet.data.RTKey 5 -3 5 -3 5 -3] "match *"]; # remove 5,7
set remove6 [java::call drcl.inet.contract.RTConfig createRemoveRequest [java::new drcl.inet.data.RTKey 6 6 6] "match all"]; # remove 2,6
set remove1 [java::call drcl.inet.contract.RTConfig createRemoveRequest [java::new drcl.inet.data.RTKey 1 -5 1 -5 1 -5] "exact match"]; # remove 1

$tester clearBatch
$tester reset; 
$tester addEvent "Test: Retrieve/remove"
$tester addEvent "send"   0.0 $get_all $port
$tester addEvent "rcv"    0.0 [java::null] $port
$tester addEvent "send"  10.0 $retrieve4 $port
$tester addEvent "rcv"   10.0 [java::null] $port
$tester addEvent "send"  20.0 $retrieve5 $port
$tester addEvent "rcv"   20.0 [java::null] $port
$tester addEvent "send"  30.0 $retrieve5_2 $port
$tester addEvent "rcv"   30.0 [java::null] $port
$tester addEvent "send"  40.0 $remove5 $port
$tester addEvent "rcv"   40.0 [java::null] $rtchanged
$tester addEvent "rcv"   40.0 [java::null] $port
$tester addEvent "send"  41.0 $get_all $port
$tester addEvent "rcv"   41.0 [java::null] $port
$tester addEvent "send"  50.0 $remove6 $port
$tester addEvent "rcv"   50.0 [java::null] $rtchanged
$tester addEvent "rcv"   50.0 [java::null] $port
$tester addEvent "send"  51.0 $get_all $port
$tester addEvent "rcv"   51.0 [java::null] $port
$tester addEvent "send"  60.0 $remove1 $port
$tester addEvent "rcv"   60.0 [java::null] $rtchanged
$tester addEvent "rcv"   60.0 [java::null] $port
$tester addEvent "send"  61.0 $get_all $port
$tester addEvent "rcv"   61.0 [java::null] $port
$tester run

wait_until "$sim isStopped"
exit
