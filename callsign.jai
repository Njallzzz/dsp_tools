ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	callsign: string;	@"?Callsign"
	repeat: u64 = 4096; @"?Repeat callsign after this many bytes transmitted (default 4096)"
}

main :: () {
	pstate: ProgramState;

	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success {
		print("Unable to process command line arguments\n", to_standard_error = true);
		return;
	}

	if !is_set.callsign {
		print("Callsign: missing callsign parameter!\n", to_standard_error = true);
		return;
	}

	pstate.args = args;

	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	bytes_since_last_tx: u64 = 0;
	premade_callsign_string: string = sprint(" % ", pstate.args.callsign);

	// First transmitt callsign
	bytes_written: u32 = 0;
	WriteFile(pstate.stdout, premade_callsign_string.data + 1, cast(u32) premade_callsign_string.count - 1, *bytes_written, null);

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) buffer.count, *bytes_read) == 0 {
			print("Callsign ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		written: u32 = 0;
		while bytes_since_last_tx + bytes_read - written > pstate.args.repeat {
			bytes_written = 0;
			if WriteFile(pstate.stdout, buffer.data, cast(u32) (pstate.args.repeat - bytes_since_last_tx), *bytes_written, null) == 0 {
				print("Callsign WriteFile Error: %\n", GetLastError(), to_standard_error = true);
				continue;
			}
			written += bytes_written;
			bytes_since_last_tx += bytes_written;

			bytes_written = 0;
			if WriteFile(pstate.stdout, premade_callsign_string.data, cast(u32) premade_callsign_string.count, *bytes_written, null) == 0 {
				print("Callsign WriteFile Error: %\n", GetLastError(), to_standard_error = true);
				continue;
			}
			bytes_since_last_tx = 0;
		}

		bytes_written = 0;
		if WriteFile(pstate.stdout, buffer.data + written, cast(u32) bytes_read - written, *bytes_written, null) == 0 {
			print("Callsign WriteFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}
		bytes_since_last_tx += bytes_written;
	}
}

#import "Basic";
#import "Windows";
#import "Math";
#import "Command_Line";