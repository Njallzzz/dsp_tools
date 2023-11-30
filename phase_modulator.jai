ModulationType :: enum s32 {
	BPSK;
}

ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	args: Arguments;
	modulation: ModulationType;
	sample: s64 = 0;
	inter_symbol_rate: float64;
}

Arguments :: struct {
	sample_rate: float64 = 48000.0;	@"?Sample rate (default 48000.0)"
	symbol_rate: float64 = 3000.0; @"?Symbol rate (default 3000.0)"
	modulation: string = "BPSK"; @"?Modulation scheme (BPSK, default BPSK)"
	frequency: float64 = 3000.0; @"?Frequency offset (default 3000.0)"
}

main :: () {
	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;

	pstate: ProgramState;
	pstate.args = args;

	if args.modulation == {
		case "BPSK";
			pstate.modulation = .BPSK;
		case;
			print("invalid modulation!\n", to_standard_error = true);
			return;
	}

	print("Phase modulator: Sample rate: %, Symbol rate: %, modulation: %, frequency: %\n", pstate.args.sample_rate, pstate.args.symbol_rate,
		pstate.modulation, pstate.args.frequency, to_standard_error = true);

	// Setup Stdout Console
	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);	// Get handle to stdout
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);	// Get handle to stdout

	// Setup internal memory
	buffer_size :: 256;
	pstate.inter_symbol_rate = args.sample_rate / args.symbol_rate;

	data_buffer: []u8 = NewArray(buffer_size, u8);
	defer free(data_buffer.data);

	sample_buffer = xx NewArray(16 * buffer_size * ((cast(s64) pstate.inter_symbol_rate) + 1), float64);
	defer free(sample_buffer.data);

	while true {
		data_buffer.count = buffer_size;

		bytes_read: u32;
		if ReadFile(pstate.stdin, data_buffer.data, cast(u32) data_buffer.count, *bytes_read) == 0 {
			print("Phase Modulator ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		data_buffer.count = bytes_read;
		process_input(data_buffer, *pstate);
	}
}

sample_buffer: []float64;

process_input :: inline (buffer: []u8, state: *ProgramState) -> s32 {
	num_samples: s64 = 8 * buffer.count * (cast(s64) state.inter_symbol_rate);

	symbol_offset: s64 = 0;
	phase: float64 = 0.0;

	if #complete state.modulation == {
		case .BPSK;
			for 0..num_samples-1 {
				sample_offset: float64 = cast(float64) state.sample / state.args.sample_rate;

				if state.sample % cast(s64) state.inter_symbol_rate == 0 {
					if ((buffer[symbol_offset / 8] >> (symbol_offset % 8)) & 0x1) > 0 phase = 180.0; else phase = 0.0;
					symbol_offset = symbol_offset + 1;
				}

				mod_calc := 2.0 * Math.PI64 * state.args.frequency * sample_offset;
				mod_calc += phase;
				
				sample_buffer[it] = Math.sin(mod_calc);

				state.sample += 1;
				if state.sample > cast(s64) state.args.sample_rate state.sample -= cast(s64) state.args.sample_rate;
			}
	}


	bytes_written: u32;
    if WriteFile(state.stdout, sample_buffer.data, cast(u32) (size_of(float64) * num_samples), *bytes_written, null) == 0 {
    	print("Phase Modulator WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    	return -1;
    }
	return 0;
}

#import "Basic";
#import "Windows";
#import "Command_Line";
Math :: #import "Math";