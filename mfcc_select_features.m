function mfcc_select_features( algo )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	set_env;
	
	% parameters
    max_features = 1000000;
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
	
	videos = fieldnames(v_paths);
	
	max_features_per_video = ceil(1.05*max_features/length(videos));
	
	feat_pat = sprintf('mfcc.%s', algo');

	local_proj_dir = '/net/per610a/export/das11f/plsang/vsd2014';
	raw_feat_dir = sprintf('%s/feature/%s/mfcc.rastamat.raw', local_proj_dir, shot_ann) ;
	
	%output_file = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', feat_pat, max_features);
	output_file = sprintf('%s/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', local_proj_dir, feat_pat, max_features);
	if exist(output_file, 'file'),
		fprintf('File [%s] already exist. skipped!!\n', output_file);
		return;
	end
	
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	all_feats = cell(length(videos), 1);
    
	fprintf('Loading video features ...\n');
    for ii = 1:length(videos),
		video_id = videos{ii};
		
		feat_file = sprintf('%s/%s.mat', raw_feat_dir, video_id);
		
		fprintf('[%d/%d] Loading video features <%s>...\n', ii, length(videos), feat_file);
        
		load(feat_file, 'feats');
		
        if size(feats, 2) > max_features_per_video,
            all_feats{ii} = vl_colsubset(feats, max_features_per_video);
        else
            all_feats{ii} = feats;
        end
        
    end
	
    % concatenate features into a single matrix
    all_feats = cat(2, all_feats{:});
    
    if size(all_feats, 2) > max_features,
         all_feats = vl_colsubset(all_feats, max_features);
    end

	feats = all_feats;
	fprintf('Saving selected features ...\n');
    save(output_file, 'feats', '-v7.3');
    
end

