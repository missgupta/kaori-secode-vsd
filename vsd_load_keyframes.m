function [ list_keyframes, list_videos, list_pats ] = vsd_load_keyframes( kf_name, szPat )
%LOAD_SEGMENTS Summary of this function goes here
%   Detailed explanation goes here
    
	metadata_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/metadata';
	
	%videolst = sprintf('/net/sfv215/export/raid6/ledduy/mediaeval-2013/metadata/%s/%s.lst', kf_name, szPat);
	videolst = sprintf('%s/%s/%s.lst', metadata_dir, kf_name, szPat);
	
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    
    videos = infos{1};
    
    pats = infos{3};
    
    list_keyframes = {};
	list_videos = {};
	list_pats = {};
	
	%v_paths = struct;
	
	fprintf('Loading keyframe list for [%s - %s]...\n', kf_name, szPat);
	
    for ii = 1:length(videos),
        video = videos{ii};
        pat = pats{ii};
        mfile = sprintf('%s/%s/%s/%s.prg', metadata_dir, kf_name, pat, video);
       
        fh = fopen(mfile);
		
		%v_paths.(video) = sprintf('%s/%s.mpg', pat, strtrim(video_name));
		
        this_keyframes = textscan(fh, '%s');
        this_videos = repmat(videos(ii), length(this_keyframes{1}), 1);
		this_pats = repmat(pats(ii), length(this_keyframes{1}), 1);
		
        list_keyframes = [list_keyframes; this_keyframes{1}];
		list_videos = [list_videos; this_videos];
		list_pats = [list_pats; this_pats];
		
        fclose(fh);
    end
	
end

