function [ code ] = densetraj_extract_and_encode( video_file, start_frame, end_frame, descriptor, codebook, kdtree, enc_type )
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here

    % densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_FULL';
	% densetraj = '/net/per900a/raid0/plsang/software/dense_trajectory_release_v1.1/release/DenseTrack';
	densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack';  % same with DenseTrack_FULL
	
    % Set up the mpeg audio decode command as a readable stream
    cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];

    % open pipe
    p = popenr(cmd);

    if p < 0
      error(['Error running popenr(', cmd,')']);
    end

	switch descriptor,
		case 'trajshape'
			start_idx = 8;
			end_idx = 37;
		case 'hog'
			start_idx = 38;
			end_idx = 133;
		case 'hof'
			start_idx = 134;
			end_idx = 241;
		case 'mbh'
			start_idx = 242;
			end_idx = 433;
		case 'full'
			start_idx = 8;
			end_idx = 433;
		otherwise
			error('Unknown descriptor for dense trajectories!!\n');
	end
	
	feat_dim = end_idx - start_idx + 1;
	full_dim = 433;		
	
    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    %listSize = BLOCK_SIZE;                      % current list capacity
    X = zeros(feat_dim, BLOCK_SIZE);
    listPtr = 1;
    
    %tic

    code = zeros(size(codebook, 2), 1);
    
    while true,

      % Get the next chunk of data from the process
      Y = popenr(p, full_dim, 'float');
	  
      if isempty(Y), break; end;

	  if length(Y) ~= full_dim,
			msg = ['wrong dimension [', num2str(length(Y)), '] when running [', cmd, '] at ', datestr(now)];
			log(msg);
			continue;                                    
	  end
	  
      %X = [X Y(8:end)]; % discard first 7 elements
      X(:, listPtr) = Y(start_idx:end_idx);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
          % encode
          if strcmp(enc_type, 'vq'),        
                code_ = vq_encode(X, codebook, kdtree);
          elseif strcmp(enc_type, 'kcb'),        
                code_ = kcb_encode(X, codebook, kdtree);
          end
          
          code = code + code_;
          
          listPtr = 1;
          X(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X(:, listPtr:end) = [];   % remove unused slots
        
        if strcmp(enc_type, 'vq'),        
            code_ = vqencode(X, codebook, kdtree);
        elseif strcmp(enc_type, 'kcb'),        
            code_ = kcbencode(X, codebook, kdtree);
        end
        
        code = code + code_;
    end
    
    % Close pipe
    popenr(p, -1);

end


function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/densetraj_extract_and_encode.log', 'a+');
	fprintf(fh, [msg, '\n']);
	fclose(fh);
end
