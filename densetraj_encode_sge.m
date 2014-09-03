function [ output_args ] = densetraj_encode_sge( proj_name, shot_ann, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    % encoding method: fisher vector
	% representation: video-based, (can be extended to segment level)
	% power normalization, which one is the best? alpha = 0.2? 
	
    % setting
    set_env;
	dimred = 128;
	root_proj = '/net/per610a/export/das11f/plsang';
	
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s, %d, %d)', mfilename, proj_name, shot_ann, start_seg, end_seg);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
    video_dir = sprintf('%s/%s/video-rsz', root_proj, proj_name);
	
	fea_dir = sprintf('%s/%s/feature', root_proj, proj_name);
	
	codebook_gmm_size = 256;
    
	feature_ext_fc = sprintf('idensetraj.hoghofmbh.cb%d.fc', codebook_gmm_size);
	if dimred > 0,
		feature_ext_fc = sprintf('idensetraj.hoghofmbh.cb%d.fc.pca', codebook_gmm_size);
	end

    output_dir_fc = sprintf('%s/%s/%s', fea_dir, shot_ann, feature_ext_fc);
	
    if ~exist(output_dir_fc, 'file'),
        mkdir(output_dir_fc);
		change_perm(output_dir_fc);
    end
	
	% loading gmm codebook
	
	codebook_hoghof_file = sprintf('%s/%s/feature/bow.codebook.devel/idensetraj.hoghof/data/codebook.gmm.%d.%d.mat', root_proj, proj_name, codebook_gmm_size, dimred);
	low_proj_hoghof_file = sprintf('%s/%s/feature/bow.codebook.devel/idensetraj.hoghof/data/lowproj.%d.%d.mat', root_proj, proj_name, dimred, 204);
	
	codebook_mbh_file = sprintf('%s/%s/feature/bow.codebook.devel/idensetraj.mbh/data/codebook.gmm.%d.%d.mat', root_proj, proj_name, codebook_gmm_size, dimred);
	low_proj_mbh_file = sprintf('%s/%s/feature/bow.codebook.devel/idensetraj.mbh/data/lowproj.%d.%d.mat', root_proj, proj_name, dimred, 192);

	codebook_hoghof_ = load(codebook_hoghof_file, 'codebook');
    codebook_hoghof = codebook_hoghof_.codebook;
	
	codebook_mbh_ = load(codebook_mbh_file, 'codebook');
    codebook_mbh = codebook_mbh_.codebook;
	
	low_proj_hoghof_ = load(low_proj_hoghof_file, 'low_proj');
	low_proj_hoghof = low_proj_hoghof_.low_proj;
	
	low_proj_mbh_ = load(low_proj_mbh_file, 'low_proj');
	low_proj_mbh = low_proj_mbh_.low_proj;
	
	%%%%% Load shot info
	meta_file = '/net/per610a/export/das11f/plsang/vsd2014/metadata/vsd_infos.mat';
	fprintf('Loading meta file [%s] ...!!\n', meta_file);
	load(meta_file, 'vsd_infos');
	%%%%% Load shot info
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(vsd_infos.shots),
        end_seg = length(vsd_infos.shots);
    end
 
    for ii = start_seg:end_seg,
	
		shot_id = vsd_infos.shots{ii};
		splits = regexp(shot_id, '\.', 'split');
		video_id = splits{1};
		splits = regexp(video_id, '_', 'split');
		pat_id = splits{2};
		
		if ~isfield(vsd_infos.v_paths, video_id),
			msg = sprintf('Video <%s> does not exist in keyframes struct\n', video_id); 
			logmsg(logfile, msg);
			continue;
		end
		
		video_file = fullfile(video_dir, vsd_infos.v_paths.(video_id));
		
		start_frame = vsd_infos.shot_infos(ii, 1);
        end_frame = vsd_infos.shot_infos(ii, 2);
		
		output_file = sprintf('%s/%s/%s/%s.mat', output_dir_fc, pat_id, video_id, shot_id);
		
		fprintf(' [%d --> %d --> %d] Extracting & Encoding for video [%s], shot [%s] ...\n', start_seg, ii, end_seg, video_id, shot_id);
		
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
        [code_hoghof, code_mbh] = densetraj_extract_and_encode_hoghofmbh(video_file, codebook_hoghof, low_proj_hoghof, codebook_mbh, low_proj_mbh, start_frame, end_frame); %important
        
		code = [code_hoghof; code_mbh];
		
		par_save(output_file, code, 1); 	
		%change_perm(output_file);
		

    end
    
	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s, %d, %d). Elapsed time: %s', mfilename, proj_name, shot_ann, start_seg, end_seg, elapsed_str);
	logmsg(logfile, msg);

	%toc
	quit;
end

