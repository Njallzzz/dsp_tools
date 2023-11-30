
ProgramState :: struct {
	ma_format: miniaudio.ma_format;

	ma_ctx: miniaudio.ma_context;
	ma_config: miniaudio.ma_device_config;
	ma_device: miniaudio.ma_device;

	stdout: HANDLE;
	running: bool;

	args: Arguments;
}

Arguments :: struct {
	device: s32;			@"?output device"
	format: string = "f32";	@"?output format (default f32, options: u8, s16, s24, s32, f32)"
	channels: u32;			@"?output channels"
	sample_rate: u32;		@"?sample rate"
}

list_audio_devices :: (pstate: *ProgramState, select_capture_device: s32 = -1) {
	using miniaudio;

    pCaptureDeviceInfos: *ma_device_info;
    captureDeviceCount: ma_uint32;

    result := ma_context_get_devices(*pstate.ma_ctx, null, null, *pCaptureDeviceInfos, *captureDeviceCount);
    if result != .MA_SUCCESS {
        print("Failed to retrieve audio device information.\n");
        return;
    }

    if select_capture_device == -1 {
	    for 0..captureDeviceCount-1 {
	    	print("%: %\n", it, to_string(pCaptureDeviceInfos[it].name.data));
	    }
	} else {
		pstate.ma_config.capture.pDeviceID = *pCaptureDeviceInfos[select_capture_device].id;
	}

}

audio_callback_u8 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []u8;
		sample_buffer.count = frameCount;
		sample_buffer.data = pInput;

		bytes_to_write: u32 = cast(u32) (size_of(u8) * pstate.args.channels * sample_buffer.count);
		bytes_written: u32;
	    if WriteFile(pstate.stdout, sample_buffer.data, bytes_to_write, *bytes_written, null) == 0
	    	pstate.running = false;
	    if bytes_written != bytes_to_write
	    	pstate.running = false;
	}
}

audio_callback_s16 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []s16;
		sample_buffer.count = frameCount;
		sample_buffer.data = pInput;

	    bytes_to_write: u32 = cast(u32) (size_of(s16) * pstate.args.channels * sample_buffer.count);
		bytes_written: u32;
	    if WriteFile(pstate.stdout, sample_buffer.data, bytes_to_write, *bytes_written, null) == 0
	    	pstate.running = false;
	    if bytes_written != bytes_to_write
	    	pstate.running = false;
	}
}

audio_callback_s24 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []s32;
		sample_buffer.count = frameCount;
		sample_buffer.data = pInput;

	    bytes_to_write: u32 = cast(u32) (size_of(u8) * 3 * pstate.args.channels * sample_buffer.count);
		bytes_written: u32;
	    if WriteFile(pstate.stdout, sample_buffer.data, bytes_to_write, *bytes_written, null) == 0
	    	pstate.running = false;
	    if bytes_written != bytes_to_write
	    	pstate.running = false;
	}
}

audio_callback_s32 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []s32;
		sample_buffer.count = frameCount;
		sample_buffer.data = pInput;

	    bytes_to_write: u32 = cast(u32) (size_of(s32) * pstate.args.channels * sample_buffer.count);
		bytes_written: u32;
	    if WriteFile(pstate.stdout, sample_buffer.data, bytes_to_write, *bytes_written, null) == 0
	    	pstate.running = false;
	    if bytes_written != bytes_to_write
	    	pstate.running = false;
	}
}

audio_callback_f32 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []float32;
		sample_buffer.count = frameCount;
		sample_buffer.data = pInput;

		bytes_to_write: u32 = cast(u32) (size_of(float32) * pstate.args.channels * sample_buffer.count);
		bytes_written: u32;
	    if WriteFile(pstate.stdout, sample_buffer.data, bytes_to_write, *bytes_written, null) == 0
	    	pstate.running = false;
	    if bytes_written != bytes_to_write
	    	pstate.running = false;
	}
}

main :: () {
	pstate: ProgramState;
	pstate.running = true;

	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);	// Get handle to stdout

	if  miniaudio.ma_context_init(null, 0, null, *pstate.ma_ctx) != .MA_SUCCESS {
        print("Failed to initialize miniaudio library.\n", to_standard_error = true);
        return;
    }
    defer miniaudio.ma_context_uninit(*pstate.ma_ctx);

    success, args, is_set := parse_arguments(Arguments);
	if !success {
		print("Unable to process command line arguments\n", to_standard_error = true);
		return;
	}

	if !is_set.device {
		print("No capture device specified!\n", to_standard_error = true);
		list_audio_devices(*pstate);
		return;
	}

	pstate.args = args;
	pstate.ma_config = miniaudio.ma_device_config_init(miniaudio.ma_device_type.capture);
	list_audio_devices(*pstate, args.device);

	if args.format == {
		case "u8";
			pstate.ma_config.capture.format = miniaudio.ma_format.ma_format_u8;
			pstate.ma_config.dataCallback   = audio_callback_u8;
		case "s16";
			pstate.ma_config.capture.format = miniaudio.ma_format.ma_format_s16;
			pstate.ma_config.dataCallback   = audio_callback_s16;
		case "s24";
			pstate.ma_config.capture.format = miniaudio.ma_format.ma_format_s24;
			pstate.ma_config.dataCallback   = audio_callback_s24;
		case "s32";
			pstate.ma_config.capture.format = miniaudio.ma_format.ma_format_s32;
			pstate.ma_config.dataCallback   = audio_callback_s32;
		case ""; #through;
		case "f32";
			pstate.ma_config.capture.format = miniaudio.ma_format.ma_format_f32;
			pstate.ma_config.dataCallback   = audio_callback_f32;
		case;
			print("invalid format!\n", to_standard_error = true);
			return;
	}

	if is_set.channels 		pstate.ma_config.capture.channels 	= args.channels;
    if is_set.sample_rate 	pstate.ma_config.sampleRate 		= args.sample_rate;
    pstate.ma_config.pUserData 			= *pstate;

    if miniaudio.ma_device_init(*pstate.ma_ctx, *pstate.ma_config, *pstate.ma_device) != .MA_SUCCESS {
        print("Failed to open capture device.\n", to_standard_error = true);
        return;
    }

	pstate.args.channels = pstate.ma_device.capture.channels;
	pstate.args.sample_rate = pstate.ma_device.sampleRate;

	if is_set.channels && args.channels != pstate.args.channels
		print("channel count % is not possible, automatically set to %\n", args.channels, pstate.args.channels, to_standard_error = true);

	if is_set.sample_rate && args.sample_rate != pstate.args.sample_rate
		print("sample rate % is not possible, automatically set to %\n", args.sample_rate, pstate.args.sample_rate, to_standard_error = true);

	print("Audio source: %, channels: %, sample rate: %\n", to_string(pstate.ma_device.capture.name.data), pstate.args.channels, pstate.args.sample_rate, to_standard_error = true);
    if miniaudio.ma_device_start(*pstate.ma_device) != .MA_SUCCESS {
        print("Failed to start capture device.\n", to_standard_error = true);
        return;
    }

    defer {
    	if miniaudio.ma_device_stop(*pstate.ma_device) != .MA_SUCCESS
	        print("Failed to stop capture device.\n", to_standard_error = true);

	    miniaudio.ma_device_uninit(*pstate.ma_device);
    }

    while pstate.running Sleep(50);
    print("Closing audio source\n", to_standard_error = true);
}

#import "Basic";
#import "Windows";
#import "Command_Line";
miniaudio :: #import,file "external/miniaudio.jai";