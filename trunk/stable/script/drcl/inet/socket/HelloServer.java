
import java.net.*;
import java.io.*;

// usage:
// HelloServer <port>
public class HelloServer implements Runnable
{
	public static int END = 10;
	static boolean stop = false;

	Socket socket = null;

	public static void main(String[] args_)
	{
		try {
			int localPort_ = Integer.parseInt(args_[0]);
			ServerSocket ss_ = new ServerSocket(localPort_);
			ss_.setSoTimeout(1000); // 1 second
			System.out.println("Server starts at port " + localPort_);

			while (!stop) {
				try {
					Socket s_ = ss_.accept();

					// Note:
					// Real applications can be run in J-Sim emulation
					// without modification.
					// For real applications be be run in simulation, 
					// use drcl.inet.socket.Launcher.newThread() instead of
					// java.lang.Thread for thread creation.

					//new Thread(new HelloServer(s_)).start();
					drcl.inet.socket.Launcher.newThread(new HelloServer(s_));
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

	public static void stop()
	{
		stop = true;
	}

	public HelloServer(Socket s_)
	{
		socket = s_;
	}

	public void run()
	{
		try {
			BufferedReader is_ = new BufferedReader(
				new InputStreamReader(socket.getInputStream()));
			OutputStream os_ = socket.getOutputStream();
			for (int i=0; i<END; i++) {
				os_.write(("Hello" + i + "!\n").getBytes());
				String line_ = is_.readLine();
				System.out.println(socket.getInetAddress() + "/" + socket.getPort() + ":"
					+ line_);
				Thread.currentThread().sleep(100);
			}
			socket.close();
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}
}
