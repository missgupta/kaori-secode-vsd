function [ shots, shot_infos, v_infos, v_paths, keyframes ] = vsd_load_shots_2014( proj_dir, shot_ann, sz_pat )
%LOAD_SEGMENTS Summary of this function goes here
%   shot_ann = 'keyframe-5'
%	sz_pat	= 'devel2014';	% merged partition, annotated for each year 
	
	videolst = sprintf('%s/metadata/%s.lst', proj_dir, sz_pat);
	
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    
    videos = infos{1};
    
    pats = infos{3};	% physical patition
    
    shots = [];
	starts = [];
	lengths = [];
	 
	v_paths = struct;
	
    for ii = 1:length(videos),
        video = videos{ii};
        pat = pats{ii};
        mfile = sprintf('%s/sbinfo/%s/%s/%s.sb', proj_dir, shot_ann, sz_pat, video);
       
        fh = fopen(mfile);
		video_name=fgets(fh);
		video_id=fgets(fh);
		
		v_paths.(video) = sprintf('%s/%s.mpg', pat, strtrim(video_name));
		
        this_shots = textscan(fh, '%s %*q %d %*q %d');
        
        shots = [shots; this_shots{1}];
		starts = [starts; this_shots{2}];
		lengths = [lengths; this_shots{3}];
        fclose(fh);
    end
	
	%% update: Jul 5, 2013 -- creat infos struct
	v_infos = struct;
	shot_infos = zeros(length(shots), 2);

	% VSD_devel2011_1.shot_1
	pattern='(?<video>VSD_\w+\d+_\d+).shot_\d+';
	for ii = 1:length(shots),
		
		shot = shots{ii};    
		info = regexp(shot, pattern, 'names');
		start_frame = starts(ii);
        end_frame = start_frame + lengths(ii) - 1;
		if ~isfield(v_infos, info.video),
			v_infos.(info.video) = [start_frame, end_frame];
		else
			v_infos.(info.video) = [v_infos.(info.video), start_frame, end_frame]; 
		end	
		shot_infos(ii, :) = [start_frame end_frame];
	end
	
	
	% load kf list
	fprintf('Loading kf list...\n');
	
	%VSD_test2014_1.shot_1.RKF_1.Frame_1
	kf_pattern = '(?<shot_id>VSD_\w+\d+_\d+.shot_\d+).\w+_\d+.\w+_\d+';	
	
	keyframes = struct;
	
	for ii = 1:length(videos),
        video = videos{ii};
        mfile = sprintf('%s/metadata/%s/%s/%s.prg', proj_dir, shot_ann, sz_pat, video);
       
        fh = fopen(mfile);
		kf_list = textscan(fh, '%s');
		fclose(fh);
		
        kf_list = kf_list{1};
		
		for jj = 1:length(kf_list),
			kf_name = kf_list{jj};
			info = regexp(kf_name, kf_pattern, 'names');
			shotkey = strrep(info.shot_id, '.', '_');
			if isfield(keyframes, shotkey),
				keyframes.(shotkey){end+1} = kf_name;
			else
				keyframes.(shotkey){1} = kf_name;
			end
		end
		
    end
	
end

