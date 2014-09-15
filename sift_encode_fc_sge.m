function sift_encode_fc_sge( proj_name, exp_ann, sift_algo, param, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;
	
    % encoding type
    enc_type = 'fisher';
	
	if ~exist('codebook_size', 'var'),
		codebook_size = 256;
	end
    
	if ~exist('spm', 'var'),
		spm = 0;
	end
	
	default_dim = 128;
	if ~exist('dimred', 'var'),
		dimred = 80;
	end
	
	agg_method = 'max'; % sum, max 
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d)', mfilename, proj_name, exp_ann, sift_algo, num2str(param), codebook_size, dimred, spm, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
	feat_pat = sprintf('%s.%s.sift', sift_algo, num2str(param));
	feature_ext = sprintf('%s.cb%d.%s.%s', feat_pat, codebook_size, enc_type, agg_method);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
	if dimred < default_dim,,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/%s/feature/bow.codebook.devel/%s/data/codebook.gmm.%d.%d.mat', ...
		proj_name, feat_pat, codebook_size, dimred);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
 
 	low_proj = [];
	if dimred < default_dim,
		lowproj_file = sprintf('/net/per610a/export/das11f/plsang/%s/feature/bow.codebook.devel/%s/data/lowproj.%d.%d.mat', ...
			proj_name, feat_pat, dimred, default_dim);
			
		fprintf('Loading low projection matrix [%s]...\n', lowproj_file);
		low_proj_ = load(lowproj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end

	%%%%% Load shot info
	meta_file = '/net/per610a/export/das11f/plsang/vsd2014/metadata/vsd_infos.mat';
	fprintf('Loading meta file [%s] ...!!\n', meta_file);
	load(meta_file, 'vsd_infos');
	%%%%% Load shot info
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(vsd_infos.shots),
        end_seg = length(vsd_infos.shots);
    end
    
    %tic
	
	proj_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014';
    kf_dir = sprintf('%s/keyframe-5/', proj_dir);
    
	output_dir = sprintf('/net/per610a/export/das11f/plsang/%s/feature/%s/%s', proj_name, exp_ann, feature_ext);
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
		change_perm(output_dir);
    end
    
	
    for ii = start_seg:end_seg,
        shot_id = vsd_infos.shots{ii};                 
		
		shotkey = strrep(shot_id, '.', '_');
		if ~isfield(vsd_infos.keyframes, shotkey),
			msg = sprintf('Shot <%s> does not exist in keyframes struct\n', shot_id); 
			logmsg(logfile, msg);
			continue;
		end
        
		splits = regexp(shot_id, '\.', 'split');
		video_id = splits{1};
		splits = regexp(video_id, '_', 'split');
		pat_id = splits{2};
		
		output_file = sprintf('%s/%s/%s/%s.mat', output_dir, pat_id, video_id, shot_id);
		
		if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
		
		video_kf_dir = fullfile(kf_dir, pat_id, video_id);
		
		kfs = vsd_infos.keyframes.(shotkey);
       
		%% update Jul 5, 2013: support segment-based
		
		fprintf(' [%d --> %d --> %d] Extracting & encoding for [%s - %d kfs]...\n', start_seg, ii, end_seg, video_id, length(kfs));
        
		code = cell(length(kfs), 1);
		
		for jj = 1:length(kfs),
			if ~mod(jj, 10),
				fprintf('%d ', jj);
			end
			img_name = kfs{jj};
			img_path = fullfile(video_kf_dir, [img_name, '.jpg']);
			
			if ~exist(img_path, 'file'),
				msg = sprintf('File does not exist [%s] \n', img_path);
				warning(msg);
				logmsg(logfile, msg);
				continue;
			end
		
			[~, descrs] = sift_extract_features( img_path, sift_algo, param );
            
            % if more than 50% of points are empty --> possibley empty image
            if isempty(descrs) || sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			code_ = sift_do_encoding(enc_type, descrs, codebook, [], low_proj);
			
			if any(isnan(code_)), 
				msg = sprintf('Image <%s> contains NaN features\n', img_name); 
				logmsg(logfile, msg);
				continue; 
			end;
			
			code{jj} = code_;	
			
			clear descrs, code_;
		end 
        
		code = cat(2, code{:});
		if strcmp(agg_method, 'sum'),
			code = mean(code, 2);
		elseif strcmp(agg_method, 'max'),
			code = max(code, [], 2);
		else
			error('unknown aggregation method');
		end
		
		% apply power normalization again
		code = sign(code) .* sqrt(abs(code));
		
        par_save(output_file, code, 1); % MATLAB don't allow to save inside parfor loop             
		%change_perm(output_file);
		
		clear code;
        
    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s, %s, %s, %d, %d, %d, %d, %d). Elapsed time: %s', mfilename, proj_name, exp_ann, sift_algo, num2str(param), codebook_size, dimred, spm, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);
	
    %toc
    quit;

end