
import java.net.*;
import java.io.*;
import java.util.Vector;
import drcl.comp.*;
import drcl.util.queue.FIFOQueue;
import drcl.inet.socket.*;

public class ftpd extends drcl.inet.socket.SocketApplication
	implements ActiveComponent
{
	public static int END = 3;

	boolean stop = false;
	long localAddress;
	int localPort = 0;
	Port sessionPort = addPort(".session"); //where new session is processed
	Port stopPort = addPort(".stop"); //to stop a session

	File file;
	int bufferSize;
	long progress, fileSize;
	
	public ftpd()
	{ super(); }

	public ftpd(String id_)
	{ super(id_); }

	public void reset()
	{
		super.reset();
		stop = false;
	}

	public String info()
	{
		return super.info() + "local port = " + localPort
			+ "\nstopped: " + stop + "\n";
	}

	public void setup(String outfile_, int bufferSize_) throws IOException
	{
		bufferSize = bufferSize_;
		file = new File(outfile_);
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

				progress = 0;
				byte[] buf_ = new byte[bufferSize];
				try	{
					FileOutputStream out_ = new FileOutputStream(file);
					DataInputStream in_ = new DataInputStream(
									socket_.getInputStream());
			
					fileSize = in_.readLong();
					if (isDebugEnabled())
						debug("Start receiving file size " + fileSize);

					while (progress < fileSize) {
						int len_ = in_.read(buf_, 0, -1);
							// -1: read whatever available in the buffer
						if (len_ > 0) out_.write(buf_, 0, len_);
						progress += len_;
					}
					out_.close();
					socketMaster.close(socket_);
					if (isDebugEnabled())
						debug("Done with '" + file.getName() + "'");
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
