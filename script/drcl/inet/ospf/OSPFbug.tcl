# the script that reveals a bug in OSPF before 1.2.1-p4 is issued
# because of different link propagation delays, some "ospf" links
# converge faster than the other and this causes the bug to surface
# and prevent neighbor state from advancing from "loading" to "full"
# so some "ospf" links never become "full"

cd [mkdir -q drcl.comp.Component /test]

# create the topology
	puts "create topology..."
	set link_ [java::new drcl.inet.Link]
	$link_ setPropDelay 0.3; # 300ms
	set adjMatrix_ [java::new {int[][]} 14 {{1 2 3} {0 3 6} {0 4 7} {0 1 10} {2 5 10} {4 6} {1 5 9} {2 8 13} {7 9 12} {6 8 11 13} {3 4 11 12} {9 10} {8 10 13} {7 9 12} }]
	java::call drcl.inet.InetUtil createTopology [! .] $adjMatrix_ $link_

# NodeBuilder
	puts "create builders..."
	set nb [mkdir drcl.inet.NodeBuilder .nodeBuilder]
	$nb setBandwidth 1.0e7; #10Mbps
	
	$nb build [! n*] {
		ospf drcl.inet.protocol.ospf.OSPF
	}
	
	! n*/ospf ospf_set_area_id 1


# setPropDelay
	! .link0 setPropDelay .009;#link0,0-1, 9ms
	! .link1 setPropDelay .009;#link1,0-2, 9ms
	! .link2 setPropDelay .007;#link2,3-0, 7ms
	! .link3 setPropDelay .013;#link3,3-1, 13ms
	! .link4 setPropDelay .02;#link4,6-1, 20ms
	! .link5 setPropDelay .007;#link5,4-2, 7ms
	! .link6 setPropDelay .016;#link6,7-2, 16ms
	! .link7 setPropDelay .015;#link7,10-3, 15ms
	! .link8 setPropDelay .007;#link8,5-4, 7ms
	! .link9 setPropDelay .011;#link9,10-4, 11ms
	! .link10 setPropDelay .007;#link10,5-6, 7ms
	! .link11 setPropDelay .007;#link11,9-6, 7ms
	! .link12 setPropDelay .005;#link12,8-7, 5ms
	! .link13 setPropDelay .008;#link13,13-7, 8ms
	! .link14 setPropDelay .005;#link14,9-8, 5ms
	! .link15 setPropDelay .007;#link15,12-8, 7ms
	! .link16 setPropDelay .008;#link16,11-9, 8ms
	! .link17 setPropDelay .001;#link17,13-9, 1ms
	! .link18 setPropDelay .009;#link18,11-10, 9ms
	! .link19 setPropDelay .014;#link19,12-10, 14ms
	! .link20 setPropDelay .004;#link20,13-12, 4ms

# set up simulator
	puts "set up simulator..."
	set sim [attach_simulator event .]
	$sim stop
	run .

	#setflag debug true n*/ospf;
	#setflag debug false -at "detail" n*/ospf;
	# routes converge at about 15.0
	$sim resumeTo 50

	puts "Done!"

