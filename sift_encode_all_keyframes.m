function [ output_args ] = sift_encode_all_keyframes( kf_dir_name, sz_pat, sift_algo, param, codebook_size, enc_type, spm, start_kf, end_kf )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	%Usage:
	%In: 
	%	clustering_algo: kmeans, gmm
	%	dimred: 		 feat dim, default 128, ortherwise using pca
	
	% update: Jun 25th, SPM suported
    % setting
    set_env;
	
    fea_dir = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/%s', kf_dir_name);
    if ~exist(fea_dir, 'file'),
            mkdir(fea_dir);
    end
        
	if ~exist('enc_type', 'var'),
		enc_type = 'soft';
	end
    
	if ~exist('codebook_size', 'var'),
		codebook_size = 4000;
	end
	
	if ~exist('spm', 'var'),
		spm = 0;
	end
	
	feature_ext = sprintf('%s.%s.sift.cb%d.%s', sift_algo, num2str(param), codebook_size, enc_type);
	if spm > 0,
		feature_ext = sprintf('%s.spm', feature_ext);
	end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, sz_pat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
    
    codebook_file = sprintf('/net/per610a/export/das11f/plsang/vsd2013/feature/bow.codebook.devel/%s.%s.sift/data/codebook.kmeans.%d.mat', ...
		sift_algo, num2str(param), codebook_size);
		
	fprintf('Loading codebook [%s]...\n', codebook_file);
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
	
	kdtree = vl_kdtreebuild(codebook);	
	
	[list_keyframes, list_videos ] = vsd_load_keyframes( kf_dir_name, sz_pat );
    
    if ~exist('start_kf', 'var') || start_kf < 1,
        start_kf = 1;
    end
    
    if ~exist('end_kf', 'var') || end_kf > length(list_keyframes),
        end_kf = length(list_keyframes);
    end
    
    %tic
	
    kf_dir = sprintf('/net/sfv215/export/raid6/ledduy/mediaeval-2013/%s/%s', kf_dir_name, sz_pat);
		
    for ii = start_kf:end_kf,
        kf_id = list_keyframes{ii};                 
		vid_id = list_videos{ii};
		
		fprintf(' [%d/%d] Extracting & encoding for keyframe [%s]...\n', ii, end_kf - start_kf + 1, kf_id);
		
		img_path = sprintf('%s/%s/%s.jpg', kf_dir, vid_id, kf_id);
		
		output_video_dir = fullfile(output_dir, vid_id);
		if ~exist(output_video_dir, 'file'),
			mkdir(output_video_dir);
		end
		
		output_file = [output_video_dir, '/', kf_id, '.mat'];
		if exist(output_file, 'file'),
			fprintf('File [%s] already exist. Skipped!!\n', output_file);
			continue;
		end
	
		try
			im = imread(img_path);
		catch
			warning('Error while reading image [%s]!!\n', img_path);
			continue;
		end
		
		[frames, descrs] = sift_extract_features( im, sift_algo, param );
		
		%%if more than 50% of points are empty --> possibley empty image
		%if sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
		%	warning('Maybe blank image...[%s]. Skipped!\n', kf_id);
			%continue;
		%end
		
		if spm > 0
			code = sift_encode_spm(enc_type, size(im), frames, descrs, codebook, kdtree, []);
		else
			code = sift_do_encoding(enc_type, descrs, codebook, kdtree, []);	
		end
		
		par_save(output_file, code); % MATLAB don't allow to save inside parfor loop             
		
		fprintf('\n');
		
    end
    
    %toc
    % quit;

end

function par_save( output_file, code )
  save( output_file, 'code', '-v7.3');
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/sift_encode_all_keyframes.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

