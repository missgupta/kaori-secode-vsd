function [ output_args ] = aggregate_image_feature( proj_name, feature_ext, kf_dir_name, szPat, start_seg, end_seg )
%ENCODE Summary of this function goes here
%   Detailed explanation goes here
%% kf_dir_name: name of keyframe folder, e.g. keyframe-60 for segment length of 60s   

	% update: Jun 25th, SPM suported
    % setting
    set_env;

    fea_dir = sprintf('/net/per900a/raid0/plsang/%s/feature/%s', proj_name, kf_dir_name);
    if ~exist(fea_dir, 'file'),
        mkdir(fea_dir);
    end
	
    output_dir = sprintf('%s/%s/%s', fea_dir, feature_ext, szPat) ;
    if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	
	output_kf_feat_dir = sprintf('/net/per900a/raid0/plsang/%s/feature/keyframe-all/%s/%s', proj_name, feature_ext, szPat) ;
	
    [segments, sinfos, vinfos] = load_segments(proj_name, szPat, kf_dir_name);
    
    if ~exist('start_seg', 'var') || start_seg < 1,
        start_seg = 1;
    end
    
    if ~exist('end_seg', 'var') || end_seg > length(segments),
        end_seg = length(segments);
    end
    
    %tic
	
    kf_dir = sprintf('/net/per900a/raid0/plsang/%s/keyframes/%s', proj_name, szPat);
	
    parfor ii = start_seg:end_seg,
        segment = segments{ii};                 
    
        pattern =  '(?<video>\w+)\.\w+\.frame(?<start>\d+)_(?<end>\d+)';
        info = regexp(segment, pattern, 'names');
        
		output_file = [output_dir, '/', info.video, '/', segment, '.mat'];
        if exist(output_file, 'file'),
            fprintf('File [%s] already exist. Skipped!!\n', output_file);
            continue;
        end

        video_kf_dir = fullfile(kf_dir, info.video);
        
        start_frame = str2num(info.start);
        end_frame = str2num(info.end);
        
		kfs = dir([video_kf_dir, '/*.jpg']);
       
		%% update Jul 5, 2013: support segment-based
		max_frames = max(vinfos.(info.video));
		max_keyframes = length(kfs);
		
        start_kf = floor(start_frame*max_keyframes/max_frames) + 1;
		end_kf = floor(end_frame*max_keyframes/max_frames);
		
		fprintf(' [%d --> %d --> %d] Aggregating for [%s - %d/%d kfs (%d - %d)]...\n', start_seg, ii, end_seg, segment, end_kf - start_kf + 1, max_keyframes, start_kf, end_kf);
		
        code = [];
		for jj = start_kf:end_kf,
			if ~mod(jj, 10),
				fprintf('%d ', jj);
			end
			img_name = kfs(jj).name;
			img_path = fullfile(video_kf_dir, img_name);
			
			feat_file = sprintf('%s/%s/%s.%s', output_kf_feat_dir, info.video, img_name(1:end-4), feature_ext);
			if ~exist(feat_file, 'file'),
				warning('File not found! [%s] ', feat_file);
				continue;
			end
			
			descrs = textread(feat_file, '%f');
            if descrs(1) ~= length(descrs(2:end)),
				warning('Dimension mismatch...[%d <> %d]. Skipped!\n', descrs(1), length(descrs(2:end)));
                continue;
			end
			
			descrs = descrs(2:end);
            % if more than 50% of points are empty --> possibley empty image
            if sum(all(descrs == 0, 1)) > 0.5*size(descrs, 2),
                warning('Maybe blank image...[%s]. Skipped!\n', img_name);
                continue;
            end
			
			code = [code descrs];
		end
		fprintf('\n');
		% averaging...
		code = mean(code, 2);
        
		output_vdir = [output_dir, '/', info.video];
        if ~exist(output_vdir, 'file'),
            mkdir(output_vdir);
        end
		
        par_save(output_file, code); % MATLAB don't allow to save inside parfor loop             
        
    end
    
    %toc
    % quit;

end

function par_save( output_file, code )
	save( output_file, 'code');
end

function log (msg)
	fh = fopen('aggregate_image_feature.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

