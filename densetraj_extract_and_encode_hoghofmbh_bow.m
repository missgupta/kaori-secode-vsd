function [code_hoghof, code_mbh] = densetraj_extract_and_encode_hoghofmbh_bow( video_file, codebook_hoghof, kdtree_hoghof, codebook_mbh, kdtree_mbh, start_frame, end_frame)
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here
	
	set_env;

	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	change_perm(logfile);
	
	densetraj = 'LD_PRELOAD=/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so /net/per900a/raid0/plsang/tools/improved_trajectory_release_vsd/release/DenseTrackStab_HOGHOFMBH';
	
	%% fisher initialization
	
    % Set up the mpeg audio decode command as a readable stream
	% cmd = [densetraj, ' ', video_file];
	cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];

    % open pipe
    p = popenr(cmd);

    if p < 0
		error(['Error running popenr(', cmd,')']);
    end
	
	start_idx_hoghof = 1;
	end_idx_hoghof = 204;
	
	start_idx_mbh = 205;
	end_idx_mbh = 396;
	
	hoghof_dim = 204;
	mbh_dim = 192;
	full_dim = 396;		
	
    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    %listSize = BLOCK_SIZE;                      % current list capacity
	X_HOGHOF = zeros(hoghof_dim, BLOCK_SIZE);
	X_MBH = zeros(mbh_dim, BLOCK_SIZE);
    %X = zeros(full_dim, BLOCK_SIZE);
    listPtr = 1;
    
    %tic
    code_hoghof = zeros(size(codebook_hoghof, 2), 1);
	code_mbh = zeros(size(codebook_mbh, 2), 1);
	
    while true,

      % Get the next chunk of data from the process
      Y = popenr(p, full_dim, 'float');
	  
      if isempty(Y), break; end;

	  if length(Y) ~= full_dim,
			msg = ['wrong dimension [', num2str(length(Y)), '] when running [', cmd, '] at ', datestr(now)];
			logmsg(logfile, msg);
			continue;                                    
	  end
	  
      %X = [X Y(8:end)]; % discard first 7 elements
      %X(:, listPtr) = Y(start_idx:end_idx);
	  X_HOGHOF(:, listPtr) = Y(start_idx_hoghof:end_idx_hoghof);
	  X_MBH(:, listPtr) = Y(start_idx_mbh:end_idx_mbh);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
               
		code_hoghof_ = kcb_encode(X_HOGHOF, codebook_hoghof, kdtree_hoghof);
		code_mbh_ = kcb_encode(X_MBH, codebook_mbh, kdtree_mbh);
			 
		code_hoghof = code_hoghof + code_hoghof_;
		code_mbh = code_mbh + code_mbh_;
		
		listPtr = 1;
	    X_HOGHOF(:,:) = 0;
		X_MBH(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X_HOGHOF(:, listPtr:end) = [];   % remove unused slots
		
		X_MBH(:, listPtr:end) = [];   % remove unused slots
        
		code_hoghof_ = kcb_encode(X_HOGHOF, codebook_hoghof, kdtree_hoghof);
		code_mbh_ = kcb_encode(X_MBH, codebook_mbh, kdtree_mbh);
			 
		code_hoghof = code_hoghof + code_hoghof_;
		code_mbh = code_mbh + code_mbh_;
		
    end
    
    popenr(p, -1);

end
