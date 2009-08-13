
import java.net.*;
import java.io.*;
import java.util.Vector;
import java.util.HashMap;
import drcl.comp.*;
import drcl.util.queue.FIFOQueue;
import drcl.inet.socket.*;

public class ftpd2 extends drcl.inet.socket.SocketApplication
	implements ActiveComponent
{
	public static int END = 3;

	boolean stop = false;
	long localAddress;
	int localPort = 0;
	Port sessionPort = addPort(".session"); //where new session is processed
	Port stopPort = addPort(".stop"); //to stop a session

	int bufferSize;
	HashMap mapRecord = new HashMap(); // InetSocket --> Record

	class Record {
		File file;
		long progress, fileSize;
		public String toString()
		{
			return "file:" + file + "," + progress + "/" + fileSize;
		}
	}
	
	public ftpd2()
	{ super(); }

	public ftpd2(String id_)
	{ super(id_); }

	public void reset()
	{
		super.reset();
		stop = false;
		mapRecord.clear();
	}

	public String info()
	{
		StringBuffer sb_ = new StringBuffer(
						super.info() + "local port = " + localPort
					   	+ "\nstopped: " + stop + "\n");
		return sb_.toString() + mapRecord + "\n";
	}

	public void setup(int bufferSize_)
	{
		bufferSize = bufferSize_;
	}

	public void bind(int localAddress_, int localPort_)
	{
		localAddress = localAddress_;
		localPort = localPort_;
	}

	InetSocket serverSocket;
	Vector vSockets = new Vector();

	protected void _start()
	{
		try {
			serverSocket = socketMaster.newSocket();
			socketMaster.bind(serverSocket, localAddress, localPort);

			System.out.println("Server starts at port " + localPort);

			while (!stop) {
				try {
					InetSocket s_ = socketMaster.accept(serverSocket);
					if (s_ != null) fork(sessionPort, s_, 0.0);
					if (!isMultiSessionEnabled()) break;
				}
				catch (java.io.InterruptedIOException e_)
				{}
			}
			System.out.println("Server stops.");
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}

	protected void _stop()
	{
		stop = true;
		try {
			socketMaster.close(serverSocket);
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}

	protected void process(Object data_, Port inPort_)
	{
		if (inPort_ == stopPort) {
			if (data_ == null) {
				// stop all sessions
				FIFOQueue qTasks_ = new FIFOQueue();
				synchronized (vSockets) {
					for (int i=0; i<vSockets.size(); i++)
						qTasks_.enqueue(vSockets.elementAt(i));
				}

				while (!qTasks_.isEmpty())
					fork(stopPort, qTasks_.dequeue(), 0.0);
				return;
			}
			else {
				try {
					socketMaster.close((InetSocket)data_);
				} 
				catch (Exception e_) {
					e_.printStackTrace();
				}
			}
		}
		else if (inPort_ == sessionPort) {
			try {
				InetSocket socket_ = (InetSocket)data_;
				synchronized (vSockets) {
					vSockets.addElement(socket_);
				}

				Record r = new Record();
				mapRecord.put(socket_, r);

				r.progress = 0;
				byte[] buf_ = new byte[bufferSize];
				try	{
					DataInputStream in_ = new DataInputStream(
									socket_.getInputStream());
			
					byte[] fileNameArray_ = new byte[in_.readInt()];
					in_.read(fileNameArray_);
					r.file = new File(new String(fileNameArray_));
					FileOutputStream out_ = new FileOutputStream(r.file);
					r.fileSize = in_.readLong();
					if (isDebugEnabled())
						debug("Start receiving file: " + r.file.getName()
									   	+ " with size " + r.fileSize);

					while (r.progress < r.fileSize) {
						int len_ = in_.read(buf_, 0, -1);
							// -1: read whatever available in the buffer
						if (len_ > 0) out_.write(buf_, 0, len_);
						r.progress += len_;
					}
					out_.close();
					socketMaster.close(socket_);
					if (isDebugEnabled())
						debug("Done with '" + r.file.getName() + "'");
				}
				catch (IOException ioe)	{
					ioe.printStackTrace();
					error("_start()", ioe);
				}
			}
			catch (Exception e_) {
				e_.printStackTrace();
			}
		}
		else
			super.process(data_, inPort_);
	}

	public void stopAllSessions()
	{
		fork(stopPort, null, 0.0);
	}
}
