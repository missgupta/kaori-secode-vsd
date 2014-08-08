function mfcc_encode_home( szPat, algo, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	set_env;
	
	if ~exist('algo', 'var'),
		algo = 'rastamat';
	end
	
	codebook_gmm_size = 256;
	feat_dim = 39;
	dimred = 24;
	
	fea_dir = '/net/per610a/export/das11f/plsang/vsd2013/feature/keyframe-5';
	raw_fea_dir = '/net/per610a/export/das11f/plsang/vsd2013/feature/keyframe-5/mfcc.rastamat.raw';
	
    feature_ext_fc = sprintf('mfcc.%s.cb%d.fc', algo, codebook_gmm_size);

	[ shots, shot_infos, v_infos, v_paths ] = vsd_load_shots('keyframe-5', szPat);
	
	videos = fieldnames(v_paths);
	
	raw_feats = struct;
	%% load raw feature
	for ii=1:length(videos),
		video_id = videos{ii};
		raw_feat_file = sprintf('%s/%s/%s.mat', raw_fea_dir, szPat, video_id );
		fprintf('Loading raw feature for video [%s]...\n', video_id);
		load(raw_feat_file, 'feats');
		raw_feats.(video_id) = feats;
	end
	
    output_dir_fc = sprintf('%s/%s/%s', fea_dir, feature_ext_fc, szPat);
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
    end
    
	% loading gmm codebook
	
	codebook_gmm_file = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/mfcc.%s/data/codebook.gmm.%d.%d.mat', algo, codebook_gmm_size, feat_dim);
    codebook_gmm_ = load(codebook_gmm_file, 'codebook');
    codebook_gmm = codebook_gmm_.codebook;
 
	low_proj = [];
	f_low_proj = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/mfcc.%s/data/lowproj.%d.%d.mat', algo, dimred, feat_dim);
	if dimred > 0 && exist(f_low_proj, 'file'),
		load(f_low_proj, 'low_proj');
	else
		warning('Not using PCA!\n');
	end
	
	codebook_pca = [];
	if ~isempty(low_proj),
		feature_ext_pca = sprintf('mfcc.%s.cb%d.fc.pca', algo, codebook_gmm_size);  
		output_dir_pca = sprintf('%s/%s/%s', fea_dir, feature_ext_pca, szPat) ;
		if ~exist(output_dir_pca, 'file'),
			mkdir(output_dir_pca);
		end		
		
		codebook_file_pca = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/mfcc.%s/data/codebook.gmm.%d.%d.mat', ...
			algo, codebook_gmm_size, size(low_proj, 1));
		codebook_pca_ = load(codebook_file_pca, 'codebook');
		codebook_pca = codebook_pca_.codebook;
	
	end
	
 	if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(shots),
        end_seg = length(shots);
    end
	
	pattern = '(?<video>VSD\d+_\d+).shot\d+_\d+';
		
    for ii = start_seg:end_seg,
        shot_id = shots{ii};
		
		info = regexp(shot_id, pattern, 'names');
        
		video_id = info.video;
		
		start_frame = shot_infos(ii, 1);
        
		end_frame = shot_infos(ii, 2);
		
		start_idx = floor(100 * start_frame / 25) + 1;	%	100 = 1000ms/10ms
		end_idx = floor(100 * end_frame / 25);			%
		
		output_fc_file = [output_dir_fc, '/', video_id, '/', shot_id, '.mat'];
        
		output_file_pca = [output_dir_pca, '/', video_id, '/', shot_id, '.mat'];
		
		if isempty(low_proj) && exist(output_fc_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_fc_file);
            continue;
			
		elseif exist(output_fc_file, 'file') && exist(output_file_pca, 'file') ,
            fprintf('Both file [%s] and [%s] already exist. Skipped!!\n', output_fc_file, output_file_pca);
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
			code_fc = fc_encode(feat, codebook_gmm, []);	
			code_pca = fc_encode(feat, codebook_pca, low_proj);	
		end
        
		output_vdir_fc = [output_dir_fc, '/', video_id];
        if ~exist(output_vdir_fc, 'file'),
            mkdir(output_vdir_fc);
        end
		
		par_save(output_fc_file, code_fc); 
		
		if ~isempty(low_proj),
			output_vdir_pca = [output_dir_pca, '/', video_id];
			if ~exist(output_vdir_pca, 'file'),
				mkdir(output_vdir_pca);
			end
        
			par_save(output_file_pca, code_pca); 
		end
		
    end

end

function par_save( output_file, code )
	save( output_file, 'code');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/mfcc_encode_home.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

