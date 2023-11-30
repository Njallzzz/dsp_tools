
ProgramState :: struct {
	ma_format: miniaudio.ma_format;

	ma_ctx: miniaudio.ma_context;
	ma_config: miniaudio.ma_device_config;
	ma_device: miniaudio.ma_device;

	stdout: HANDLE;
	stdin: HANDLE;
	running: bool;

	args: Arguments;
}

Arguments :: struct {
	device: s32;		@"?output device"
	format: string;		@"?output format (default f32, options: u8, s16, s24, s32, f32)"
	channels: u32;		@"?output channels"
	sample_rate: u32;	@"?sample rate"
	passthrough: bool;	@"?Passthrough input to output"
}

list_audio_devices :: (pstate: *ProgramState, select_playback_device: s32 = -1) {
	using miniaudio;

	pPlaybackDeviceInfos: *ma_device_info;
    playbackDeviceCount: ma_uint32;

    result := ma_context_get_devices(*pstate.ma_ctx, *pPlaybackDeviceInfos, *playbackDeviceCount, null, null);
    if result != .MA_SUCCESS {
        print("Failed to retrieve audio device information.\n");
        return;
    }

    if select_playback_device == -1 {
	    for 0..playbackDeviceCount-1 {
	    	print("%: %\n", it, to_string(pPlaybackDeviceInfos[it].name.data));
	    }
	} else {
		pstate.ma_config.playback.pDeviceID = *pPlaybackDeviceInfos[select_playback_device].id;
	}

}

audio_callback_u8 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []u8;
		sample_buffer.count = frameCount;
		sample_buffer.data = pOutput;

		bytes_read: u32;
		if ReadFile(pstate.stdin, sample_buffer.data, cast(u32) (size_of(u8) * pstate.args.channels * sample_buffer.count), *bytes_read) == 0 {
			print("Audio Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			pstate.running = false;
		}

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, sample_buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    	}
		}
	}
}


audio_callback_s16 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []s16;
		sample_buffer.count = frameCount;
		sample_buffer.data = pOutput;

		bytes_read: u32;
		if ReadFile(pstate.stdin, sample_buffer.data, cast(u32) (size_of(s16) * pstate.args.channels * sample_buffer.count), *bytes_read) == 0 {
			print("Audio Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			pstate.running = false;
		}

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, sample_buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    	}
		}
	}
}


audio_callback_s24 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []u8;
		sample_buffer.count = frameCount;
		sample_buffer.data = pOutput;

		bytes_read: u32;
		if ReadFile(pstate.stdin, sample_buffer.data, cast(u32) (size_of(u8) * 3 * pstate.args.channels * sample_buffer.count), *bytes_read) == 0 {
			print("Audio Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			pstate.running = false;
		}

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, sample_buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    	}
		}
	}
}



audio_callback_s32 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []s32;
		sample_buffer.count = frameCount;
		sample_buffer.data = pOutput;

		bytes_read: u32;
		if ReadFile(pstate.stdin, sample_buffer.data, cast(u32) (size_of(s32) * pstate.args.channels * sample_buffer.count), *bytes_read) == 0 {
			print("Audio Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			pstate.running = false;
		}

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, sample_buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    	}
		}
	}
}

audio_callback_f32 :: (pDevice: *miniaudio.ma_device, pOutput: *void, pInput: *void, frameCount: miniaudio.ma_uint32) #c_call {
	ctx: Context;
	push_context ctx {
		pstate: *ProgramState = xx pDevice.pUserData;
		sample_buffer: []float32;
		sample_buffer.count = frameCount;
		sample_buffer.data = pOutput;

		bytes_read: u32;
		if ReadFile(pstate.stdin, sample_buffer.data, cast(u32) (size_of(float32) * pstate.args.channels * sample_buffer.count), *bytes_read) == 0 {
			print("Audio Sink ReadFile Error: %\n", GetLastError(), to_standard_error = true);
			pstate.running = false;
		}

		if pstate.args.passthrough {
			bytes_written: u32;
	    	if WriteFile(pstate.stdout, sample_buffer.data, bytes_read, *bytes_written, null) == 0 {
	    		print("File Sink WriteFile Error: %\n", GetLastError(), to_standard_error = true);
	    	}
		}
	}
}

main :: () {
	pstate: ProgramState;
	pstate.running = true;

	pstate.stdout = GetStdHandle(STD_OUTPUT_HANDLE);
	pstate.stdin = GetStdHandle(STD_INPUT_HANDLE);	// Get handle to stdin

	if  miniaudio.ma_context_init(null, 0, null, *pstate.ma_ctx) != .MA_SUCCESS {
        print("Failed to initialize miniaudio library.\n", to_standard_error = true);
        return;
    }
    defer miniaudio.ma_context_uninit(*pstate.ma_ctx);

    success, args, is_set := parse_arguments(Arguments);
	if !success return;

	if !is_set.device {
		print("No playback device specified!\n", to_standard_error = true);
		list_audio_devices(*pstate);
		return;
	}

	if !is_set.format 
		args.format = "f32";

	pstate.args = args;
	pstate.ma_config = miniaudio.ma_device_config_init(miniaudio.ma_device_type.playback);
	list_audio_devices(*pstate, args.device);

	if args.format == {
		case "u8";
			pstate.ma_config.playback.format = miniaudio.ma_format.ma_format_u8;
			pstate.ma_config.dataCallback   = audio_callback_u8;
		case "s16";
			pstate.ma_config.playback.format = miniaudio.ma_format.ma_format_s16;
			pstate.ma_config.dataCallback   = audio_callback_s16;
		case "s24";
			pstate.ma_config.playback.format = miniaudio.ma_format.ma_format_s24;
			pstate.ma_config.dataCallback   = audio_callback_s24;
		case "s32";
			pstate.ma_config.playback.format = miniaudio.ma_format.ma_format_s32;
			pstate.ma_config.dataCallback   = audio_callback_s32;
		case ""; #through;
		case "f32";
			pstate.ma_config.playback.format = miniaudio.ma_format.ma_format_f32;
			pstate.ma_config.dataCallback   = audio_callback_f32;
		case;
			print("invalid format!\n", to_standard_error = true);
			return;
	}

	if is_set.channels 		pstate.ma_config.playback.channels 	= args.channels;
    if is_set.sample_rate 	pstate.ma_config.sampleRate 		= args.sample_rate;
    pstate.ma_config.pUserData 			= *pstate;

    if miniaudio.ma_device_init(*pstate.ma_ctx, *pstate.ma_config, *pstate.ma_device) != .MA_SUCCESS {
        print("Failed to open playback device.\n", to_standard_error = true);
        return;
    }

	pstate.args.channels = pstate.ma_device.playback.channels;
	pstate.args.sample_rate = pstate.ma_device.sampleRate;

	if is_set.channels && args.channels != pstate.args.channels
		print("channel count % is not possible, automatically set to %\n", args.channels, pstate.args.channels, to_standard_error = true);

	if is_set.sample_rate && args.sample_rate != pstate.args.sample_rate
		print("sample rate % is not possible, automatically set to %\n", args.sample_rate, pstate.args.sample_rate, to_standard_error = true);

	print("Audio sink: %, channels: %, sample rate: %\n", to_string(pstate.ma_device.playback.name.data), pstate.args.channels, pstate.args.sample_rate, to_standard_error = true);
    if miniaudio.ma_device_start(*pstate.ma_device) != .MA_SUCCESS {
        print("Failed to start playback device.\n", to_standard_error = true);
        return;
    }

    defer {
    	if miniaudio.ma_device_stop(*pstate.ma_device) != .MA_SUCCESS
	        print("Failed to stop playback device.\n", to_standard_error = true);

	    miniaudio.ma_device_uninit(*pstate.ma_device);
    }

    while pstate.running Sleep(50);
}

#import "Basic";
#import "Windows";
#import "Command_Line";
miniaudio :: #import,file "external/miniaudio.jai";