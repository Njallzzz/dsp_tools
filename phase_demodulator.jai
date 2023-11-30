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

	sample_buffer: []float64;
	data_buffer: []u8;
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

	print("Phase demodulator: Sample rate: %, Symbol rate: %, modulation: %, frequency: %\n", pstate.args.sample_rate, pstate.args.symbol_rate,
		pstate.modulation, pstate.args.frequency, to_standard_error = true);

	// Setup Stdout Console
	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);	// Get handle to stdout
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);	// Get handle to stdout

	// Setup internal memory
	buffer_size :: 4096;
	pstate.inter_symbol_rate = args.sample_rate / args.symbol_rate;

	pstate.sample_buffer = xx NewArray(buffer_size, float64);
	defer free(pstate.sample_buffer.data);

	pstate.data_buffer = xx NewArray(buffer_size, u8);
	defer free(pstate.data_buffer.data);

	while true {
		pstate.sample_buffer.count = buffer_size;

		bytes_read: u32;
		if ReadFile(pstate.stdin, pstate.sample_buffer.data, cast(u32) pstate.sample_buffer.count, *bytes_read) == 0 {
			print("Phase Demodulator ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		pstate.sample_buffer.count = bytes_read;
		process_input(*pstate);
	}
}

process_input :: inline (pstate: *ProgramState) -> s32 {
	for 0..pstate.sample_buffer.count-1 {
		/*sample_offset: float64 = cast(float64) state.sample / state.args.sample_rate;

		if state.sample % cast(s64) state.inter_symbol_rate == 0 {
			if ((buffer[symbol_offset / 8] >> (symbol_offset % 8)) & 0x1) > 0 phase = 180.0; else phase = 0.0;
			symbol_offset = symbol_offset + 1;
		}

		mod_calc := 2.0 * Math.PI64 * state.args.frequency * sample_offset;
		mod_calc += phase;
		
		sample_buffer[it] = Math.sin(mod_calc);

		state.sample += 1;
		if state.sample > cast(s64) state.args.sample_rate state.sample -= cast(s64) state.args.sample_rate;*/


	}

	bytes_read: u32 = 0;

	bytes_written: u32;
    if WriteFile(pstate.stdout, pstate.data_buffer.data, cast(u32) bytes_read, *bytes_written, null) == 0 {
    	print("Phase Modulator WriteFile Error: %\n", GetLastError(), to_standard_error = true);
    	return -1;
    }
	return 0;
}

#import "Basic";
#import "Windows";
#import "Command_Line";
Math :: #import "Math";