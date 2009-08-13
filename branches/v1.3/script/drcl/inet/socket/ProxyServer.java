
import java.net.*;
import java.io.*;
import drcl.comp.*;
import drcl.inet.socket.*;

/* Redirects all the data from clients to a server. */
public class ProxyServer extends SocketApplication 
	implements ActiveComponent
{
	boolean stop = false;
	int dataUnit = 512;
	long progress; 
	int port;
	long localAddress, remoteAddress;
	InetSocket serverSocket; 
	InetSocket clientSocket; // connect to real server
	OutputStream out; // output to real server
	Port sessionPort = addPort(".session"); //where new session is processed
	
	public ProxyServer()
	{ super(); }

	public ProxyServer(String id_)
	{ super(id_); }

	public void reset()
	{
		super.reset();
		progress = 0;
	}

	public void duplicate(Object source_)
	{
		super.duplicate(source_);
		dataUnit = ((ProxyServer)source_).dataUnit;
	}
	
	public String info()
	{
		return super.info() + "peer: " + remoteAddress + "/" + port
				+ "\nProgress: " + (progress/dataUnit) + "/" + progress + "\n";
	}

	public void setDataUnit(int dataUnit_)
	{ dataUnit = dataUnit_; }

	public int getDataUnit()
	{ return dataUnit; }
	
	public void bind(long localAddr_, long remoteAddr_, int port_)
	{
		localAddress = localAddr_;
		remoteAddress = remoteAddr_;
		port = port_;
	}

	protected void _start()
	{
		try {
			serverSocket = socketMaster.newSocket();
			socketMaster.bind(serverSocket, localAddress, port);
			System.out.println("Servidor de eventos lanzado en el puerto:" +
                                port);
			
			while (!stop) {
				try {
					InetSocket svrSock_ = socketMaster.accept(serverSocket);
					// connect to real server if haven't done so
					if (clientSocket == null){
						clientSocket = socketMaster.newSocket();
						socketMaster.bind(clientSocket, localAddress, 0);
						socketMaster.connect(clientSocket, remoteAddress, 
										port);
						out = clientSocket.getOutputStream();
					} 
					
					if (svrSock_ != null)
						fork(sessionPort, svrSock_, 0.0);
					if (!isMultiSessionEnabled()) break;
				}
				catch (java.io.InterruptedIOException e_)
				{}
			}
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
		if (inPort_ == sessionPort) {
			try {
				InetSocket socket_ = (InetSocket)data_;
				InputStream is_ = socket_.getInputStream();
				System.out.println(this + ": start a session: " + socket_);

				while (!isStopped()) {
					int n_ = is_.read(null, 0, dataUnit);
					lock(this);
					progress += n_;
					out.write(null, 0, n_);
					unlock(this);
				}
				socketMaster.close(socket_);
				System.out.println("End with client: "
								+ socket_.getRemoteAddress()
								+ "/" + socket_.getRemotePort());
			}
			catch (Exception e_) {
				e_.printStackTrace();
			}
		}
		else
			super.process(data_, inPort_);
	}
}
