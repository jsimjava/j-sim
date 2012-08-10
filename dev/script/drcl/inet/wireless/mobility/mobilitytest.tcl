
set minx   0.0
set maxx 100.0
set miny   0.0
set maxy 100.0
set dx     1.0
set dy     1.0
set maxSpeed 2.0

cd [mkdir test]

set mob [mkdir drcl.inet.mac.MobilityModel mobility]
set convert [mkdir PositionReportConvert converter]
set plot [mkdir drcl.comp.tool.Plotter plotter]

connect $mob/.query@ -and $convert/query@
connect -c $convert/out@ -to $plot/0@0

$mob setSeed 11101
$mob setTopologyParameters $maxx $maxy $minx $miny $dx $dy 0
$mob setPosition $maxSpeed 0 0 0
$plot setXRange 0 $minx $maxx
$plot setYRange 0 $miny $maxy

# install trajectory
if 1 {
	set r [java::new java.util.Random 3091]
	set np 50; # number of points
	set t [java::new {double[][]} $np]
	set time 0.0
	set x0 [expr ($minx + $maxx) / 2]
	set y0 [expr ($miny + $maxy) / 2]
	set x $x0; set y $y0
	set incx 20
	set incy 20
	for {set i 0} {$i<$np-1} {incr i} {
		$t set $i [java::new {double[]} 4 "$time $x $y 0"]
		set time [expr $time + 100.0*[$r nextDouble]]
		set x [expr $incx*([$r nextDouble]-0.5)+$x]
		set y [expr $incy*([$r nextDouble]-0.5)+$y]
		if {$x > $maxx} { set x $maxx} elseif {$x < $minx} { set x $minx}
		if {$y > $maxy} { set y $maxy} elseif {$y < $miny} { set y $miny}
	}
	$t set [expr $np-1] [java::new {double[]} 4 "$time $x0 $y0 0"]
	$mob installTrajectory $t
}

set sim [attach_simulator .]
run .
