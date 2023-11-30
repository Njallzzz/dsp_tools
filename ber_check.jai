ProgramState :: struct {
	stdout: HANDLE;
	stdin: HANDLE;

	output_state: Random_State;
	input_state: Random_State;

	args: Arguments;
}

Arguments :: struct {
	seed: u64 = 901283017717; @"?Specify specific seed used for random number generation"
	receiver: bool = false;   @"?Specify if program should only listen"
}

main :: () {
	pstate: ProgramState;

	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);
	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	// Command line argument handling
	success, args, is_set := parse_arguments(Arguments);
	if !success return;

	pstate.args = args;

	random_seed(*pstate.output_state, pstate.args.seed);
	random_seed(*pstate.input_state, pstate.args.seed);

	write_thread: Thread;
	write_thread.data = *pstate;
	thread_init(*write_thread, WriteThreadFunc);
	defer thread_deinit(*write_thread);

	if !pstate.args.receiver
		thread_start(*write_thread);

	// Stdout specific
	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	total_read: u64 = 0;
	total_errors: u64 = 0;

	offset: s64 = 0;
	rand: u64 = random_get(*pstate.input_state);
	cmp_buffer: []u8;

	cmp_buffer.data = xx *rand;
	cmp_buffer.count = size_of(u64);

	while true {
		bytes_read: u32;
		if ReadFile(pstate.stdin, buffer.data, cast(u32) buffer.count, *bytes_read) == 0 {
			print("BER Check ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}

		for 0..bytes_read-1 {
			if offset == size_of(u64) {
				rand = random_get(*pstate.input_state);
				offset = 0;
			}

			if cmp_buffer[offset] != buffer[it] {
				error_count: u32 = 0;
				for byte_iter: 0..7 {
					if (((cmp_buffer[offset] >> byte_iter) & 1) != ((buffer[it] >> byte_iter) & 1)) {
			            error_count = error_count + 1;
			        }
				}

				total_errors += error_count;
				averaged_error: float64 = cast(float64) total_errors / cast(float64) (total_read + (it * 8));
				print("BER Check errors detected, current BER: %, total errors: %\n", averaged_error, total_errors, to_standard_error = true);
			}


			offset = offset + 1;
		}

		total_read += bytes_read * 8;
	}

}

WriteThreadFunc :: (ctx: *Thread) -> s64 {
	pstate: *ProgramState = xx ctx.data;

	buffer: []u8 = NewArray(4096, u8);
	defer free(buffer.data);

	while true {
		for 0..(4096 / size_of(u64))-1 {
			rand := random_get(*pstate.output_state);
			memcpy(buffer.data + (size_of(u64) * it), *rand, size_of(u64));
		}

		bytes_written: u32;
		if WriteFile(pstate.stdout, buffer.data, cast(u32) buffer.count, *bytes_written, null) == 0 {
			print("BER Check WriteFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}
	}

	return 0;
}

#import "Basic";
#import "Windows";
#import "Random";
#import "Thread";
#import "Command_Line";