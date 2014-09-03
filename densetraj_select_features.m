function [ feats ] = densetraj_select_features( descriptor )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

    % parameters
    max_features = 1000000;
    sample_length = 60; % frames
    shot_sampling_rate = 0.5;
	
	video_dir = '/net/per610a/export/das11f/plsang/vsd2014/video-rsz';
	proj_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014';
	shot_ann = 'keyframe-5';
	devel_pats = {'devel2011', 'test2011', 'test2012', 'test2013'};
	
	shots = [];
	shot_infos = [];
	v_infos = struct;
	v_paths = struct;
	
	fprintf('Loading shot info...\n');
	for devel_pat = devel_pats,
		[shots_, shot_infos_, v_infos_, v_paths_] = vsd_load_shots_2014(proj_dir, shot_ann, devel_pat{:});
		
		shots = [shots; shots_];
		shot_infos = [shot_infos; shot_infos_];
		
		v_infos = [fieldnames(v_infos)' fieldnames(v_infos_)'; struct2cell(v_infos)' struct2cell(v_infos_)'];
		v_paths = [fieldnames(v_paths)' fieldnames(v_paths_)'; struct2cell(v_paths)' struct2cell(v_paths_)'];
		
		v_infos = struct(v_infos{:});
		v_paths = struct(v_paths{:});
	end
	
	num_selected_shots = ceil(shot_sampling_rate * length( shots ));
	rand_index = randperm(length(shots));
	selected_index = rand_index(1:num_selected_shots);
    selected_shots = shots(selected_index);
	selected_shot_infos = shot_infos(selected_index, :);
	
	
	max_features_per_video = ceil(1.05*max_features/length(selected_shots));
	feats = cell(length(selected_shots), 1);
	
	pattern='(?<video>VSD_\w+\d+_\d+).shot_\d+';
	
    parfor ii = 1:length(selected_shots),
        shot_id = selected_shots{ii};
        
		info = regexp(shot_id, pattern, 'names');
		
        video_file = fullfile(video_dir, v_paths.(info.video));
        
        start_frame = shot_infos(ii, 1);
        end_frame = shot_infos(ii, 2);
   
		fprintf('--- Start frame: %d -- End frame: %d \n', start_frame, end_frame);
		
        if end_frame - start_frame > sample_length,
            start_frame = start_frame + randi(end_frame - start_frame - sample_length);
            end_frame = start_frame + sample_length;
        end
		
		fprintf('Computing features for: %s (%d-%d) (%f %% complete)\n', info.video, start_frame, end_frame, ii/length(selected_shots)*100.00);
		
        feat = densetraj_extract_features(video_file, descriptor, start_frame, end_frame);
        
        if size(feat, 2) > max_features_per_video,
            feats{ii} = vl_colsubset(feat, max_features_per_video);
        else
            feats{ii} = feat;
        end
        
    end
    	
    % concatenate features into a single matrix
    feats = cat(2, feats{:});
    
    if size(feats, 2) > max_features,
         feats = vl_colsubset(feats, max_features);
    end

	local_proj_dir = '/net/per610a/export/das11f/plsang/vsd2014';
	
	output_file = sprintf('%s/feature/bow.codebook.devel/idensetraj.%s/data/selected_feats_%d.mat', local_proj_dir, descriptor, max_features);
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	fprintf('Saving selected features to [%s]...\n', output_file);
    save(output_file, 'feats', '-v7.3');
    
end

