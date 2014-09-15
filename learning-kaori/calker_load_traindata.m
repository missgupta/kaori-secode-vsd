
function [hists, sel_feat] = calker_load_traindata(proj_name, exp_name, ker)

%%Update change parameter to ker
% load database

	set_env;
	configs = set_global_config();
	logfile = sprintf('%s/%s.log', configs.logdir, mfilename);
	msg = sprintf('Start running %s(%s, %s)', mfilename, proj_name, exp_name);
	logmsg(logfile, msg);
	change_perm(logfile);
	tic;
	
calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);

traindb_file = fullfile(calker_exp_dir, 'metadata', 'traindb.mat');

dev_db_file = sprintf('database_%s.mat', ker.dev_pat);

db_file = fullfile(calker_common_exp_dir, dev_db_file);

database = load(db_file, 'database');
database = database.database;

hists = zeros(ker.num_dim, database.num_shot);
selected_idx = zeros(1, database.num_shot);

%%%%  load kaori-secode features
kaori_feats = struct;
meta_file = sprintf('/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014/metadata/keyframe-5/%s.lst', ker.dev_pat);
fh = fopen(meta_file, 'r');
infos = textscan(fh, '%s %*q %s %*q %s', 'delimiter', ' #$# ', 'MultipleDelimsAsOne', 1 );
fclose(fh);
video_ids = infos{1};
pat_ids = infos{2};

for ii = 1:length(video_ids),
	fprintf('%d/%d ', ii, length(video_ids));
	video_id = video_ids{ii};
	pat_id = pat_ids{ii};
	feat_file = sprintf('/net/per610a/export/das11f/ledduy/mediaeval-vsd-2014/feature/keyframe-5/%s/%s/%s.%s.tar.gz', ker.feat_raw, pat_id, video_id, ker.feat_raw);
	if ~exist(feat_file),
		error('File [%s] does not exist!\n', feat_file);
	end
	cur_feats = load_feature_sparse(feat_file, 1000);
	kaori_feats = [fieldnames(kaori_feats)' fieldnames(cur_feats)'; struct2cell(kaori_feats)' struct2cell(cur_feats)'];
	kaori_feats = struct(kaori_feats{:});
end
	
%%%%

for ii = 1:database.num_shot, %

	if ~mod(ii, 100),
		fprintf('%d ', ii);
	end
	
	shot_id = database.cname{ii};
	new_shot_id = strrep(shot_id, '.', '_');
	
	code = kaori_feats.(new_shot_id);
	
	if size(code, 1) ~= ker.num_dim,
		warning('Dimension mismatch [%d-%d-%s]. Skipped !!\n', size(code, 1), ker.num_dim, shot_id);
		size(code);
		continue;
	end
	
	if any(isnan(code)),
		warning('Feature contains NaN [%s]. Skipped !!\n', shot_id);
		msg = sprintf('Feature contains NaN [%s]', shot_id);
		logmsg(logfile, msg);
		continue;
	end
	
	% event video contains all zeros --> skip, keep backgroud video
	if all(code == 0),
		warning('Feature contains all zeros [%s]. Skipped !!\n', shot_id);
		msg = sprintf('Feature contains all zeros [%s]', shot_id);
		logmsg(logfile, msg);
		continue;
	end
	
	if ~all(code == 0),
		if strcmp(ker.feat_norm, 'l1'),
			code = code / norm(code, 1);
		elseif strcmp(ker.feat_norm, 'l2'),
			code = code / norm(code, 2);
		else
			error('unknown norm!\n');
		end
    end
	
	hists(:, ii) =  code;
	selected_idx(ii) = 1;
	
end

sel_feat = selected_idx ~= 0;
%hists = hists(:, sel_feat);

	elapsed = toc;
	elapsed_str = datestr(datenum(0,0,0,0,0,elapsed),'HH:MM:SS');
	msg = sprintf('Finish running %s(%s, %s, %s). Elapsed time: %s', mfilename, proj_name, exp_name, elapsed_str);
	logmsg(logfile, msg);

end
