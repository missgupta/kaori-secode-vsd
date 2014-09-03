function calker_train_kernel(proj_name, exp_name, ker, events, start_event, end_event)

    test_on_train = 1;
	
	calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

    traindb_file = fullfile(calker_exp_dir, 'metadata', 'traindb.mat');
	
    traindb = load(traindb_file, 'traindb');
	traindb = traindb.traindb;

    % event names
 
    n_event = length(events);

    kerPath = sprintf('%s/kernels/%s/%s', calker_exp_dir, ker.dev_pat, ker.devname);
	
	heu_kerPath = sprintf('%s.heuristic.mat', kerPath);
	fprintf('Loading kernel %s ...\n', heu_kerPath); 
	kernels_ = load(heu_kerPath) ;
	base = kernels_.matrix;
			
	if ~exist('start_event', 'var'),
		start_event = 1;
	end
	
	if ~exist('end_event', 'var'),
		end_event = n_event;
	end
	
	for kk = start_event:end_event,
	
		event_name = events{kk};
	
        modelPath = sprintf('%s/models/%s.%s.%s.model.mat', calker_exp_dir, event_name, ker.name, ker.type);
		
		if checkFile(modelPath),
			fprintf('Skipped training %s \n', modelPath);
			continue;
		end
		
		fprintf('***** Training event ''%s''...\n', event_name);	
		
		labels = double(traindb.labels.(event_name));
		posWeight = ceil(length(find(labels == -1))/length(find(labels == 1)));
		
			
		fprintf('SVM learning with predefined kernel matrix...\n');
		svm = calker_svmkernellearn(base, labels,   ...
						   'type', 'C',        ...
						   'C', 1,            ...
						   'verbosity', 1,     ...
						   ...%'rbf', 1,           ...
						   ...%'crossvalidation', 5, ...
						   'weights', [+1 posWeight ; -1 1]') ;
						   
		if isfield(kernels_, 'mu'),
			gamma = kernels_.mu;
		end
	

		svm = svmflip(svm, labels);

		if strcmp(ker.type, 'echi2'),
			svm.gamma = gamma;
		end
		
		% test it on train
		if test_on_train,		
			
			scores = svm.alphay' * base(svm.svind, :) + svm.b ;
			errs = scores .* labels < 0 ;
			err  = mean(errs) ;
			selPos = find(labels > 0) ;
			selNeg = find(labels < 0) ;
			werr = sum(errs(selPos)) * posWeight + sum(errs(selNeg)) ;
			werr = werr / (length(selPos) * posWeight + length(selNeg)) ;
			fprintf('\tSVM training error: %.2f%% (weighed: %.2f%%).\n', ...
			  err*100, werr*100) ;
			  
			% save model
			fprintf('\tNumber of support vectors: %d\n', length(svm.svind)) ;
			%clear kernels_;
		end
		
		fprintf('\tSaving model ''%s''.\n', modelPath) ;
		par_save( modelPath, svm );	

	end
	
end

function par_save( modelPath, svm )
	ssave(modelPath, '-STRUCT', 'svm') ;
end
