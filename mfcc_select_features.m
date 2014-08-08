function mfcc_select_features( algo )
%SELECT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	% parameters
    max_features = 1000000;
	shot_sampling_rate = 0.5;
   
	[ shots, shot_infos, v_infos, v_paths ] = vsd_load_shots('keyframe-5', 'devel2013');
	
	videos = fieldnames(v_paths);
	
	max_features_per_video = ceil(1.1*max_features/length(videos));
	
	
	raw_feat_dir = '/net/per610a/export/das11f/plsang/vsd2013/feature/keyframe-5/mfcc.rastamat.raw/devel2013';
	
	pattern = '(?<video>VSD\d+_\d+).shot\d+_\d+';
	
    video_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/video';
	
	
	if ~exist('algo', 'var'),
		algo = 'rastamat';
	end
	
	feat_pat = sprintf('mfcc.%s', algo');

	output_file = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', feat_pat, max_features);
	if exist(output_file, 'file'),
		fprintf('File [%s] already exist. skipped!!\n', output_file);
		return;
	end
	
	output_dir = fileparts(output_file);
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	all_feats = cell(length(videos), 1);
    
    for ii = 1:length(videos),
		video_id = videos{ii};
		
		feat_file = sprintf('%s/%s.mat', raw_feat_dir, video_id);
		
		fprintf('Loading %s...\n', feat_file);
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
    save(output_file, 'feats', '-v7.3');
    
end


function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/mfcc_select_features.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end
