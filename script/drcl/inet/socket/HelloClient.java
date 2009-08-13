
import java.net.*;
import java.io.*;

// Usage:
// HelloClient <host> <port>
public class HelloClient
{
	public static void main(String[] args_)
	{
		try {
			int port_ = Integer.parseInt(args_[1]);
			Socket s_ = new Socket(args_[0], port_);
			BufferedReader is_ = new BufferedReader(
				new InputStreamReader(s_.getInputStream()));
			OutputStream os_ = s_.getOutputStream();

			for (int i=0; i<HelloServer.END; i++) {
				String line_ = is_.readLine();
				System.out.println(s_.getInetAddress() + "/" + s_.getPort() + ":" + line_);

				os_.write(("Hello Back" + i + "!\n").getBytes());
			}
			s_.close();
		}
		catch (Exception e_) {
			e_.printStackTrace();
		}
	}
}
