@echo off
set JAVA_HOME=c:/java
set J_SIM=c:/jsim
set script=%J_SIM%/jars/tcl.zip;%J_SIM%/jars/jython.jar
set classpath=.;%CLASSPATH%;%J_SIM%/classes;%script%
