tools: [16]string = string.["phase_modulator", "audio_source", "audio_sink", "null", "noise", "multiply",
	"map", "file_source", "file_sink", "ber_check", "bit_error_adder", "network_source", "network_sink",
	"phase_demodulator", "callsign", "callsign_detector"];

// file_upload
// file_download

build :: () {
	make_directory_if_it_does_not_exist("build");

	for 0..tools.count-1 {
		compile(tools[it]);
	}	

    set_build_options_dc(.{do_output=false});
}

compile :: (exe: string) {
	w := compiler_create_workspace(exe);
    if !w {
        print("Workspace '%' creation failed.\n", exe);
        return;
    }

	target_options := get_build_options(w);
    target_options.output_executable_name = exe;
	target_options.output_path = "build/";
	set_optimization(*target_options, .VERY_DEBUG);
    set_build_options(target_options, w);

	add_build_file(tprint("%.jai", exe), w);
}


#run build();

#import "Basic";
#import "Compiler";
#import "File";