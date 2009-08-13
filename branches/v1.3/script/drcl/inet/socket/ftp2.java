// @(#)ftp2.java   06/2003
// Copyright (c) 1998-2003, Distributed Real-time Computing Lab (DRCL) 
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

import java.util.*;
import java.io.*;
import drcl.data.*;
import drcl.comp.*;
import drcl.net.*;
import drcl.inet.*;
import drcl.inet.socket.*;

/**
 * This component implements a uni-directional file transfer protocol.
 *
 * When transmitting a file, it first sends the size of the file in a
 * 8-byte long integer and then follows the content of the file in 
 * continuous byte stream.
 * 
 * To start a transmission, use {@link #setup setup} to set up the file to be
 * transmitted and the segment size, and then {@link #run run} it.
 */
public class ftp2 extends drcl.inet.socket.SocketApplication
	implements ActiveComponent
{
	int remotePort;
	long localAddress, remoteAddress;

	String remoteFile;
	File file;
	int bufferSize;
	long progress;
	
	public ftp2 ()
	{ super(); }
	
	public ftp2(String id_)
	{ super(id_); }
	
	public void setup(String infile_, int bufferSize_, String remoteFile_)
		   	throws IOException
	{
		bufferSize = bufferSize_;
		file = new File(infile_);
		remoteFile = remoteFile_;
	}

	public void reset()
	{
		progress = 0;
	}
	
	public void duplicate(Object source_)
	{
		super.duplicate(source_);
		bufferSize = ((ftp2)source_).bufferSize;
	}
	
	public void bind(long localAddr_, long remoteAddr_, int remotePort_)
	{
		localAddress = localAddr_;
		remoteAddress = remoteAddr_;
		remotePort = remotePort_;
	}

	protected void _start ()
	{
		if (file == null) {
			error("start()", "no file is set up to send");
			return;
		}
		progress = 0;
		long fileSize_ = file.length();
		
		try	{
			InetSocket socket_ = socketMaster.newSocket();
			socketMaster.bind(socket_, localAddress, 0);
			socketMaster.connect(socket_, remoteAddress, remotePort);
			FileInputStream in_ = new FileInputStream(file);
			DataOutputStream out_ = new DataOutputStream(
							socket_.getOutputStream());
			
			if (isDebugEnabled())
				debug("Start transmitting a file of size " + fileSize_);
			byte[] remoteFileName_ = remoteFile.getBytes();
			out_.writeInt(remoteFileName_.length);
			out_.write(remoteFileName_);
			out_.writeLong(fileSize_);
			byte[] buf_ = new byte[bufferSize];
			
			while (progress <= fileSize_) {
				int nread_ = in_.read(buf_, 0, buf_.length);
				if (nread_ <= 0) break;
				progress += nread_;
				out_.write(buf_, 0, nread_);
			}
			in_.close ();
			out_.close();
			socketMaster.close(socket_);
			if (isDebugEnabled())
				debug("Done with '" + file.getName() + "'");
		}
		catch (IOException ioe) {
			ioe.printStackTrace();
			error("start()", ioe);
		}
	}
	
	public String info()
	{
		StringBuffer sb_ = new StringBuffer(
			super.info() + "peer: " + remoteAddress + "/" + remotePort + "\n");
		if (file == null)
			return sb_.toString() + "No in file is set up.\n";
		else
			return sb_.toString()
				+ "File read: " + file + "\n"
				+ "BufferSize = " + bufferSize + "\n"
				+ "Remote file: " + remoteFile + "\n"
				+ "Progress: " + progress + "/" + file.length() + "\n";
	}
}
