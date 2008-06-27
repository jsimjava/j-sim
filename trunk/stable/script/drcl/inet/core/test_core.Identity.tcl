# test_core.Identity.tcl
#
# Testing component drcl.inet.core.Identity and contract drcl.inet.contract.IDLookup/IDConfig
# using drcl.comp.tool.ComponentTester.
#
# Connections between ComponentTester and Identity:
#                 |idconfig@ ------- .service_id@|
# ComponentTester |idchange@ ----<----<----- .id@| Identity
#                 |                              |

# test root
cd [mkdir drcl.comp.Component /test]

# create testee and tester, and hookup them
set id [mkdir -q drcl.inet.core.Identity id]
set tester [mkdir -q drcl.comp.tool.ComponentTester tester]
$tester setRcvEnabled false; # turn off receipt notification for cleaner test report
set idport [mkdir $tester/idconfig@]
set idchanged [mkdir $tester/idchange@] 
connect $idport -to $id/.service_id@
connect $id/.id@ -to $idchanged

set sim [attach_simulator .]

# test 1: add an entry w/ timeout
#   0.0: add an identity of 10 with timeout duration 200.0
# 100.0: query the timeout time of identity 10
# 200.0: 10 is timed out and removed (event)
# 300.0: query again as at 100.0
if 1 {
puts "Test 1"
set req [!!! [java::call drcl.inet.contract.IDConfig createAddRequest 10 200.0]]
set req2 [!!! [java::call drcl.inet.contract.IDConfig createQueryRequest 10]]
$tester clearBatch
! . reset; # reset the component and simulator
$tester addEvent              "Test 1: add an id, w/ timeout"
$tester addEvent "send"   0.0 $req $idport
$tester addEvent "rcv"    0.0 [java::null] $idchanged;# event
$tester addEvent "rcv"    0.0 [java::null] $idport; # reply
$tester addEvent              "Test: look up the entry"
$tester addEvent "send" 100.0 $req2 $idport
$tester addEvent "rcv"  100.0 [java::null] $DOUBLE_ARRAY $idport
$tester addEvent "rcv"  200.0 [java::null] $idchanged
$tester addEvent "send" 300.0 $req2 $idport
$tester addEvent "rcv"  300.0 [java::null] $DOUBLE_ARRAY $idport
$tester addEvent "finish" 1000.0
$tester run
}

wait_until "$sim isStopped"

# test 2: more thorough tests on config and lookup
#   0.0: add three identities 20, 30, 40 with timeout duration 200.0, 300.0, 400.0
# 100.0: test "query one", "query all" and "get default identity"
# 199.0-201.0: ID 20 is timed out and removed, use lookup request and "query all" to verify
# 279.0-281.0: remove ID 30 manually, use "query all" to verify
# 400.0: ID 40 is timed out and removed
# 500.0: add ID 10 w/o timeout, it becomes default ID
# 501.0: use "query one" and "get default ID" to verify
puts "Test 2"
set ids_ [java::new {long[]} 3 {20 30 40}]
set timeouts_ [java::new {double[]} 3 {200.0 300.0 400.0}]
set add_3_ids [java::call drcl.inet.contract.IDConfig createAddRequest $ids_ $timeouts_]
set add_10_200 [java::call drcl.inet.contract.IDConfig createAddRequest 10 200.0]
set add_10_neg [java::call drcl.inet.contract.IDConfig createAddRequest 10 -1.0]
set add_10 [java::call drcl.inet.contract.IDConfig createAddRequest 10]
set add_20_200 [java::call drcl.inet.contract.IDConfig createAddRequest 20 200.0]
set query_10 [java::call drcl.inet.contract.IDConfig createQueryRequest 10]
set query_20 [java::call drcl.inet.contract.IDConfig createQueryRequest 20]
set query_30 [java::call drcl.inet.contract.IDConfig createQueryRequest 30]
set query_40 [java::call drcl.inet.contract.IDConfig createQueryRequest 40]
set query_all [java::call drcl.inet.contract.IDConfig createQueryRequest]
set remove_10 [java::call drcl.inet.contract.IDConfig createRemoveRequest 10]
set remove_20 [java::call drcl.inet.contract.IDConfig createRemoveRequest 20]
set remove_30 [java::call drcl.inet.contract.IDConfig createRemoveRequest 30]
set remove_40 [java::call drcl.inet.contract.IDConfig createRemoveRequest 40]
set remove_2_ids [java::call drcl.inet.contract.IDConfig createRemoveRequest [java::new {long[]} 2 {20 40}]]
set get_default [java::call drcl.inet.contract.IDLookup createGetDefaultRequest]
set get_all [java::call drcl.inet.contract.IDLookup createGetAllRequest]
set lookup [java::call drcl.inet.contract.IDLookup createQueryRequest [java::new {long[]} 3 {20 30 40}]]

puts "Test 3"
$tester clearBatch
$tester reset;
$tester addEvent              "----- Test : add a list of ids:([java::call drcl.util.StringUtil toString $ids_]) w/ timeout ([java::call drcl.util.StringUtil toString $timeouts_])"
$tester addEvent "send"   0.0 $add_3_ids $idport
$tester addEvent "rcv"    0.0 [java::null] $idchanged
$tester addEvent "rcv"    0.0 [java::null] $idport
$tester addEvent              "Test: query 20's timeout"
$tester addEvent "send" 100.0 $query_20 $idport
$tester addEvent "rcv"  100.0 [java::null] $DOUBLE_ARRAY $idport
$tester addEvent              "Test: query all"
$tester addEvent "send" 100.0 $lookup $idport
$tester addEvent "rcv"  100.0 [java::new {boolean[]} 3 {1 1 1}] $idport
$tester addEvent              "Test: get default"
$tester addEvent "send" 100.0 $get_default $idport
$tester addEvent "rcv"  100.0 [java::new drcl.data.LongObj 20] $idport
$tester addEvent ""
$tester addEvent              "----- Test: check timeout of 20"
$tester addEvent "send" 199.0 $lookup $idport
$tester addEvent "rcv"  199.0 [java::new {boolean[]} 3 {1 1 1}] $idport
$tester addEvent "rcv"  200.0 [java::null] $idchanged
$tester addEvent "send" 201.0 $get_all $idport
$tester addEvent "rcv"  201.0 [java::new {long[]} 2 {30 40}] $idport
$tester addEvent ""
$tester addEvent              "----- Test: remover id 30"
$tester addEvent "send" 279.0 $query_all $idport
$tester addEvent "rcv"  279.0 [java::null] "$OBJECT_ARRAY_PREFIX\java.lang.Object\;" $idport
$tester addEvent "send" 280.0 $remove_30 $idport
$tester addEvent "rcv"  280.0 [java::null] $idchanged
$tester addEvent "rcv"  280.0 [java::null] $idport
$tester addEvent "send" 281.0 $query_all $idport
$tester addEvent "rcv"  281.0 [java::null] "$OBJECT_ARRAY_PREFIX\java.lang.Object\;" $idport
$tester addEvent "rcv"  400.0 [java::null] $idchanged
$tester addEvent ""
$tester addEvent              "----- Test: check case of no timeout"
$tester addEvent "send" 500.0 $add_10_neg $idport
$tester addEvent "rcv"  500.0 [java::null] $idchanged
$tester addEvent "rcv"  500.0 [java::null] $idport
$tester addEvent "send" 501.0 $query_10 $idport
$tester addEvent "rcv"  501.0 [java::null] $DOUBLE_ARRAY $idport
$tester addEvent "send" 501.0 $get_default $idport
$tester addEvent "rcv"  501.0 [java::new drcl.data.LongObj 10] $idport
$tester addEvent "finish" 1000.0
$tester run

wait_until "$sim isStopped"
exit

