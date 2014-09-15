function mfcc_extract_features(pat_name, start_video, end_video)
		
	set_env
	
	proj_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014';
	local_proj_dir = '/net/per610a/export/das11f/plsang/vsd2014';
	video_dir = sprintf('%s/video', proj_dir);
	shot_ann = 'keyframe-5';
	vsd_pats = {'devel2011', 'test2011', 'test2012', 'test2013', 'test2014'};
	
	feat_dir = sprintf('%s/feature/%s/mfcc.rastamat.raw', local_proj_dir, shot_ann);
	
	fprintf('Loading shot info for pat <%s>...\n', pat_name);
	
	[shots, shot_infos, v_infos, v_paths] = vsd_load_shots_2014(proj_dir, shot_ann, pat_name);
	
	videos = fieldnames(v_paths);
	
	if start_video < 1,
		start_video = 1;
	end
	
	if end_video > length(videos),
		end_video = length(videos);
	end
	
	for ii=start_video:end_video,
		video_id = videos{ii};
		output_file = sprintf('%s/%s/%s.mat', feat_dir, pat_name, video_id);
		if exist(output_file, 'file'),
			fprintf('File already exist!\n');
			continue;
		end
		video_file = fullfile(video_dir, v_paths.(video_id));
		
		fprintf('[%d-%d-%d] Extracting feature for video <%s>...\n', start_video, ii, end_video, v_paths.(video_id));
		feats = mfcc_extract_features_(video_file);
		
		if ~exist(fileparts(output_file), 'file'),
			mkdir(fileparts(output_file));
		end
		
		fprintf('Saving [%s] ...\n', output_file);
		save(output_file, 'feats', '-v7.3');
	end

end

function feat = mfcc_extract_features_( filepath, toolbox)
%EXTRACT_FEATURES Summary of this function goes here
%   Detailed explanation goes here

	if ~exist('toolbox', 'var'),
		toolbox = 'rastamat';
	end
    
    % Set up the mpeg audio decode command as a readable stream
	
	% mmread path (for reading video info)
	% addpath('/net/per900a/raid0/plsang/tools/mfcc');
	audio_dir = '/net/per610a/export/das11f/plsang/vsd2014/audio';
	
	ffmpeg_bin = '/net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg';
	
	%fprintf('Loading video [%s]...\n', filepath);
	%v_info = mmread(filepath);
	% extract audio part
	
	%%%% to get: ffmpeg -i HVC5787.mp4 2>&1 | sed -n "s/.*Duration: \([^,]*\), .*/\1/p"
	%%%% to get: ffmpeg -i HVC5787.mp4 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p"
	%%%% to getfps=$( ffmpeg -i HVC5787.mp4 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p")
	
	%%% example 1, with duplicate outputs
	%%% /net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i /net/per900a/raid0/plsang/dataset/MED10/HVC1035.mp4 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p"
	%%% example 2, with one output, using sed '0,/pattern/s/pattern/replacement/' filename
	%%% /net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i /net/per900a/raid0/plsang/dataset/MED10/HVC1035.mp4 2>&1 | sed -n "0,/.*, \(.*\) fps.*/s/.*, \(.*\) fps.*/\1/p"
	
	ac_param = 1; % 1 audio output channels, only voicebox and can work with 2 audio channels
	
	[vpath, fname, fext] = fileparts(filepath);
	
	%[~, tmpname] = fileparts(tempname);
	tmp_audio_file = sprintf('%s/%s.wav', audio_dir, fname);
	
	if ~exist(tmp_audio_file, 'file'),
		
		%cmd = sprintf('ffmpeg -ss %s -i %s -t %s -vn -ac 1 -ar 44100 -ab 320k -f wav %s', ss_time, filepath, t_time, tmp_audio_file);
		%%cmd = sprintf('/net/per900a/raid0/plsang/usr.local/ffmpeg-1.2.1/release/bin/ffmpeg -i %s -vn -ac 1 -ar 44100 -ab 320k -f wav %s', filepath, tmp_audio_file);
		
		%%% update Jul 5th, 2013: supported start frame, end frame
		% convert frame to timestamp: hh:mm:ss.ms
		if ~exist('start_frame', 'var') && ~exist('end_frame', 'var'),
			cmd = sprintf('%s -i %s -y -vn -ac %d -ar 48000 -ab 320k -f wav %s', ffmpeg_bin, filepath, ac_param, tmp_audio_file);
		else
			%%% get fps, note: escape \ by \\
			cmd = sprintf('%s -i %s 2>&1 | sed -n "0,/.*, \\(.*\\) fps.*/s/.*, \\(.*\\) fps.*/\\1/p"', ffmpeg_bin, filepath);
			[~, fps] = system(cmd);
			if fps ~= 25,
				warning('FPS is not 25 but %d\n', fps);
			end
			
			ss_time = convert_to_timestamp(start_frame, fps);
			to_time = convert_to_timestamp(end_frame, fps);
			cmd = sprintf('%s -ss %s -i %s -y -to %s -vn -ac %d -ar 48000 -ab 320k -f wav %s', ffmpeg_bin, ss_time, filepath, to_time, ac_param, tmp_audio_file);
		end
		
		fprintf('\n---- Extract audio file for [%s]...\n', filepath);
		system(cmd);
		
		if ~exist(tmp_audio_file),
			msg = sprintf('Failed to extract audio for [%s]', filepath);
			warning(msg);
			log(msg);
			return;
		end
	
	end
	
	fprintf('--- Extracting audio feature for [%s]...\n', filepath);
    %try
        % Read speech samples, sampling rate and precision from file
		fprintf('Reading audio file...\n');
        [ speech, fs, nbits ] = wavread( tmp_audio_file );
			
		if strcmp(toolbox, 'kamil'),		
			Tw = 32;                % analysis frame duration (ms)
			Ts = 16;                % analysis frame shift (ms)
			alpha = 0.97;           % preemphasis coefficient
			M = 20; %40 ;                 % number of filterbank channels, default 20
			C = 12;                 % number of cepstral coefficients
			L = 22;                 % cepstral sine lifter parameter
			LF = 300;               % lower frequency limit (Hz)
			HF = 3700; %6854;              % upper frequency limit (Hz), default 3700
			% Feature extraction (feature vectors as columns)
			feat = mfcc( speech, fs, Tw, Ts, alpha, @hamming, [LF HF], M, C+1, L );
		elseif strcmp(toolbox, 'voicebox'),	
			feat = melcepst(speech , fs, 'e0'); % include log energy, 0th cepstral coef, delta and delta-delta coefs
			%feat = melcepst(speech , fs, 'e0dD'); % include log energy, 0th cepstral coef, delta and delta-delta coefs
			feat = feat';						  % transpose to column vectors;
		elseif strcmp(toolbox, 'rastamat'),
			fprintf('--- Extracting audio feature using rastamat method for [%s]...\n', filepath);
			cep2 = melfcc(speech, fs, 'maxfreq', 3700, 'numcep', 13, 'nbands', 20, 'fbtype', 'fcmel', 'dcttype', 1, 'usecmp', 1, 'wintime', 0.025, 'hoptime', 0.010, 'preemph', 0.97, 'dither', 1);
			del1 = deltas(cep2);
			%del2 = deltas(deltas(cep2,5),5);
			del2 = deltas(deltas(cep2));	% use default w: 9
			% Composite, 39-element feature vector, just like we use for speech recognition
			feat = [cep2;del1;del2];
		end
		
		%removing columns that contain any NaN
		feat = feat(:, ~any(isnan(feat), 1));
		feat = feat(:, ~any(isinf(feat), 1));
    %catch
    %    warning('Wrong format!\n');
    %    feat = [];        
    %end
    	
	%delete(tmp_audio_file);

end


function time_str = convert_to_timestamp(frame_num, frame_rate)
	seconds =  floor(frame_num / frame_rate);
	remaining_frames =  frame_num - round(seconds * frame_rate);
	
	msec = round((remaining_frames / frame_rate) * 1000);
	hh = floor(seconds/3600);
	mm = floor(rem(seconds, 3600)/60);
	ss = rem(seconds, 60);
	
	time_str = sprintf('%d:%d:%d.%d', hh, mm, ss, msec);
	
end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/mfcc_extract_features.log', 'a+');
	fprintf(fh, [msg, '\n']);
	fclose(fh);
end
