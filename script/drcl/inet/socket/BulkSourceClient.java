
import java.net.*;
import java.io.*;
import drcl.comp.*;
import drcl.inet.socket.*;

public class BulkSourceClient extends SocketApplication 
	implements ActiveComponent
{
	int dataUnit = 512;
	long progress; 
	int remoteport;
	long localAddress, remoteAddress;

	public BulkSourceClient()
	{ super(); }

	public BulkSourceClient(String id_)
	{ super(id_); }

	public void reset()
	{
		super.reset();
		progress = 0;
	}

	public void duplicate(Object source_)
	{
		super.duplicate(source_);
		dataUnit = ((BulkSourceClient)source_).dataUnit;
	}
	
	public String info()
	{
		return super.info() + "peer: " + remoteAddress + "/" + remoteport
				+ "\nProgress: " + (progress/dataUnit) + "/" + progress + "\n";
	}

	public void setDataUnit(int dataUnit_)
	{ dataUnit = dataUnit_; }

	public int getDataUnit()
	{ return dataUnit; }
	
	public void bind(long localAddr_, long remoteAddr_, int remotePort_)
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

			while (!isStopped()) {
				os_.write(null, 0, dataUnit);
				progress += dataUnit;
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
