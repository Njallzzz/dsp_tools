ProgramState :: struct {
	args: Arguments;

	stdin: HANDLE;
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
	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);

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
		print("Network Sink %:% Protocol %\n", args.bind, args.port, args.protocol, to_standard_error = true);
		failure, socket := Networking.init(args.bind, args.port, protocol);
		if failure {
			print("Unable to initalize networking interface, error %\n", failure, to_standard_error = true);
			return;
		}
		defer Networking.close_handle(socket);

		// Main loop
		buffer: []u8 = NewArray(4096, u8);
		defer free(buffer.data);

		while true {
			bytes_read: u32;
			if ReadFile(pstate.stdin, buffer.data, cast(u32) buffer.count, *bytes_read) == 0 {
				print("Network Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
				continue;
			}

			//sendto :: (s: SOCKET, buf: *u8, len: s32, flags: MSG, to: *sockaddr, tolen: s32) -> s32;
			Socket.sendto(socket, buffer.data, cast(s32) bytes_read, 0, null, 0);
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