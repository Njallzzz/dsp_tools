main :: () {
	stdin := GetStdHandle(STD_INPUT_HANDLE);	// Get handle to stdout

	buffer_size :: 4096;
	data_buffer: []u8 = NewArray(buffer_size, u8);
	defer free(data_buffer.data);

	while true {
		bytes_read: u32;
		if ReadFile(stdin, data_buffer.data, cast(u32) data_buffer.count, *bytes_read) == 0 {
			print("Null ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			continue;
		}
	}
}


#import "Basic";
#import "Windows";