// @(#)TraceRT.java   3/2004
// Copyright (c) 1998-2004, Distributed Real-time Computing Lab (DRCL) 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer. 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution. 
// 3. Neither the name of "DRCL" nor the names of its contributors may be used
//    to endorse or promote products derived from this software without specific
//    prior written permission. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

package drcl.inet;

import java.util.*;
import drcl.comp.*;

/**
 * Component to initiate a trace-route command.
 * Place this component on a CoreServiceLayer and call
 * {@link #traceRoute(long)} to start it. 
 */
public class TraceRT extends Component
{
	Port downPort = addPort("down");
	Port outputPort = addPort("output");

	HashMap hsRequest = new HashMap(); // pending requests

	public TraceRT()
	{ super(); }
	
	public TraceRT(String id_)
	{ super(id_); }

	public void reset()
	{
		super.reset();
		hsRequest.clear();
	}

	/** Initiates a trace-route with trace route packet of size 0.
	 * @see #traceRoute(long, int) */
	public void traceRoute(long destAddress_)
	{ traceRoute(destAddress_, 0); }

	/** Starts a trace-route in a thread and prints result to stdout.
	 * @see #traceRoute(long, int) */
	public void traceRoute(final long destAddress_, final int pktSize_)
	{
		TraceRTPkt p = new TraceRTPkt(TraceRTPkt.RT_REQUEST, destAddress_,
						pktSize_);
		hsRequest.put(p, new Double(getTime()));
		downPort.doSending(p);
	}

	protected void process(Object data_, Port inPort_) 
	{
		if (!(data_ instanceof TraceRTPkt)) {
			debug("Dont know how to handle " + data_);
			return;
		}

		TraceRTPkt p = (TraceRTPkt)data_;
		if (p.getType() != TraceRTPkt.RT_RESPONSE) {
			debug("Dont know how to handle " + data_);
			return;
		}

		Double time_ = (Double)hsRequest.remove(p);
		if (time_ == null) {
			debug("no pending request matches the response: " + p);
			return;
		}

		Object[] hops_ = p.getList();

		if (hops_ == null || hops_.length == 0)
			outputPort.doSending("Error: destination not reachable\n");

	 	// Every two elements in the array represent time (Double) and
		// hop (address + incoming_if) for the corresponding hop
		// along the route.
		StringBuffer sb = new StringBuffer(); 
		for (int i=0; i<hops_.length; i++) {
			sb.append((i/2+1) + ": " + hops_[i+1] + "   "
					+ (((Double)hops_[i]).doubleValue() - time_.doubleValue())
					+ "\n");
			i++;
		}
		outputPort.doSending(sb.toString());
	}

	public String info()
	{
		if (hsRequest.isEmpty())
			return "No pending request.\n";
		else {
			StringBuffer sb = new StringBuffer("Pending Requests:\n");

			for (Iterator it_=hsRequest.keySet().iterator(); it_.hasNext(); ) {
				Object pkt_ = it_.next();
				Object time_ = hsRequest.get(pkt_);
				sb.append("    " + time_ + ": " + pkt_ + "\n");
			}
			return sb.toString();
		}
	}
}
