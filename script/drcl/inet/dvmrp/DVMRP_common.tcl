# DVMRP_common.tcl
# Provides common operations for demonstration and debugging purposes.
# - host_event -join/-leave <group> -host <host> -router <router|router port>
# - send_mcast_pkt -message <content> -from <port path> -to <group> -size <size>
# - add_node <id> <netmask> <list of neighbors> <link> <node builder>

# -join/-leave <multicast group>
# -host <host path>
# -router(port) <router path> | <router port path>
proc host_event args {
	set host_ ""
	set router_ ""
	set type_ ""
	set group_ ""
	set var_ ""
	foreach arg_ $args {
		if {$var_ == ""} {
			if [string match "-join" $arg_] {
				set type_ join
				set var_ "group_"
			} elseif [string match "-leave" $arg_] {
				set type_ leave
				set var_ "group_"
			} elseif [string match "-host" $arg_] {
				set var_ "host_"
			} elseif [string match "-router" $arg_] {
				set var_ "router_"
			} else {
				puts "unknown option: $arg_"
				return
			}
		} else {
			set $var_ $arg_
			set var_ ""
			if {$host_ == "" || $router_ == ""} {
				continue;
			} else {
				# real action
				# 1. determine "if_"
				# 2. add address
				# 3. convey the host event to router
				set if_ -1
				set tmp_ [! -q $router_]
				if [java::isnull $tmp_] {
					if [regexp {/([0-9]+)@$} $router_ tmp_ if_] {
						set tmp_ [string range $router_ 0 [string first $tmp_ $router_]]
						set router_ [! $tmp_]
					} else {
						puts "Error in the '-router' option: $router_"
						return
					}
				} elseif [java::instanceof $tmp_ drcl.comp.Port] {
					set if_ [$tmp_ getID]
					set router_ [!!! [$tmp_ getHost]]
				}

				if {$if_ < 0} {
					# multihome
					! $router_ addAddress $group_
				} elseif [string match "none" $host_] {
					# do nothing
				} else {
					! $host_ addAddress $group_
				}

				if [string match "join" $type_] {
					set event_ [java::call drcl.inet.contract.McastHostEvent createJoinEvent $group_ $if_]
				} else {
					set event_ [java::call drcl.inet.contract.McastHostEvent createLeaveEvent $group_ $if_]
				}

				inject $event_ $router_/dvmrp/.mcastHost@
				set router_ ""
				set host_ ""
			}
		}
	}
}

# -message <content>
# -from <path of a csl up port>
# -to <multicast group>
# -size <message size>
proc send_mcast_pkt args {
	set message_ "mcast_packet"
	set from_ ""
	set to_ ""
	set size_ 100
	set var_ ""
	foreach arg_ $args {
		#puts "arg: '$arg_'"
		if {$var_ == ""} {
			if [string match "-message" $arg_] {
				set var_ "message_"
			} elseif [string match "-from" $arg_] {
				set var_ "from_"
			} elseif [string match "-to" $arg_] {
				set var_ "to_"
			} elseif [string match "-size" $arg_] {
				set var_ "size_"
			}
		} else {
			set $var_ $arg_
			set var_ ""
		}
	}

	if {$from_ == "" || $to_ == ""} {
		puts "Error: must provide both '-from <port>' and '-to <group>' options."
		return
	}

	# construct mcast packet
	set ra_ false
	set ttl_ 255
	set tos_ 0
	set pkt_ [java::call drcl.inet.contract.PktSending getForwardPack $message_ $size_ [java::field drcl.net.Address NULL_ADDR] $to_ $ra_ $ttl_ $tos_]
	inject $pkt_ $from_
}

proc add_node {id_ netmask_ neighbors_ link_ nodeBuilder_} {
	# build adjacency matrix and id array
	set adjMatrix_ ""
	set tmpadj_ ""
	set ids_ ""
	for {set j 0} {$j < [llength $neighbors_]} {incr j} {
		set neighbor_ [! [lindex $neighbors_ $j]]
		set nifs_ [$neighbor_ getNumOfPhysicalInterfaces]
		set tmp_ ""
		for {set i 0} {$i < $nifs_} {incr i} { lappend tmp_ -1 }
		lappend tmp_ [llength $neighbors_]
		lappend adjMatrix_ $tmp_

		lappend tmpadj_ $j
		lappend ids_ -1
	}
	lappend adjMatrix_ $tmpadj_
	lappend ids_ $id_
	set adjMatrix_ [java::new {int[][]} [llength $adjMatrix_] $adjMatrix_]
	set ids_ [java::new {long[]} [llength $ids_] $ids_]

	# add the node
	set tmp_ $neighbors_
	lappend tmp_ [java::null]
	set existing_  [eval "!! $tmp_"]
	java::call drcl.inet.InetUtil createTopology [! .] "n" "n" $existing_ $adjMatrix_ $ids_ $link_
	set tmp_ $neighbors_
	lappend tmp_ "n$id_"
	! $nodeBuilder_ build [eval "!! $tmp_"]

	# configure the new interface of existing nodes
	foreach neighbor_ $neighbors_ {
		set neighbor_ [! $neighbor_]
		set tmpid_ [$neighbor_ getDefaultAddress]
		set tmpinfo_ [$neighbor_ getInterfaceInfo 0]
		set tmplocal_ [$tmpinfo_ getLocalNetAddress]
		set nifs_ [$neighbor_ getNumOfPhysicalInterfaces]
		$neighbor_ setInterfaceInfo [expr $nifs_-1] [java::new drcl.inet.data.InterfaceInfo $tmplocal_]
	}

	# configure the interfaces of the newly created node
	set newNode_ [! "n$id_"]
	set nifs_ [$newNode_ getNumOfPhysicalInterfaces]
	for {set i 0} {$i < $nifs_} {incr i} {
		$newNode_ setInterfaceInfo $i [java::new drcl.inet.data.InterfaceInfo $id_ $netmask_]
	}

	# hookup the new node and run
	setflag debug true -at {debug_route debug_timeout debug_mcast_query debug_prune debug_graft} $newNode_/dvmrp
	watch -c -label FC -add $newNode_/csl/.rt_mcast@
	! $newNode_ run

	cat [eval "!! $tmp_"]/csl/hello
}


