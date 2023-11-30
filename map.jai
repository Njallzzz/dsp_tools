ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
}

Arguments :: struct {
	in: string = "f64";		@"?output format (default f32, options: u8, s16, s32, s64, f32, f64)"
	out: string = "f32";	@"?output format (default f32, options: u8, s16, s32, s64, f32, f64)"
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

	if args.in == {
		case "u8";
			if args.out == {
				case "u8";
					convert_loop(*pstate, u8, u8);
				case "s16";
					convert_loop(*pstate, u8, s16);
				case "s32";
					convert_loop(*pstate, u8, s32);
				case "s64";
					convert_loop(*pstate, u8, s64);
				case "f32";
					convert_loop(*pstate, u8, float32);
				case "f64";
					convert_loop(*pstate, u8, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case "s16";
			if args.out == {
				case "u8";
					convert_loop(*pstate, s16, u8);
				case "s16";
					convert_loop(*pstate, s16, s16);
				case "s32";
					convert_loop(*pstate, s16, s32);
				case "s64";
					convert_loop(*pstate, s16, s64);
				case "f32";
					convert_loop(*pstate, s16, float32);
				case "f64";
					convert_loop(*pstate, s16, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case "s32";
			if args.out == {
				case "u8";
					convert_loop(*pstate, s32, u8);
				case "s16";
					convert_loop(*pstate, s32, s16);
				case "s32";
					convert_loop(*pstate, s32, s32);
				case "s64";
					convert_loop(*pstate, s32, s64);
				case "f32";
					convert_loop(*pstate, s32, float32);
				case "f64";
					convert_loop(*pstate, s32, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case "s64";
			if args.out == {
				case "u8";
					convert_loop(*pstate, s64, u8);
				case "s16";
					convert_loop(*pstate, s64, s16);
				case "s32";
					convert_loop(*pstate, s64, s32);
				case "s64";
					convert_loop(*pstate, s64, s64);
				case "f32";
					convert_loop(*pstate, s64, float32);
				case "f64";
					convert_loop(*pstate, s64, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case "f32";
			if args.out == {
				case "u8";
					convert_loop(*pstate, float32, u8);
				case "s16";
					convert_loop(*pstate, float32, s16);
				case "s32";
					convert_loop(*pstate, float32, s32);
				case "s64";
					convert_loop(*pstate, float32, s64);
				case "f32";
					convert_loop(*pstate, float32, float32);
				case "f64";
					convert_loop(*pstate, float32, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case "f64";
			if args.out == {
				case "u8";
					convert_loop(*pstate, float64, u8);
				case "s16";
					convert_loop(*pstate, float64, s16);
				case "s32";
					convert_loop(*pstate, float64, s32);
				case "s64";
					convert_loop(*pstate, float64, s64);
				case "f32";
					convert_loop(*pstate, float64, float32);
				case "f64";
					convert_loop(*pstate, float64, float64);
				case;
					print("invalid output format!\n", to_standard_error = true);
			}
		case;
			print("invalid input format!\n", to_standard_error = true);
	}
}

convert_loop :: (pstate: *ProgramState, $in: Type, $out: Type)
#modify {
    return in != out;
}{
	buffer_in: []in = NewArray(4096, in);
	defer free(buffer_in.data);
	buffer_out: []out = NewArray(4096, out);
	defer free(buffer_out.data);

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer_in.data, cast(u32) (size_of(in) * buffer_in.count), *bytes_read) == 0 {
			print("Map ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		num_elements: s64 = bytes_read / size_of(in);
		for 0..num_elements-1 {
			buffer_out[it] = xx buffer_in[it];
		}

		bytes_written: u32;
    	if WriteFile(pstate.stdout, buffer_out.data, cast(u32) (size_of(out) * num_elements), *bytes_written, null) == 0 {
    		print("Map WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    		continue;
    	}
	}
}

convert_loop :: (pstate: *ProgramState, $in: Type, $out: Type)
#modify {
    return in == out;
}{
	buffer: []in = NewArray(4096, in);
	defer free(buffer.data);

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) (size_of(in) * buffer.count), *bytes_read) == 0 {
			print("Map ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		bytes_written: u32;
    	if WriteFile(pstate.stdout, buffer.data, bytes_read, *bytes_written, null) == 0 {
    		print("Map WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    		continue;
    	}
	}
}

#import "Basic";
#import "Windows";
#import "Random";
#import "Command_Line";