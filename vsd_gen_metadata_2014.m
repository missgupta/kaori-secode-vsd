function vsd_gen_metadata_2014
	video_dir = '/net/per610a/export/das11f/plsang/vsd2014/video-rsz';
	proj_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014';
	shot_ann = 'keyframe-5';
	vsd_pats = {'devel2011', 'test2011', 'test2012', 'test2013', 'test2014'};
	
	output_file = '/net/per610a/export/das11f/plsang/vsd2014/metadata/vsd_infos.mat';
	if exist(output_file, 'file'),
		return;
	end
	
	shots = [];
	shot_infos = [];
	v_infos = struct;
	v_paths = struct;
	keyframes = struct;
	
	fprintf('Loading shot info...\n');
	for devel_pat = vsd_pats,
		fprintf('Loading shot info for pat <%s>...\n', devel_pat{:});
		[shots_, shot_infos_, v_infos_, v_paths_, keyframes_] = vsd_load_shots_2014(proj_dir, shot_ann, devel_pat{:});
		
		shots = [shots; shots_];
		shot_infos = [shot_infos; shot_infos_];
		
		v_infos = [fieldnames(v_infos)' fieldnames(v_infos_)'; struct2cell(v_infos)' struct2cell(v_infos_)'];
		v_paths = [fieldnames(v_paths)' fieldnames(v_paths_)'; struct2cell(v_paths)' struct2cell(v_paths_)'];
		
		v_infos = struct(v_infos{:});
		v_paths = struct(v_paths{:});
		
		%% special treat to concatenate keyframes struct.
		fn1 = fieldnames(keyframes);
		fn2 = fieldnames(keyframes_);
		fn = [fn1; fn2];
		
		c1 = struct2cell(keyframes);
		c2 = struct2cell(keyframes_);
		c = [c1;c2];

		keyframes = cell2struct(c,fn,1);
	end
	
	vsd_infos = struct;
	vsd_infos.shots = shots;
	vsd_infos.shot_infos = shot_infos;
	vsd_infos.v_infos = v_infos;
	vsd_infos.v_paths = v_paths;
	vsd_infos.keyframes = keyframes;
	
	save(output_file, 'vsd_infos');
	
end