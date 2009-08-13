
import drcl.comp.*;
import drcl.inet.mac.PositionReportContract;

// convert PositionReportContract.Message to double[]
public class PositionReportConvert extends Component implements ActiveComponent
{
	Port queryPort = addPort("query", false);
	Port outPort = addPort("out", false);
	Port timerPort = addPort(".timer", false);
	static final double PERIOD = 1.0; // second

	protected void _start()
	{
		fork(timerPort, null, PERIOD);
	}

	public void process(Object o, Port in_)
	{
		if (in_ == timerPort) {
			queryPort.doSending("QUERY POSITION");
			fork(timerPort, null, PERIOD);
		}
		else {
			PositionReportContract.Message m =(PositionReportContract.Message)o;
			outPort.doSending(new double[]{m.getX(), m.getY()});
		}
	}
}
