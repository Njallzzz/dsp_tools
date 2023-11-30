init :: (hostname: string, service_name: string, protocol: IPPROTO) -> s32, SOCKET {
	retval: s32;
	server_socket: SOCKET;
	hints: addrinfo;
	hints.ai_family = AF_UNSPEC;
    hints.ai_flags = .AI_PASSIVE | .AI_CANONNAME;
    if protocol == .IPPROTO_TCP {
	    hints.ai_socktype = .SOCK_STREAM;
	    hints.ai_protocol = protocol;
	} else if protocol == .IPPROTO_UDP {
	    hints.ai_socktype = .SOCK_DGRAM;
	    hints.ai_protocol = protocol;
	}

    result: *addrinfo = null;
	retval = getaddrinfo(hostname.data, service_name.data, *hints, *result);
	if retval != 0 return retval, INVALID_SOCKET;

	retval, server_socket = process_getaddrinfo(result);
	if retval != 0 return retval, INVALID_SOCKET;

	return 0, server_socket;
}

close_handle :: inline (socket: SOCKET) {
	shutdown(socket, 3);
	closesocket(socket);
}

request_client :: (server_socket: SOCKET) -> s32, SOCKET {
	client: SOCKET = accept(server_socket, null, null);
	if client == INVALID_SOCKET {
		error := get_last_socket_error();
		return cast(s32) error, INVALID_SOCKET;
	}
	return 0, client;
}

init_server :: (addr: *addrinfo) -> s32, SOCKET {
	result: s32;
	sock: SOCKET;

	sock = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol);
	if sock == INVALID_SOCKET {
		error := get_last_socket_error();
		return cast(s32) error, INVALID_SOCKET;
	}

	result = bind(sock, cast(*sockaddr)addr.ai_addr, cast(s32) addr.ai_addrlen);
	if result == SOCKET_ERROR {
		error := get_last_socket_error();
		closesocket(sock);
		return cast(s32) error, INVALID_SOCKET;
	}

	if addr.ai_socktype == .SOCK_STREAM {
		result = listen(sock, SOMAXCONN);
		if result == SOCKET_ERROR {
			error := get_last_socket_error();
			closesocket(sock);
			return cast(s32) error, INVALID_SOCKET;
		}

		client := accept(sock);
		close_handle(sock);
		sock = client;
	}

	return 0, sock;
}

process_getaddrinfo :: (result: *addrinfo) -> s32, SOCKET {
	retval: s32 = -1;
	sock: SOCKET;
	ptr: *addrinfo = result;
	defer freeaddrinfo(result);

	while ptr != null {
		retval, sock = init_server(ptr);
		if retval == 0 return retval, sock;

		ptr = ptr.ai_next;
	}

	return retval, INVALID_SOCKET;
}

#scope_module

#import "Basic";
#import "Socket";
System :: #import "System";