J-Sim v1.3 patch 4

The 4th patch over J-Sim v1.3.

To apply it, unpack the package directly onto where J-Sim v1.3 is installed.
Prompt "yes" to any file overrides.  And then recompile the sources.

July 2006
The J-Sim Team

===============================================================================
Change Log

patch1.3-4: 07/05/2006

- drcl.inet.socket.TCP_socket:
  - add resetAppSendClose() to notify of the event exactly once
- drcl.inet.socket.InetSocket: added _accept() and _aAcceptFinished() to be
  invoked by SocketMaster to avoid a race condition where TCP might start send
  stuff before SocketMaster associates socket with data port with
  htSockets.put(p, s); SocketMaster is modified accordingly
- drcl.inet.transport.TCP: implements getSeqNo() to return snd_nxt
- drcl.inet.transport.TCPSink: add getSeqNo() for subclass extension; in 
  addition, all TCP headers are added getSeqNo() upon creation
- drcl.inet.transport.TCPb:
  - implements getSeqNo() in TCPSink subclass, it returns TCPb.this.snd_nxt
  - dataArrivesAtDownPort(): invoke TCPSink.recv() when payload exists, not
    when seqno >= 0
- drcl.inet.socket.TCP_socket:
  - should check if the ACK is the expected one (ack no == seq no)
  - synchronized closeBottomHalf() to avoid a racing condition where FIN is
    sent out and ack comes back before the method goes to wait()
  - when reallyEstablished, should notifyAll() instead of just notify() as
    there may be more than one thread waiting
- drcl.net.graph.TopologyReaderAlt.parse(): Pattern.compile() needs to add 
  square parentheses just like regular expression; add code to deal with
  exceptions when not enough lines (for nodes or edges) are supplied
- drcl.inet.application.BulkSource: revised javadoc of setDataUnit(); it was
  misleading
- drcl.comp.Component.exposePort(...): use connectTo() instead of connect()
- fixed a bug in drcl.util.queue.VSFIFOQueue.dequeue(key) (Bjornar Libaek)
- make "info script" work for the first script specified on the command line:
  - drcl.ruv.Shell: removed "final" from evalFile()
  - tcl.lang.Hook: added setScriptFile() and addScriptFile()
  - drcl.ruv.ShellTcl: added evalFile() to set up for "info script" through Hook
- drcl.inet.application.FSPMessage: made it implement drcl.ObjectCloneable
  instead of extending drcl.DrclObj and added clone()
- add SetDefaultID
  - drcl.inet.contract.IDConfig: add new "SetDefault" message
  - drcl.inet.InetConstants: add new DEFAULT_IDENTITY_SET/UNSET event names
  - drcl.inet.core.Identity: revised to respond to new SetDefault message and
    to eject default identity set/unset events when appropriate
- drcl.comp.ARuntime.off(): the method was not synchronized! (Psoroulas Giannis)
- drcl.comp.queue.ActiveQueue.process(): handling of IntObj was not reachable
  (Louis Hugues)
- drcl.comp.tool.Plotter: added drawLine(); but this introduces conflict with
  previous output format where we assumed points are all connected;
  in addition, this cannot be invoked through ports yet
  (** TO BE FIXED **)
- drcl.inet.InetUtil.createTraffic()'s: remove the check for
  TrafficSourceComponent when calling setPacketWrapper(); NOT TESTED YET
- drcl.comp.ARuntime
  - _startAll(): add code at the end to deal with the situation where system
    is inactive and a new task is being added which triggers wakeupThread to
    handle the task; the original code did not change the system state to
    running
  - added more state information in wakeupThread
- drcl.inet.contract.DatagramContract.Message.wraps(): need to update pktsize
- drcl.inet.protocol.aodv.AODV:
  - added routePurgeEnabled to enable/disable route purge operation
  - modified not to have RT purge route again since AODV does it by itself
  - process(): added code to drop packet if the component has not started yet;
    this prevents AODV from going into wrong state before starting if nodes are
    booted up at different times
- added script/drcl/inet/wireless/mobility/ for testing mobility model
- drcl.inet.InetUtil:
  - added createNodes()'s with option of assigning node address
  - getPID(): added PID_AODV, PID_TRACE_RT
- drcl.inet.core.CSLBuilder.build(): set global queue properties only if q_
  is DEFAULT_QUEUE
- drcl.inet.data.InterfaceInfo: made it implement drcl.ObjectCloneable instead
  of extending drcl.DrclObj; included mtu,bw,bufferSize in clone()
- drcl.inet.core.CoreServiceLayer: added fillInterfaceInfo() to convey the
  information of MTU, interface bandwidth and buffer size to InterfaceInfo
  stored in hello
- drcl.inet.protocol.ospf.OSPF:
  - dataArriveAtDownPort(): added interface info in the error output
  - added refreshAll() to allow initiating a LSA refresh manually
- drcl.inet.protocol.ospf.OSPF_QoS:
  - fixed a bug in info() where a constant 14 was hard coded for array size;
    added info from super.info() as well
  - changed bw2metric() and metric2bw() to static for testing purpose
- drcl.inet.protocol.ospf.Router_LSA_Link: replaced tos_no, tos_list,
  tos_metric_list with tos_metric_map (HashMap)
- drcl.inet.core: moved link emulation out of NI and created NI_LinkEmulation
  - affected classes modified accordingly: CoreServiceLayer, CSLBuilder,
    QueueNI, ni/PointopointNI
- drcl.inet.InetUtil.createTopology(): modified to detect all (asymmetric
  connection) errors in adjMatrix_
- drcl.ruv.Dterm/DtermAWT,drcl.net.graph.TopologyVisRelaxer,drcl.comp.lib.Talk,
  drcl.comp.tool.Plotter/HistogramPlotter/ComponentTester: replaced show()
  with setVisible(true) for Window/JFrame
- drcl.comp.WorkerThread.getState(): renamed to _getState() due to conflict to
  java.lang.Thread.getState() added since v1.5.0
- drcl.inet: added InetPacketInterface and made InetPacket,
  drcl.inet.mac.LLPacket implement it
  - drcl.inet.core.queue.PriorityQueue: modified to use InetPacketInterface
    instead of InetPacket directly
- drcl.inet.core.Queue: javadoc revised (removed the wording saying that
  byte mode is the only acceptable mode)
- drcl.inet.core.queue.PriorityQueue/PreemptPriorityQueue:
  - removed drop_front option to reduce complexity; code revised accordingly
  - added instant queue length output
- drcl.inet.core.queue.PriorityQueue
  - fixed a bug in lastElement(), should decrement the loop variable
  - added info(String, boolean) for checking content in the queue
  - duplicate(): fixed a bug caused by null that_.qq; forgot to duplicate
    "capacity"
- drcl.data.RadixMap: fixed a bug in rn_insert() where mask list was not passed
  to parent node; bug appears when a leaf node with mask < -1 branches out
  on left and a longest match searches through the right branch and back tracks
  to the new parent node; example: add (0,8,0)(0,-8,0) and (0,13,0)(0,-1,0) and
  find longest match for (0,12,0);
  rn_delete_radix_mask() and rn_new_radix_mask() are modified accordingly
- drcl.inet.protocol.dv.DV._updateNeighbors(): added a special check for
  default route; default route can only be distributed within the same domain
- drcl.ruv.TclGateway: add code to start drcl.ruv.System if not yet done so;
  must do so to put Shell under ruv so that Shell is equipped with runtime;
  otherwise, Shell.print()-->Shell.doSending()-->NullPointerException
- drcl.ruv.Dterm.init(): add synchronization to avoid deadlock between
  new JFrame() and new JFileChooser()
- drcl.net.traffic.TrafficSourceComponent
  - send(): one of the two places to clone enclosingPacket was not revised
    accordingly when the code was revised to implement PacketWrapper
  - reset(): cancel timer if the timer exists
- drcl.net.traffic.tsPoisson: setPacketSize(), setRate() and set() added code
  to reschedule packets if the component already started
- drcl.ruv.drcl.tcl: have "grep" also use java.util.regex

===============================================================================

patch1.3-3: 5/14/2004

- drcl.comp.lib.bytestream.ByteStreamPeer: added sendWait(), recvWait(), 
  sendNotify() and recvNotify() for subclassing for non-simulation thread
- revised code for running real application in simulation threads
  - drcl.inet.socket.Launcher:
    - added static Thread newThread(Runnable)
    - added MyRunnable and started application in MyRunnable in simulation
      thread
  - drcl.inet.socket.JSimSocketImpl: added MyByteStreamPeer to handle
    non-simulation thread
  - drcl.comp.Task: added a new field "threadGroup"
  - drcl.comp.TaskSpecial: added a constructor to accept ThreadGroup as argument
  - drcl.comp.TaskNotify: added a static MARK and assign this to every
    instance's threadGroup; this way simulation thread's code of telling
    special tasks becomes simple: just test if Task's threadGroup != null
  - drcl.comp.ACARuntime: added a new addRunnableAt() to accept ThreadGroup as
    argument
  - drcl.comp.ARuntime:
    - newThread() added ThreadGroup as argument
    - added grabOne(ThreadGroup) and immediatelyStart(Task)
  - drcl.comp.AWorkerThread: clean up run() and added code to handle task
    whose threadGroup is not thread's
  - drcl.sim.event.SESimulator:
    - newThread() added ThreadGroup as argument
    - added grabOne(ThreadGroup) and immediatelyStart(Task)
  - drcl.sim.event.SEThread: clean up run() and added code to handle task
    whose threadGroup is not thread's
  - script/drcl/inet/socket/HelloServer.java:
    use drcl.inet.socket.Launcher.newThread() instead of java.lang.Thread
- drcl.inet.contract.DatagramContract
  - add code to implement drcl.net.PacketWrapper and drcl.data.Countable
- updated script/drcl/inet/dvmrp/test_igmp.trace and 
  script/drcl/inet/queue/*.trace
- drcl.inet.mac:
  - NodePositionTracker, MobilityModel: added info()
  - WirelessPhy: added setBandwidth() and more debug info to the case of
    negative gap time
  - NodeChannelContract, MacPhyContract: made Message implement
    drcl.data.Countable so that raw bit rate can be collected by TrafficMonitor
- drcl.inet.protocol.dv.DV:
  - _updateNeighbors(): relax the condition on checking route entry to be
    distributed by DV
  - _routingUpdateHandler(): make it more strict the condition on checking
    route entry to be handled by DV (only those created by DV can be handled
    by DV later)
- fix a bug in drcl.inet.transport.TCPSink.recv(): may receive a packet whose
  seq_ is smaller than rcv_nxt but it contains new bytes due to retransmission
  of several small messages in one segment and some of the messages have been
  received before
- fix a bug in drcl.comp.lib.bytestream.ByteStreamPeer.handle():
  pendingReceive.buffer may be null if caller specifies a null byte array to
  receive
- Classes are revised to be compatible with J2SDK1.5
  - drcl.comp.ARuntime
  - drcl.comp.ForkManagerLocal
  - drcl.comp.tool.ComponentTester
  - drcl.comp.tool.HistogramPlotter
  - drcl.comp.tool.Plotter
  - drcl.inet.tool.routing_msp
  - drcl.net.graph.ShortestPathTree
  - drcl.net.traffic.tsCDSmooth
  - drcl.sim.event.SESimulator
  - drcl.intserv.Scheduler
  - drcl.intserv.scheduler.admission_PTSP
  - drcl.intserv.scheduler.admission_DCTS
  - drcl.intserv.scheduler.scheduler_SP
- drcl.ruv.Dterm: added minimize() and restore()
- drcl.comp.tool.Plotter: added hide()/hideAll()
- drcl.net.traffic
  - TrafficSourceComponent.info(): add birthTime printout
  - tsPacketTrain.info(String): add prefix_ in printout
- drcl.inet.mac.WirelessPhy: added getEnergyModel()
- drcl.net.traffic.ts*: all TrafficSourceComponent's added reschedule()
  to allow the parameters of a traffic source to be changed online and the
  next packet (pakcet that has been scheduled) to be rescheduled accordingly
- drcl.data: added XYDataInterface; made XYData implement it
- drcl.comp.tool: made Plotter and PlotPlan deal with XYDataInterface
- drcl.inet.socket.TCP_socket: add code to do exponential backoff for SYN
  retransmissions

===============================================================================

patch1.3-2: 3/16/2004
- drcl.inet.NodeBuilder.loadmap(): add back code to deal with the option of
  using default "up" port by specifying "-" as port ID in the node map
- drcl.comp.lib.bytestream:
  - ByteStreamContract: added "STOP" command; also in ByteStreamConstants
  - ByteStreamPeer:
    - interrupt sending when STOP command is received
    - added DONT_THROW_EXCEPTION
    - enclose IO exception thrown in another IO exception as cause to better
      locate where these exceptions occur. 
- drcl.inet.transport.TCP:
  - move state check from snd_packet() to timeout()
  - according to RFC2988
    - rtxcur_init: changed from 6.0 to 3.0
    - smallest rto (in rxt_timer()): changed from 2*t_grain to 1.0 second
  - added set/getMaxRetransmissionsAllowed(): when max is reached, TCP sends
    a STOP command 0 or negative for unlimited retrans.
- drcl.ruv:
  - Term: added set/getMaxNumberOfLines() for max # of lines that can be
    buffered in the terminal; default is 500 lines
  - Dterm: made conform to the maxNumberOfLines property

===============================================================================

patch1.3-1: 3/5/2004
- drcl.comp.lib.bytestream.ByteStreamPeer: added
  getCurrentReceiveBufferOccupancy()
- drcl.inet.socket:
  - added SocketListener to be notified of byte stream receiving events
  - InetSocket: added registerListener()
  - SocketMaster: added code for SocketListener callback
- drcl.inet.InetUtil:
  - added connectNeighbors()
  - added traceRoute/traceRouteInObj(Node, Node, long) to allow route tracing
    to nodes with multiple addresses
- drcl.inet.NodeBuilder.loadmap(): allow application to be connected to
  an arbitrary (non-number) up port of the transport
- drcl.comp.Port._getPeers(): should include ancestor ports
- drcl.inet.TraceRT:
  - remove synchronized call and add code to output result through output@
    port (asynchronously)
  - bookkeep pending requests in order to calculate pkt traversal time
- drcl.inet.Node.traceRoute(): revised accordingly
- drcl.inet.TraceRTPkt: add incomingIf to addHop()
- drcl.inet.core.PktDispatcher:
  - add incomingIf to TraceRTPkt
  - for TraceRTPkt, use the destination field as the source when sending back
    response instead of the default node address


