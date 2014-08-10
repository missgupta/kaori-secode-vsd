function sift_select_features(sift_algo, param )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	set_env;
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s)', mfilename, sift_algo, param);
	logmsg(logfile, msg);
	tic;
	
	
    % parameters
	proj_dir = '/net/per610a/export/das11f/plsang/vsd2013';
    max_features = 1000000;
    kf_sampling_rate = 0.2; %% ~130K Keyframes
	
	% tong so keyfraem cua devel2013-new la 663.092 :D
	% tong so shot là 32.683 (trong đó 2523 là pos, 30160 là neg)
	% test set thì có 273.377 kf / 11245 sho
	
	output_file = sprintf('%s/feature/bow.codebook.devel/%s.%s.sift/data/selected_feats_%d.mat', proj_dir, sift_algo, num2str(param), max_features);
	if exist(output_file),
		fprintf('File [%s] already exist. skipped!\n', output_file);
		return;
	end
	
    %[list_keyframes_dev11, list_videos_dev11, list_pats_dev11 ] = vsd_load_keyframes( 'keyframe-5', 'dev11-new' );
	%[list_keyframes_test11, list_videos_test11, list_pats_test11 ] = vsd_load_keyframes( 'keyframe-5', 'test11-new' );
	%[list_keyframes_test12, list_videos_test12, list_pats_test12 ] = vsd_load_keyframes( 'keyframe-5', 'test12-new' );
	
	[list_keyframes, list_videos, list_pats] = vsd_load_keyframes( 'keyframe-5', 'devel2013-new' );
	
	%list_keyframes = [list_keyframes_dev11; list_keyframes_test11; list_keyframes_test12];
	%list_videos = [list_videos_dev11; list_videos_test11; list_videos_test12];
	%list_pats = [list_pats_dev11; list_pats_test11; list_pats_test12];
	
	num_selected_keyframes = ceil(kf_sampling_rate * length( list_keyframes ));
	rand_index = randperm(length(list_keyframes));
	selected_index = rand_index(1:num_selected_keyframes);
    selected_keyframes = list_keyframes(selected_index);
	selected_videos = list_videos(selected_index);
	selected_pats = list_pats(selected_index);
	
	max_features_per_video = ceil(1.1*max_features/length(selected_keyframes));
	feats = cell(length(selected_keyframes), 1);
	
	%kf_dir = sprintf('/net/sfv215/export/raid6/ledduy/mediaeval-2013/keyframe-5');
	kf_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/keyframe-5';
	
    parfor ii = 1:length(selected_keyframes),
        keyframe_id = selected_keyframes{ii};
        
		video_id = selected_videos{ii};		
		
		pat = selected_pats{ii};
		
        img_path = fullfile(kf_dir, pat, video_id, [keyframe_id, '.jpg']);
	
		if ~exist(img_path, 'file'),
			msg = sprintf('File does not exist [%s] \n', img_path);
			warning(msg);
			logmsg(logfile, msg);
			continue;
		end
     
		fprintf(' ***** [%d/%d] ******* <%s> ...\n', ii, length(selected_keyframes), keyframe_id);
		
		[frames, descrs] = sift_extract_features( img_path, sift_algo, param );
        
		if any(isnan(descrs), 1),
			% remove NaN columns
			msg = sprintf('Feature file contains NaN [%s] \n', img_path);
			warning(msg);
			logmsg(logfile, msg);
			
			descrs(:, any(isnan(descrs), 1)) = [];
		end
		
		% if more than 50% of points are empty --> possibley empty image
		if sum(all(descrs == 0, 1)) >= 0.5*size(descrs, 2),
			%warning('Maybe blank image...[%s]. Skipped!\n', keyframe_id);
			continue;
		end
        
        if size(descrs, 2) > max_features_per_video,
            feats{ii} = vl_colsubset(descrs, max_features_per_video);
        else
            feats{ii} = descrs;
        end
        
    end
    
    % concatenate features into a single matrix
    feats = cat(2, feats{:});
    
    if size(feats, 2) > max_features,
         feats = vl_colsubset(feats, max_features);
    end
	
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		cmd = sprintf('mkdir -p %s', output_dir);
		system(cmd);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
    save(output_file, 'feats', '-v7.3');
	
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s). Elapsed time: %s', mfilename, sift_algo, param, elapsed_str);
	logmsg(logfile, msg);
	
end

