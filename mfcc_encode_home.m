function mfcc_encode_home( algo, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	set_env;
	
	if ~exist('algo', 'var'),
		algo = 'rastamat';
	end
	
	enc_type = 'bow'; % 'fc';
	clustering_algo = 'kmeans'; % 'gmm', 'kmeans'
	codebook_size = 1000;
	feat_dim = 39;
	
	org_proj_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014';
	proj_dir = '/net/per610a/export/das11f/plsang/vsd2014';
	shot_ann = 'keyframe-5';
	fea_dir = sprintf('%s/feature/%s', proj_dir, shot_ann);
	raw_fea_dir = sprintf('%s/feature/%s/mfcc.rastamat.raw', proj_dir, shot_ann) ;
	
    feature_ext_fc = sprintf('mfcc.%s.cb%d.%s', algo, codebook_size, enc_type);

	shots = [];
	shot_infos = [];
	v_infos = struct;
	v_paths = struct;
	
	%devel_pats = {'devel2011', 'test2011', 'test2012', 'test2013', 'test2014'};
	%devel_pats = {'test2012'};
	devel_pats = {'devel2011', 'test2011', 'test2013', 'test2014'};
	
	fprintf('Loading shot info...\n');
	for devel_pat = devel_pats,
		[shots_, shot_infos_, v_infos_, v_paths_] = vsd_load_shots_2014(org_proj_dir, shot_ann, devel_pat{:});
		
		shots = [shots; shots_];
		shot_infos = [shot_infos; shot_infos_];
		
		v_infos = [fieldnames(v_infos)' fieldnames(v_infos_)'; struct2cell(v_infos)' struct2cell(v_infos_)'];
		v_paths = [fieldnames(v_paths)' fieldnames(v_paths_)'; struct2cell(v_paths)' struct2cell(v_paths_)'];
		
		v_infos = struct(v_infos{:});
		v_paths = struct(v_paths{:});
	end
	
	videos = fieldnames(v_paths);
	
	raw_feats = struct;
	%% load raw feature
	for ii=1:length(videos),
		video_id = videos{ii};
		raw_feat_file = sprintf('%s/%s.mat', raw_fea_dir, video_id );
		fprintf('Loading raw feature for video [%s]...\n', video_id);
		load(raw_feat_file, 'feats');
		raw_feats.(video_id) = feats;
	end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext_fc);
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
    
	% loading gmm codebook
	
	codebook_file = sprintf('%s/feature/bow.codebook.devel/mfcc.%s/data/codebook.%s.%d.%d.mat', proj_dir, algo, clustering_algo, codebook_size, feat_dim);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
	
	if strcmp(enc_type, 'bow'),
		kdtree = vl_kdtreebuild(codebook);
	end
	
 	if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(shots),
        end_seg = length(shots);
    end
		
    for ii = start_seg:end_seg,
    	shot_id = shots{ii};
		splits = regexp(shot_id, '\.', 'split');
		video_id = splits{1};
		splits = regexp(video_id, '_', 'split');
		pat_id = splits{2};
		
		start_frame = shot_infos(ii, 1);
        
		end_frame = shot_infos(ii, 2);
		
		start_idx = floor(100 * start_frame / 25) + 1;	%	100 = 1000ms/10ms
		end_idx = floor(100 * end_frame / 25);			%
		
		%output_fc_file = [output_dir, '/', video_id, '/', shot_id, '.mat'];
		output_file = sprintf('%s/%s/%s/%s.mat', output_dir, pat_id, video_id, shot_id);
		
		if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
        fprintf(' [%d --> %d --> %d] Extracting features & Encoding for [%s]...\n', start_seg, ii, end_seg, shot_id);
        
		if end_idx > size(raw_feats.(video_id), 2),
			end_idx = size(raw_feats.(video_id), 2);
		end
		
		feat = raw_feats.(video_id)(:, start_idx:end_idx);
		
		if isempty(feat),
			continue;
		else			    
			if strcmp(enc_type, 'fc'),
				code = fc_encode(feat, codebook, []);
			elseif strcmp(enc_type, 'bow'),
				code = kcb_encode(feat, codebook, kdtree);
			end
			
		end
		
		par_save(output_file, code, 1); 
    end

end


