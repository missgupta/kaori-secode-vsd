function [ output_args ] = convert_feature( shot_ann, run, pat, norm_type, feat_dim )
%CONVERT_FEATURE Summary of this function goes here
%   Detailed explanation goes here
    fea_dir = ['/net/per610a/export/das11f/plsang/vsd2013/feature/', shot_ann];
	
	out_fea_dir = ['/net/sfv215/export/raid6/ledduy/mediaeval-2013/feature/', shot_ann];
	
	feat_fmt = 'sparse';
    %run = 'densetrajectory.mbh.Soft-1000-VL2.MBH.trecvidmed10.devel.vq';
    %pat = 'devel';
    %norm_type = 'l1';
    
	if ~exist('norm_type', 'var'),
		norm_type = 'l2';
	end
	
	if ~exist('feat_dim', 'var'),
		feat_dim = 4000;
	end
	
    tmp_dir = sprintf('/net/per610a/export/das11f/plsang/tmp/%s', run);
    if ~exist(tmp_dir, 'file'),
        mkdir(tmp_dir);
    end

    output_run = [run, '.', norm_type];
    
    if ~exist([out_fea_dir, '/', output_run, '/', pat], 'file'),
        mkdir([out_fea_dir, '/', output_run, '/', pat]);
    end
    
    videolst = ['/net/sfv215/export/raid6/ledduy/mediaeval-2013/metadata/', shot_ann, '/', pat, '.lst'];
	
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    
    videos = infos{1};
    
    pats = infos{3};
    
	%blanklst = sprintf('%s/%s/blanklist.lst', out_fea_dir, output_run);
	
    for ii = 1:length(videos),
        video = videos{ii};
        pat = pats{ii};
		
        mfile = ['/net/sfv215/export/raid6/ledduy/mediaeval-2013/metadata/', shot_ann, '/', pat, '/', video, '.prgz'];
       
        fh = fopen(mfile);
		if ~isempty(strfind(shot_ann, 'keyframe')),	%keyframe
			mfile = ['/net/sfv215/export/raid6/ledduy/mediaeval-2013/metadata/', shot_ann, '/', pat, '/', video, '.prg'];
			shots = textread(mfile, '%s');
		elseif isempty(strfind(shot_ann, 'sub')),
			segments = textscan(fh, '%s %*q %s');
			shots = segments{2};
		else
			segments = textscan(fh, '%s %*q %s %*q %s');
			%shots = segments{2};
			shots = segments{3};
		end
				
        fclose(fh);
        
        tmp_file = sprintf('%s/%s.%s', tmp_dir, video, output_run);
        tar_file = sprintf('%s/%s/%s/%s.%s.tar.gz', out_fea_dir, output_run, pat, video, output_run);
		
		if exist(tar_file, 'file'),
			fprintf('File [%s] already exist! skipped!\n', tar_file);
			continue;
		end
    
        fh = fopen(tmp_file, 'w');
        if fh == -1,
           error('can''t open file for writing [%s]\n', tmp_file);
        end
           
        fprintf(fh, '%% BoW-tf feature, %d keyframes\n', length(shots));
            
		fprintf('\n-- [%d/%d] Converting for video %s [%d shots]...\n', ii, length(videos), video, length(shots));
		
        for jj =1:length(shots),
            shot = shots{jj};
            
			if mod(jj, 100) == 0,
				fprintf('%d ', jj);
			end
            fea_file = sprintf('%s/%s/%s/%s/%s.mat', fea_dir, run, pat, video, shot);
			if ~exist(fea_file),
				warning('File [%s] does not exist!!\n', fea_file);
				
				code = zeros(feat_dim, 1);
			else
				code = load(fea_file, 'code');
				code = code.code;
				
				%% TODO: fix this stupid code
				if size(code, 1) ~= feat_dim,
					code = zeros(feat_dim, 1);
				end
			end
            
			if ~all(code == 0)
				% normalization
				if strcmp(norm_type, 'l1')
					code = code / norm(code,1);
				end
				
				if strcmp(norm_type, 'l2')
					code = code / norm(code,2);
				end
            else
				warning('Shot [%s] contains all zero features...\n', shot);
				%f_blank = fopen(blanklst, 'a');
				%fprintf(f_blank, '%s #$# %s #$# %s\n', pat, video, shot);
				%fclose(f_blank);
			end
			
            code = code';
            
			if strcmp(feat_fmt, 'sparse'),
				idx = find(code ~= 0);
				fprintf(fh, '%d ', length(idx));
				if length(idx) > 0,
					out_code = [idx; code(idx)];
					fprintf(fh, '%d %f ', out_code);
				end
				szAnn = sprintf('%% %s %s %s', pat, video, shot); 
				fprintf(fh, '%s\n', szAnn);
			else
				fprintf(fh, '%d ', size(code, 2));
				fprintf(fh, '%f ', code);
				szAnn = sprintf('%% %s %s %s', pat, video, shot); 
				fprintf(fh, '%s\n', szAnn);
			end
             
        end
        
        fclose(fh);
        
        fprintf('\nCompressing %s ...\n', tar_file);
        tar(tar_file, tmp_file);

        delete(tmp_file);
    
    end
	
	
end

