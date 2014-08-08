function [ feats ] = densetraj_select_features( descriptor )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

    % parameters
    max_features = 1000000;
    sample_length = 30; % frames
    shot_sampling_rate = 0.333;
	
    [shots_dev11, shot_infos_dev11, v_infos_dev11, v_paths_dev11] = vsd_load_shots('shot_0180', 'dev11');
	[shots_test11, shot_infos_test11, v_infos_test11, v_paths_test11] = vsd_load_shots('shot_0180', 'test11');
	[shots_test12, shot_infos_test12, v_infos_test12, v_paths_test12] = vsd_load_shots('shot_0180', 'test12');
	
	shots = [shots_dev11; shots_test11; shots_test12];
	shot_infos = [shot_infos_dev11; shot_infos_test11; shot_infos_test12];
	
	%v_infos = [fieldnames(v_infos_dev11)' fieldnames(v_infos_test11)'; struct2cell(v_infos_dev11)' struct2cell(v_infos_test11)'];
	%v_paths = [fieldnames(v_paths_dev11)' fieldnames(v_paths_test11)'; struct2cell(v_paths_dev11)' struct2cell(v_paths_test11)'];
	%v_infos = struct(v_infos{:});
	%v_paths = struct(v_paths{:});
    
    
	num_selected_shots = ceil(shot_sampling_rate * length( shots ));
	rand_index = randperm(length(shots));
	selected_index = rand_index(1:num_selected_shots);
    selected_shots = shots(selected_index);
	selected_shot_infos = shot_infos(selected_index, :);
	
	
	max_features_per_video = ceil(1.05*max_features/length(selected_shots));
	feats = cell(length(selected_shots), 1);
	
	pattern='(?<video>VSD\d+_\d+)_shot\d+_\d+';
	
    parfor ii = 1:length(selected_shots),
        shot_id = selected_shots{ii};
        
		info = regexp(shot_id, pattern, 'names');
		
        video_dir = '/net/per610a/export/das11f/ledduy/plsang/vsd2013/video-rsz';
        video_file = [video_dir, '/', info.video, '.mpg'];
        
        start_frame = shot_infos(ii, 1);
        end_frame = shot_infos(ii, 2);
   
		fprintf('--- Start frame: %d -- End frame: %d \n', start_frame, end_frame);
		
        %if end_frame - start_frame > sample_length,
        %    start_frame = start_frame + randi(end_frame - start_frame - sample_length);
        %    end_frame = start_frame + sample_length;
        %end
		fprintf('Computing features for: %d - %s %f %% complete\n', ii, info.video, ii/length(selected_shots)*100.00);
		
        feat = densetraj_extract_features(video_file, start_frame, end_frame, 15, descriptor);
        
        if size(feat, 2) > max_features_per_video,
            feats{ii} = vl_colsubset(feat, max_features_per_video);
        else
            feats{ii} = feat;
        end
        
    end
    
	% saving temporary
	save('/net/per610a/export/das11f/ledduy/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.mbh/data/feats.mat', 'feats', '-v7.3');
	
    % concatenate features into a single matrix
    feats = cat(2, feats{:});
    
    if size(feats, 2) > max_features,
         feats = vl_colsubset(feats, max_features);
    end

	output_file = sprintf('/net/per610a/export/das11f/ledduy/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.%s/data/selected_feats_%d.mat', descriptor, max_features);
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		cmd = sprintf('mkdir -p %s', output_dir);
		system(cmd);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
    save(output_file, 'feats', '-v7.3');
    
end

