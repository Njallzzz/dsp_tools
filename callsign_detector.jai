ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	callsign: string;		@"?Callsign"
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
		print("Callsign detector: missing callsign parameter!\n", to_standard_error = true);
		return;
	}

	pstate.args = args;

	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	bytes_since_last_tx: u64 = 0;
	premade_callsign_string: string = sprint("% ", pstate.args.callsign);

	callsign_without_spaces: string = ---;
	callsign_without_spaces.data = premade_callsign_string.data;
	callsign_without_spaces.count = premade_callsign_string.count - 1;

	matched: s64 = 0;
	buffer_offset: s64 = 0;
	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data + buffer_offset, cast(u32) (buffer.count - buffer_offset), *bytes_read) == 0 {
			print("Callsign ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		for 0..bytes_read-1 {
			while bytes_read > it + matched && premade_callsign_string.count > matched && buffer[it + matched] == premade_callsign_string[matched] {
				matched = matched + 1;
				//print("%\n", matched, to_standard_error = true);
			}

			if matched == premade_callsign_string.count {
				print("Callsign detected: %\n", callsign_without_spaces, to_standard_error = true);

				if it == 0 {
					memcpy(buffer.data + it, buffer.data + it + matched, bytes_read - it - matched);
				} else {
					memcpy(buffer.data + it - 1, buffer.data + it + matched, bytes_read - it - matched);
					bytes_read -= 1;
				}
				bytes_read -= xx matched;
				matched = 0;
			}
		}

		if matched > 0 {
			bytes_read -= cast(u32) (matched - 1);
			buffer_offset = matched - 1;
		} else 
			buffer_offset = 0;

		if bytes_read <= 0 continue;

		bytes_written: u32;
		if WriteFile(pstate.stdout, buffer.data, cast(u32) bytes_read, *bytes_written, null) == 0 {
			print("Callsign WriteFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}
	}
}

#import "Basic";
#import "Windows";
#import "Math";
#import "Command_Line";