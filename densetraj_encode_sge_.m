function [ output_args ] = densetraj_encode_sge( descriptor, shot_ann, szPat, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   
   
    %log start
    msg = sprintf('Start runing encode (%s, %s, %s, %d, %d)', descriptor, shot_ann, szPat, start_seg, end_seg );
    log(msg);
    
    % setting
    set_env;
    
    
    video_dir = '/net/per610a/export/das11f/ledduy/plsang/vsd2013/video-rsz';
    
	
    fea_dir = ['/net/per610a/export/das11f/ledduy/plsang/vsd2013/feature/', shot_ann];
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
        
    % encoding type
    enc_type = 'kcb';
    codebook_size = 4000;
    
	feature_ext = sprintf('densetrajectory.%s.Soft-4000-VL2.vsd2013.devel', descriptor);
	
        
    output_dir = sprintf('%s/%s.%s/%s', fea_dir, feature_ext, enc_type, szPat) ;
    if ~exist(output_dir, 'file'),
        mkdir(output_dir);
    end
    
    codebook_file = sprintf('/net/per610a/export/das11f/ledduy/plsang/vsd2013/feature/bow.codebook.devel/densetrajectory.%s/data/codebook.%d.mat', descriptor, codebook_size);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
    
    kdtree = vl_kdtreebuild(codebook);
    
    %segments = load_segments('trecvidmed11', szPat, kf_dir_name);
	[shots, shot_infos, v_infos, v_paths] = vsd_load_shots(shot_ann, szPat);
    
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(shots),
        end_seg = length(shots);
    end
    
    %tic
    pattern='(?<video>VSD\d+_\d+)_shot\d+_\d+';
	
    for ii = start_seg:end_seg,

        shot_id = shots{ii};
		
		info = regexp(shot_id, pattern, 'names');
		
        %log start
        %msg = sprintf(' +++ start encoding for [%s]', segment);
        %log(msg);
    
        
        info = regexp(shot_id, pattern, 'names');
        
        output_file = [output_dir, '/', info.video, '/', shot_id, '.mat'];
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end
        
        video_file = [video_dir, '/', info.video, '.mpg'];
        
        start_frame = shot_infos(ii, 1);
        end_frame = shot_infos(ii, 2);
        
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, shot_id);
        
        code = densetraj_extract_and_encode(video_file, start_frame, end_frame, descriptor, codebook, kdtree, enc_type); %important
        
        % output code
        output_vdir = [output_dir, '/', info.video];
        if ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
        
        par_save(output_file, code); % MATLAB don't allow to save inside parfor loop
              
        %msg = sprintf(' +++ finish encoding for [%s]', segment);
        %log(msg);
        
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
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/densetraj_encode_sge.log', 'a+');
    msg = [msg, ' at ', datestr(now)];
	fprintf(fh, [msg, '\n']);
	fclose(fh);
end

