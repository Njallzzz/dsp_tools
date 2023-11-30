ProgramState :: struct {
	stdout: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	file: string = "f32";		@"?input file"
}

main :: () {
	pstate: ProgramState;

	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;
	pstate.args = args;

	if !is_set.file {
		print("File source: missing input file!\n");
		return;
	}

	handler, is_open := map_file(args.file);
	if !is_open {
		print("File source: unable to open file: %\n", args.file);
		return;
	}
	defer munmap_file(*handler);

	bytes_written: u32;
	if WriteFile(pstate.stdout, handler.data.data, xx handler.data.count, *bytes_written, null) == 0 {
		print("File Source WriteFile Error: %\n", GetLastError(), to_standard_error = true);
		return;
	}
}

#import "Basic";
#import "Windows";
#import "File";
#import "Command_Line";