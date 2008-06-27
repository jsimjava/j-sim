
import drcl.comp.*;
import drcl.inet.InetPacket;
import drcl.inet.InetConstants;
import drcl.inet.protocol.dv.*;
import drcl.inet.data.NetAddress;

public class DVFake extends Component
{
	long addr = drcl.net.Address.NULL_ADDR;
	DVPacket dvpkt = new DVPacket(2/*UPDATE*/, 2);
	InetPacket ipkt;

	public DVFake()
	{ super(); }

	public DVFake(String id)
	{ super(id); }

	public void reset()
	{
		super.reset();
		ipkt = null;
	}

	public String info()
	{
		return "Address = " + addr + "\n"
				+ "DVPacket = " + dvpkt + "\n";
	}

	public synchronized void setAddress(long addr_)
	{ addr = addr_; }

	public synchronized void addRTE(long dest_, long mask_, int metric_)
	{
		dvpkt.addRTE(dest_, mask_, drcl.net.Address.NULL_ADDR, metric_);
		if (ipkt != null)
			ipkt.setBody(dvpkt, dvpkt.getNumRTEs()*20+16); // packet size
	}

	protected void process(Object data_, Port inPort_)
	{
		if (!(data_ instanceof InetPacket)) return;

		InetPacket ipkt_ = (InetPacket)data_;
		Object payload_ = ipkt_.getBody();

		if (payload_ instanceof NetAddress) {
			// hello
			NetAddress hello_ = new NetAddress(addr, -1L);
			ipkt_ = drcl.inet.contract.PktSending.getForwardPack(
						hello_, 16, // packet size
						addr, -1, true/*router alert*/,
						1/* TTL */, InetPacket.CONTROL);
			ipkt_.setProtocol(InetConstants.PID_HELLO); // hello protocol
			inPort_.doSending(ipkt_);
		}
		else if (payload_ instanceof DVPacket) {
			// DVPacket
			if (ipkt == null) createInetPacket(ipkt_.getSource());

			// the other end changes protocol ID to interface index all the time
			ipkt.setProtocol(InetConstants.PID_DV); // DV protocol

			inPort_.doSending(ipkt);
		}
	}

	void createInetPacket(long dest_)
	{
		ipkt = drcl.inet.contract.PktSending.getForwardPack(
						dvpkt, dvpkt.getNumRTEs()*20+16, // packet size
						addr, dest_, true/*router alert*/,
						1/* TTL */, InetPacket.CONTROL);
	}
}

