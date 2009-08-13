#
# J-Sim Project Makefile
#

PACKAGES = \
	drcl \
	drcl.comp \
	drcl.comp.contract \
	drcl.comp.io \
	drcl.comp.lib \
	drcl.comp.lib.bytestream \
	drcl.comp.queue \
	drcl.comp.tool \
	drcl.data \
	drcl.util \
	drcl.util.queue \
	drcl.util.random \
	drcl.util.scalar \
	drcl.net \
	drcl.net.tool \
	drcl.net.traffic \
	drcl.net.graph \
	drcl.inet \
	drcl.inet.application \
	drcl.inet.contract \
	drcl.inet.core \
	drcl.inet.core.ni \
	drcl.inet.core.queue \
	drcl.inet.data \
	drcl.inet.mac \
	drcl.inet.protocol \
	drcl.inet.protocol.aodv \
	drcl.inet.protocol.cbt \
	drcl.inet.protocol.dv \
	drcl.inet.protocol.dvmrp \
	drcl.inet.protocol.ospf \
	drcl.inet.sensorsim \
	drcl.inet.socket \
	drcl.inet.tool \
	drcl.inet.transport \
	drcl.diffserv \
	drcl.diffserv.scheduling \
	drcl.intserv \
	drcl.intserv.scheduler \
	drcl.ruv \
	drcl.sim \
	drcl.sim.process \
	drcl.sim.event \


NODOC_PACKAGES = \
#	ptolemy.gui \
#	ptolemy.plot \
#	ptolemy.plot.plotml \
#	tcl.lang 

JARS = \
	. \

JARS_3RDPARTY = \
	tcl.zip \
	jython.jar \

MAIN_CLASS     = System
MAIN_PACKAGE   = drcl.ruv
MAIN_JAR       =


RUN_PARAMETERS = 


#***************************************************************************
#
# Javadoc
#
#***************************************************************************

WINDOWTITLE = 'DRCL J-Sim - API Specification'
DOCTITLE    = 'DRCL J-Sim API'
HEADER      = 'DRCL J-Sim API'
BOTTOM      = '<font size="-1">Copyright &copy; 1998-2003 Distributed Real-time Computing Lab (DRCL).  All Rights Reserved.  &nbsp; &nbsp; <a href="http://www.j-sim.org" target=main><i>~ To J-Sim Home ~</i></a></font>'


include $(J_SIM)/make/Makefile

#***************************************************************************
#
#  (C) 2000 Geotecnical Software Services - GeoSoft
# 
#***************************************************************************
