ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	format: string = "f32";		@"?output format (default f32, options: u8, s16, s32, s64, f32, f64)"
	value: float = 1.0;	@"?value (default 1.0)"
}

main :: () {
	pstate: ProgramState;

	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;

	pstate.args = args;

	if args.format == {
		case "u8";
			multiply_loop(*pstate, u8);
		case "s16";
			multiply_loop(*pstate, s16);
		case "s32";
			multiply_loop(*pstate, s32);
		case "s64";
			multiply_loop(*pstate, s32);
		case "f32";
			multiply_loop(*pstate, float32);
		case "f64";
			multiply_loop(*pstate, float64);
		case;
			print("invalid format!\n", to_standard_error = true);
			return;
	}
}

multiply_loop :: (pstate: *ProgramState, $value_type: Type) {
	buffer: []value_type = NewArray(4096, value_type);
	defer free(buffer.data);

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) (size_of(value_type) * buffer.count), *bytes_read) == 0 {
			print("Multiply ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		num_elements: s64 = bytes_read / size_of(value_type);
		for 0..num_elements-1 {
			buffer[it] = buffer[it] * (xx pstate.args.value);
		}

		bytes_written: u32;
    	if WriteFile(pstate.stdout, buffer.data, bytes_read, *bytes_written, null) == 0 {
    		print("Multiply WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    		continue;
    	}
	}
}

#import "Basic";
#import "Windows";
#import "Command_Line";