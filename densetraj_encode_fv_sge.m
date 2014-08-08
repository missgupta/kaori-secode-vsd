function [ output_args ] = densetraj_encode_fv_sge( descriptor, shot_ann, szPat, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    %log start
    msg = sprintf('Start runing encode (%s, %s, %s, %d, %d)', descriptor, shot_ann, szPat, start_seg, end_seg );
    log(msg);
    
    % setting
    set_env;
    
    
    rsz_video_dir = '/net/per610a/export/das11f/plsang/vsd2013/video-rsz';
    
	
    fea_dir = ['/net/per610a/export/das11f/plsang/vsd2013/feature/', shot_ann];
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
   
	codebook_size = 256;
    raw_feat_dim = 192;
    dimred = 128;
        
	low_proj = [];
	f_low_proj = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.mbh/data/lowproj.%d.%d.mat', dimred, raw_feat_dim);
	if dimred > 0 && exist(f_low_proj, 'file'),
		load(f_low_proj, 'low_proj');
	else
		warning('Not using PCA!\n');
	end
	
	feature_ext = sprintf('densetrajectory.mbh.cb%d.fc', codebook_size);    
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end

	codebook_file = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.gmm.%d.%d.mat', codebook_size, raw_feat_dim);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
    
	codebook_pca = [];
	if ~isempty(low_proj),
		feature_ext_pca = sprintf('densetrajectory.mbh.cb%d.fc.pca', codebook_size);  
		output_dir_pca = sprintf('%s/%s/%s', fea_dir, feature_ext_pca, szPat) ;
		if ~exist(output_dir_pca, 'file'),
			mkdir(output_dir_pca);
		end		
		
		codebook_file_pca = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.mbh/data/codebook.gmm.%d.%d.mat', ...
			codebook_size, size(low_proj, 1));
		codebook_pca_ = load(codebook_file_pca, 'codebook');
		codebook_pca = codebook_pca_.codebook;
	
	end
	
	[shots, shot_infos, v_infos, v_paths] = vsd_load_shots(shot_ann, szPat);
    
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(shots),
        end_seg = length(shots);
    end
    
    %tic
    pattern='(?<video>VSD\d+_\d+).shot\d+_\d+';
	
    for ii = start_seg:end_seg,

        shot_id = shots{ii};
		
        info = regexp(shot_id, pattern, 'names');
        
		video_id = info.video;
		
		video_file = [rsz_video_dir, '/', v_paths.(video_id)];
		
		start_frame = shot_infos(ii, 1);
        end_frame = shot_infos(ii, 2);
		
        output_file = [output_dir, '/', video_id, '/', shot_id, '.mat'];
		output_file_pca = [output_dir_pca, '/', video_id, '/', shot_id, '.mat'];
        if isempty(low_proj) && exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
			
		elseif exist(output_file, 'file') && exist(output_file_pca, 'file') ,
            fprintf('Both file [%s] and [%s] already exist. Skipped!!\n', output_file, output_file_pca);
            continue;
        end
		
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [video: %s] [shot: %s]...\n', start_seg, ii, end_seg, video_id, shot_id);
        
		[code, code_pca] = densetraj_extract_and_encode_fv( video_file, start_frame, end_frame, descriptor, codebook, codebook_pca, low_proj);
                
        % output code
        output_vdir = [output_dir, '/', video_id];
        if ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
        par_save(output_file, code); % MATLAB don't allow to save inside parfor loop
		
		if ~isempty(low_proj),
			output_vdir_pca = [output_dir_pca, '/', video_id];
			if ~exist(output_vdir_pca, 'file'),
				mkdir(output_vdir_pca);
			end
        
			par_save(output_file_pca, code_pca); 
		end
        
    end
    
    %toc
    
    %log end
    msg = sprintf('Finish runing encode (%s, %s, %s, %d, %d)', descriptor, shot_ann, szPat, start_seg, end_seg );
    log(msg);
    
       
    % quit matlab
    quit;

end

function par_save( output_file, code )
	save( output_file, 'code');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/densetraj_encode_fv_sge.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

