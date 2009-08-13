README.txt for J-Sim 1.3

Refer to CHANGE_LOG.txt for changes.
For more information about J-Sim, including tutorials, please visit
the J-Sim website at http://j-sim.cs.uiuc.edu.

February, 2004
The J-Sim Team


------------------------------------------------------------------------------

TABLE OF CONTENTS

1. SYSTEM REQUIREMENT
2. INSTALL J-SIM IN UNIX/LINUX
3. INSTALL J-SIM IN WINDOWS
4. RUN J-SIM
5. BATCH RUN
6. DIRECTORY STRUCTURE IN J-SIM ARCHIVE
7. COMPILING SOURCE
8. SPONSORS
9. J-SIM TEAM
10. ACKNOWLEDGEMENT
11. COPYRIGHT

------------------------------------------------------------------------------

1. SYSTEM REQUIREMENT

Running J-Sim requires
- a Java Virtual Machine (JVM).
- JDK1.4 or newer.

For Linux users, a good alternative is Blackdown's JDK (www.blackdown.org)
or "IBM's Developer Kit for Linux" (http://www.ibm.com/java).

------------------------------------------------------------------------------

2. INSTALL J-SIM IN UNIX/LINUX

Step 1. Unpack the archive to a directory (the J-Sim root).
Step 2. Set up environment variables J-SIM, CLASSPATH, JAVA_HOME, and IS_UNIX:

   J_SIM=... 		# the J-Sim root
   CLASSPATH=.:$J_SIM/classes:$J_SIM/jars/tcl.zip:$J_SIM/jars/jython.jar
   JAVA_HOME=... 	# javac and javadoc should be in $JAVA_HOME/bin
   IS_UNIX=... 		# can be anything

   The first two are for running J-Sim, and the last two for compiling 
   sources.

------------------------------------------------------------------------------

3. INSTALL J-SIM IN WINDOWS

Step 1. Unpack the archive to a directory (the J-Sim root).
Step 2. Modify the J-Sim root directory (J_SIM), and Java home directory
        (JAVA_HOME) in "setcpath.bat".
Step 3. Run the "setcpath.bat" script to set environment variables JAVA_HOME,
        J-SIM and CLASSPATH before using the package.  The first two
        variables are for GNU make.  The last one is for running J-Sim.
   
   One may set the environment variables whenever and wherever is appropriate
   (for example, C:\autoexec.bat for Windows 9x, the environment variables
   applet in the "System" control panel for Windows NT/2000/XP) so that one
   does not need to run the above script every time starting J-Sim.

------------------------------------------------------------------------------

4. RUN J-SIM

Use the following command to start a J-Sim session:

	<java> drcl.ruv.System ?<script>?

Or

	<java> drcl.ruv.System -n ?<script>?

where <java> is the name of the JVM, <script> is the initial script to run with.
With the option "-n", J-Sim terminal output is disabled and the output only
goes to the standard output.

------------------------------------------------------------------------------

5. BATCH RUN

Use the following command to run a script without involving a terminal:

	<java> drcl.ruv.System -ue <script>

The command exits when simulation stops.

------------------------------------------------------------------------------

6. DIRECTORY STRUCTURE IN J-SIM ARCHIVE

This J-Sim package uses the makefile setup described in
"make/Java Makefile.htm".  The setup uses the GnuMake syntax.  As described in
the html file:

	"GnuMake is the default make system on the Linux platform, it is available
	on all UNIX platforms, and a Microsoft Windows version can be downloaded
	from here[http://www.edv.agrar.tu-muenchen.de/~syring/win32/UnxUtils.html]."

The directores are structured as follows:
	src/		source files (*.java, *.gif, *.tcl...)
	classes/	compiled files (*.classes, *.gif, *.tcl...)
	jars/		third-party jar files
	data/		simulation data files such as topology files
	script/		example/testing scripts
	make/		common makefile, make log...

Each sub-directory in ./src corresponds to a Java package.  Each java package
needs a package makefile to be placed in the same directory.
The makefile is basically a list of all the sources files in the package.
Examples can be found in any directory.

------------------------------------------------------------------------------

7. COMPILING SOURCE

- Make:

  make          to compile all newly-modified sources.
  make clean    to remove all compiled files.

  The above commands can also be applied, when in a package directory, to that
  specific package.

  For details of the makefile setup described here, please refer to
  "make/Java_Makefile.htm".

- Apache Ant
  From version 1.2, J-Sim can also be compiled using Apache Ant, the build 
  file is "build.xml".  For details, refer to 
  http://jakarta.apache.org/ant/index.html.

  ant compile   to compile all newly-modified sources.
  ant clean     to remove all compiled files.

------------------------------------------------------------------------------

8. SPONSORS

- NSF
- DARPA/ITO (Quorum and NMS)
- MURI
- Ohio State University
- University of Illinois at Urbana-Champaign

------------------------------------------------------------------------------

9. J-SIM TEAM

Supervisor:
  Jennifer Hou

Current: (in alphabetical order) 
  Wei-peng Chen
  Ye Ge
  Guanghui He
  Hwangnam Kim
  Lu-chan Kung
  Ning Li
  Hyuk Lim
  Ahmed Sobeih
  Hung-ying Tyan
  Honghai Zhang
  Rong Zheng

Past:
  Yuan Gao
  Yifei Hong
  Yung-Ching Hsiao
  Shankar Kalyanaraman
  Wei Lin
  Seok-Bae Park
  Ling Su
  Bin Wang
  Yi Ye
  Jing Zhang

------------------------------------------------------------------------------

10. ACKNOWLEDGEMENT

- Special thanks to Geotechnical Software Services who puts up the document
  (being saved locally as "make/Java Makefile.htm") on the web.

- Thanks to Ling Su for contribution of the Apache Ant build file.
- Thanks to Bruno Quoitin for contribution of code in drcl.inet.InetUtil.

- Thanks to numerous J-Sim users for their valuable feedbacks/suggestions
  that keep J-Sim improved over time.

------------------------------------------------------------------------------

11. COPYRIGHT

Below is the copyright agreement for the J-Sim package.  Additional copyright
notices are included in their directories for packages from third parties. 

-----
Copyright (c) 1998-2004, Distributed Real-time Computing Lab (DRCL) 
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 
3. Neither the name of "DRCL" nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific
   prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

