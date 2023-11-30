ProgramState :: struct {
	args: Arguments;

	stdout: HANDLE;
}

Arguments :: struct {
	bind: string = "127.0.0.1"; @"?IP address of the interface to bind the network interface (default 127.0.0.1)"
	port: string = "4000"; @"?Port of the network interface (default 4000)"
	protocol: string = "udp"; @"?Protocol (tcp/udp, default udp)"
}

main :: () {
	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;

	pstate: ProgramState;
	pstate.args = args;
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);	// Get handle to stdout

	protocol: Socket.IPPROTO;
	if args.protocol == {
		case "tcp";
			protocol = .IPPROTO_TCP;
		case "udp";
			protocol = .IPPROTO_UDP;
		case;
			print("invalid protocol! tcp or udp is valid\n", to_standard_error = true);
			return;
	}

	// Windows specific networking initialization
	assert(Socket.socket_init(), message="Unable to initalize windows networking");
	#if OS == .WINDOWS defer Socket.WSACleanup();

	while true {
		total_received: s64 = 0;

		// Initalize network input
		print("Network Source %:% Protocol %\n", args.bind, args.port, args.protocol, to_standard_error = true);
		failure, socket := Networking.init(args.bind, args.port, protocol);
		if failure {
			print("Unable to initalize networking interface, error %\n", failure, to_standard_error = true);
			return;
		}
		defer Networking.close_handle(socket);

		// Main loop
		buffer: []u8 = NewArray(4096, u8);
		defer free(buffer.data);

		from: Socket.sockaddr;
		fromlen: s32;
		while true {
			buffer.count = 4096;
			fromlen = size_of(Socket.sockaddr);

			buffer.count = Socket.recvfrom(socket, buffer.data, cast(s32) buffer.count, 0, *from, *fromlen);
			if buffer.count <= 0 break;

			total_received += buffer.count;
			//print("Network source: %/%\n", buffer.count, total_received, to_standard_error = true);
			
			total_bytes_written: u32 = 0;
			bytes_written: u32;

			while total_bytes_written < buffer.count {
				if WriteFile(pstate.stdout, buffer.data, cast(u32) buffer.count, *bytes_written, null) == 0 {
					print("Network Source WriteFile error %\n", GetLastError(), to_standard_error = true);
					break;
				}

				total_bytes_written += bytes_written;
			}

			total_received += total_bytes_written;
		}

		print("Closing connection to client\n", to_standard_error = true);
	}
}

#import "Basic";
#import "Windows";
#import "Command_Line";
Math :: #import "Math";
Networking :: #import,file "networking/networking.jai";
Socket :: #import "Socket";