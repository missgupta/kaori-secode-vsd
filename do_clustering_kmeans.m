function codebook = do_clustering_kmeans(proj_dir, feat_pat, num_features, cluster_count, app_kmeans)
%DO_CLUSTERING Summary of this function goes here
%   Detailed explanation goes here
	
	set_env;
	
	%proj_dir = '/net/per610a/export/das11f/plsang';
	proj_name = 'vsd2014';
	
	if ~exist('num_features', 'var'),
		num_features = 1000000;
	end
	
	if ~exist('cluster_count', 'var'),
		cluster_count = 1000;
	end
	
	if ~exist ('app_kmeans', 'var'),
		app_kmeans = 0;
	end
	
	
	output_file = sprintf('%s/%s/feature/bow.codebook.devel/%s/data/codebook.kmeans.%d.mat', ...
		proj_dir, proj_name, feat_pat, cluster_count);
		
	if exist(output_file),
		fprintf('File [%s] already exist. skipped!\n', output_file);
		return;
	end
	
	f_selected_feats = sprintf('%s/%s/feature/bow.codebook.devel/%s/data/selected_feats_%d.mat', ...
		proj_dir, proj_name, feat_pat, num_features);
		
	if ~exist(f_selected_feats, 'file'),
		error('File %s not found!\n', f_selected_feats);
	end
	
	load(f_selected_feats, 'feats');

	feats = single(feats);
	
    if app_kmeans == 1,
		maxcomps = ceil(cluster_count/4);	
        codebook = featpipem.lib.annkmeans(feats, cluster_count, ...
        'verbose', true, 'MaxNumComparisons', maxcomps, ...
        'MaxNumIterations', 150);
    else
        codebook = vl_kmeans(feats, cluster_count, ...
        'verbose', 'algorithm', 'elkan');
    end
	
	fprintf('Done training codebook!\n');
    save(output_file, 'codebook', '-v7.3'); 
    
end

