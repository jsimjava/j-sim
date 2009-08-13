
import java.net.*;
import java.io.*;
import drcl.comp.*;
import drcl.inet.socket.SocketMaster;
import drcl.inet.socket.InetSocket;

public class HelloClient2 extends drcl.inet.socket.SocketApplication
	implements ActiveComponent
{
	int remoteport;
	long localAddress, remoteAddress;

	public HelloClient2()
	{ super(); }

	public HelloClient2(String id_)
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
			BufferedReader is_ = new BufferedReader(
				new InputStreamReader(s_.getInputStream()));
			OutputStream os_ = s_.getOutputStream();

			for (int i=0; i<HelloServer2.END; i++) {
				String line_ = is_.readLine();
				System.out.println(line_ + " from " + s_.getRemoteAddress()
								+ "/" + s_.getRemotePort());

				// uncomment the following line blocks the thread at the server
				//   from receiving the last line of messages, used to test
				//   cancelling blocked receiving
				//if (i < HelloServer2.END-1)
				os_.write(("Hello Back" + i + "!\n").getBytes());
			}
			socketMaster.close(s_);
			System.out.println("End with server: " + s_.getRemoteAddress()
							+ "/" + s_.getRemotePort());
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}
}
