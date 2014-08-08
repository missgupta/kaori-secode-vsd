function [ code, code_pca ] = densetraj_extract_and_encode_fv( video_file, start_frame, end_frame, descriptor, codebook, codebook_pca, low_proj )
%EXTRACT_AND_ENCODE Summary of this function goes here
%   Detailed explanation goes here

	fisher_params.grad_weights = false;		% "soft" BOW
    fisher_params.grad_means = true;		% 1st order
    fisher_params.grad_variances = true;	% 2nd order
    fisher_params.alpha = single(1.0);		% power normalization (set to 1 to disable)
    fisher_params.pnorm = single(0.0);		% norm regularisation (set to 0 to disable)
	
	cpp_handle = mexFisherEncodeHelperSP('init', codebook, fisher_params);
	
	if ~isempty(low_proj),
		cpp_handle_pca = mexFisherEncodeHelperSP('init', codebook_pca, fisher_params);
	end
	
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
          mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
		  
		  if ~isempty(low_proj),	
			mexFisherEncodeHelperSP('accumulate', cpp_handle_pca, single(low_proj * X));
		  end
          
          listPtr = 1;
          X(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X(:, listPtr:end) = [];   % remove unused slots
        
        mexFisherEncodeHelperSP('accumulate', cpp_handle, single(X));
		  
		if ~isempty(low_proj),	
			mexFisherEncodeHelperSP('accumulate', cpp_handle_pca, single(low_proj * X));
		end
    end
    
    % Close pipe
    popenr(p, -1);
	
	code = mexFisherEncodeHelperSP('getfk', cpp_handle);
    code = sign(code) .* sqrt(abs(code));    
	
	mexFisherEncodeHelperSP('clear', cpp_handle);
	
	if ~isempty(low_proj),	
		code_pca = mexFisherEncodeHelperSP('getfk', cpp_handle_pca);
		code_pca = sign(code_pca) .* sqrt(abs(code_pca));    
		
		mexFisherEncodeHelperSP('clear', cpp_handle_pca);
	end

end


function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/log/densetraj_extract_and_encode.log', 'a+');
	fprintf(fh, [msg, '\n']);
	fclose(fh);
end
