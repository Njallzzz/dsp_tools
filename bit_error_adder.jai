ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	frequency: s64 = 128;		@"?number of bytes between bit flips (default 1024)"
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

	pstate.args = args;

	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	counter: u64 = 0;
	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) buffer.count, *bytes_read) == 0 {
			print("Multiply ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		byte := random_get() % bytes_read;
		bit := random_get() % 8;
		buffer[byte] ^= cast(u8) (1 << bit);

		bytes_written: u32;
    	if WriteFile(pstate.stdout, buffer.data, bytes_read, *bytes_written, null) == 0 {
    		print("Multiply WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    		continue;
    	}
	}
}

#import "Basic";
#import "Windows";
#import "Random";
#import "Command_Line";