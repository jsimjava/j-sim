
import java.net.*;
import java.io.*;
import drcl.comp.*;
import drcl.inet.socket.SocketMaster;
import drcl.inet.socket.InetSocket;

public class SimpleClient extends drcl.inet.socket.SocketApplication
	implements ActiveComponent
{
	int remoteport;
	long localAddress, remoteAddress;

	public SimpleClient()
	{ super(); }

	public SimpleClient(String id_)
	{ super(id_); }

	public String info()
	{ return "peer: " + remoteAddress + "/" + remoteport
			+ "\n" + super.info(); }

	public void setup(long localAddr_, long remoteAddr_, int remotePort_)
	{
		localAddress = localAddr_;
		remoteAddress = remoteAddr_;
		remoteport = remotePort_;
	}

	protected void _start()
	{
		try {
			InetSocket s_ = socketMaster.newSocket();
			socketMaster.bind(s_, localAddress, 0);
			socketMaster.connect(s_, remoteAddress, remoteport);
			ObjectOutputStream os_ = new ObjectOutputStream(
							s_.getOutputStream());
			os_.writeObject(new int[]{3,5,9,19});

			socketMaster.close(s_);
			System.out.println("End with server: " + s_.getRemoteAddress()
							+ "/" + s_.getRemotePort());
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}
}
