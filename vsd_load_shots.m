function [ segments, segment_infos, v_infos, v_paths ] = vsd_load_shots( shot_ann, szPat )
%LOAD_SEGMENTS Summary of this function goes here
%   Detailed explanation goes here
    
	videolst = sprintf('/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/metadata/%s/%s.lst', shot_ann, szPat);
	
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    
    videos = infos{1};
    
    pats = infos{3};
    
    segments = [];
	starts = [];
	lengths = [];
	
	v_paths = struct;
	
    for ii = 1:length(videos),
        video = videos{ii};
        pat = pats{ii};
        mfile = sprintf('/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/SBfiles/%s/%s/%s.sb', shot_ann, pat, video);
       
        fh = fopen(mfile);
		video_name=fgets(fh);
		video_id=fgets(fh);
		
		v_paths.(video) = sprintf('%s/%s.mpg', pat, strtrim(video_name));
		
        this_segments = textscan(fh, '%s %*q %d %*q %d');
        
        segments = [segments; this_segments{1}];
		starts = [starts; this_segments{2}];
		lengths = [lengths; this_segments{3}];
        fclose(fh);
    end
	
	%% update: Jul 5, 2013 -- creat infos struct
	v_infos = struct;
	segment_infos = zeros(length(segments), 2);

	pattern='(?<video>VSD\d+_\d+).shot\d+_\d+';
	for ii = 1:length(segments),
		
		segment = segments{ii};    
		info = regexp(segment, pattern, 'names');
		start_frame = starts(ii);
        end_frame = start_frame + lengths(ii) - 1;
		if ~isfield(v_infos, info.video),
			v_infos.(info.video) = [start_frame, end_frame];
		else
			v_infos.(info.video) = [v_infos.(info.video), start_frame, end_frame]; 
		end	
		segment_infos(ii, :) = [start_frame end_frame];
	end
	
end

