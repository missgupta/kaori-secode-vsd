
function hists = calker_load_traindata(proj_name, exp_name, ker)

%%Update change parameter to ker
% load database

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);

calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);

traindb_file = fullfile(calker_exp_dir, 'metadata', 'traindb.mat');

dev_db_file = sprintf('database_%s.mat', ker.dev_pat);

db_file = fullfile(calker_common_exp_dir, dev_db_file);

database = load(db_file, 'database');
database = database.database;

hists = zeros(ker.num_dim, database.num_shot);

selected_idx = zeros(1, database.num_shot);

traindb_path = database.path;

min_length = 250; % frames

length(traindb_path)

for ii = 1:length(traindb_path), %

	if ~mod(ii, 100),
		fprintf('%d ', ii);
	end
	
	segment_path = traindb_path{ii};
	
	if ~exist(segment_path),
		warning('File [%s] does not exist!\n', segment_path);
		continue;
	end
	
	code = load(segment_path, 'code');
	code = code.code;
	
	if size(code, 1) ~= ker.num_dim,
		warning('Dimension mismatch [%d-%d-%s]. Skipped !!\n', size(code, 1), ker.num_dim, segment_path);
		size(code)
		continue;
	end
	
	if any(isnan(code)),
		warning('Feature contains NaN [%s]. Skipped !!\n', segment_path);
		msg = sprintf('Feature contains NaN [%s]', segment_path);
		log(msg);
		continue;
	end
	
	% event video contains all zeros --> skip, keep backgroud video
	if all(code == 0),
		warning('Feature contains all zeros [%s]. Skipped !!\n', segment_path);
		msg = sprintf('Feature contains all zeros [%s]', segment_path);
		log(msg);
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
hists = hists(:, sel_feat);

traindb.selected_idx = selected_idx;

events = ker.events;

for ii=1:length(events),
	event = events{ii};
	traindb.labels.(event) = database.labels.(event)(sel_feat);
end

fprintf('Saving training db ...\n');
save(traindb_file, 'traindb');

end

function log (msg)
	fh = fopen('/net/per900a/raid0/plsang/tools/kaori-secode-calker-v3/log/calker_load_traindata.log', 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

