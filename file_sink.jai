ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	file: string = "f32";		@"?input file"
	passthrough: bool = false;  @"?Passthrough input to output"
}

main :: () {
	pstate: ProgramState;

	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;
	pstate.args = args;

	if !is_set.file {
		print("File sink: missing input file!\n");
		return;
	}

	handler, is_open := file_open(args.file, for_writing = true, keep_existing_content = false);
	if !is_open {
		print("File sink: unable to open file: %\n", args.file);
	}
	defer file_close(*handler);

	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	file_ref: string = ---;
	file_ref.data = buffer.data;

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) buffer.count, *bytes_read) == 0 {
			print("Noise ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		file_ref.count = xx bytes_read;
		file_write(*handler, file_ref);

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    		continue;
	    	}
		}
	}
}

#import "Basic";
#import "Windows";
#import "File";
#import "Command_Line";