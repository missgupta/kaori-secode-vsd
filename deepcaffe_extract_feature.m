function deepcaffe_extract_feature( proj_name, exp_ann, layer_name, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;
	
    % encoding type
    enc_type = 'deepcaffe';
	
	agg_method = 'max'; % sum, max 
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s, %s, %d, %d)', mfilename, proj_name, exp_ann, layer_name, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
    feature_ext_sum = sprintf('%s.%s.sum', enc_type, layer_name);
	feature_ext_max = sprintf('%s.%s.max', enc_type, layer_name);
	

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
    
	output_dir_sum = sprintf('/net/per610a/export/das11f/plsang/%s/feature/%s/%s', proj_name, exp_ann, feature_ext_sum);
    if ~exist(output_dir_sum, 'file'),
		mkdir(output_dir_sum);
		change_perm(output_dir_sum);
    end
    
    output_dir_max = sprintf('/net/per610a/export/das11f/plsang/%s/feature/%s/%s', proj_name, exp_ann, feature_ext_max);
    if ~exist(output_dir_max, 'file'),
		mkdir(output_dir_max);
		change_perm(output_dir_max);
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
		
		output_file_sum = sprintf('%s/%s/%s/%s.mat', output_dir_sum, pat_id, video_id, shot_id);
        
        output_file_max = sprintf('%s/%s/%s/%s.mat', output_dir_max, pat_id, video_id, shot_id);
		
		if exist(output_file_sum, 'file') && exist(output_file_max, 'file'),
            fprintf('File for shot [%s] already exist. Skipped!!\n', shot_id);
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
		
			code_ = matcaffe_extract_feat(img_path, layer_name);
			
			if any(isnan(code_)), 
				msg = sprintf('Image <%s> contains NaN features\n', img_name); 
				logmsg(logfile, msg);
				continue; 
			end
			
			code{jj} = code_;	
			
			clear descrs, code_;
		end 
        
		code = cat(2, code{:});
        		
        code_sum = mean(code, 2);
    
        code_max = max(code, [], 2);
		
        par_save(output_file_sum, code_sum, 1); % MATLAB don't allow to save inside parfor loop             
        
        par_save(output_file_max, code_max, 1); % MATLAB don't allow to save inside parfor loop             
		%change_perm(output_file);
		
		clear code code_sum code_max;
        
    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s, %s, %d, %d). Elapsed time: %s', mfilename, proj_name, exp_ann, layer_name, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);
	
    %toc
    quit;

end