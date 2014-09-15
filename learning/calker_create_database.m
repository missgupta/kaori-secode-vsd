function calker_create_database(prms, ker, pat_list, pat_name)

common_dir = sprintf('%s/%s/metadata/common', prms.proj_dir, prms.proj_name);
calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', prms.proj_dir, prms.proj_name, prms.exp_name, ker.feat, ker.suffix);
calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', prms.proj_dir, prms.proj_name, prms.exp_name, ker.feat);
if ~exist(calker_common_exp_dir, 'file'),
	mkdir(calker_common_exp_dir);
end

skip_exist = 1;
	
db_file = fullfile(calker_common_exp_dir, ['database_' pat_name '.mat']);
if skip_exist && exist(db_file, 'file'),
	fprintf('File [%s] already exist! skip!\n', db_file);
	return;
end

fprintf('creating the database...\n');

database = struct;


database.cname = {}; % name of each video
database.labels = struct;
database.path = {}; % contain the pathes for each image of each class
database.video = []; % video index for each segment

for pat_ = pat_list,
    pat = pat_{:};
	
	%[ shots, shot_infos, v_infos, v_paths ] = vsd_load_shots('keyframe-5', pat);
	org_proj_dir = sprintf('%s/%s', prms.org_root_dir, prms.org_proj_name);
	[ shots, shot_infos, v_infos, v_paths, keyframes ] = vsd_load_shots_2014( org_proj_dir, prms.seg_name, pat );
			
	for ii = 1:length(shots),
		shot_id = shots{ii};

		splits = regexp(shot_id, '\.', 'split');
		
		video_id = splits{1};

		fprintf('Processing [%d/%d] videos...\n', ii, length(shots));
		database.cname{end+1} = shot_id;        

		c_path = sprintf('%s/%s/feature/%s/%s/%s/%s/%s.mat',...
			prms.proj_dir, prms.proj_name, prms.seg_name, ker.feat_raw, pat, video_id, shot_id);                  
		
		database.path{end+1} = c_path;

	end
end

database.num_shot = length(database.cname);

ann_dir = sprintf('%s/%s/annotation/%s/%s', ...
			prms.org_root_dir, prms.org_proj_name, prms.seg_name, prms.exp_name);
			
%% no annotation dir for this pat_name, means this is a test patition	
if strfind(pat_name, 'devel'),
	for jj = 1:length(ker.events),
		event = ker.events{jj};
		
		%label = -1*ones(1, length(shots));
		label = zeros(1, length(database.cname));
		
		pos_ann_file = sprintf('%s/%s.pos.ann', ann_dir, event); 	% label 1
		
		pos_shots = load_shot_ann(pos_ann_file);
		
		neg_ann_file = sprintf('%s/%s.neg.ann', ann_dir, event); 	% label 1
		
		neg_shots = load_shot_ann(neg_ann_file);
		
		pos_idx = find(ismember(database.cname, pos_shots));
		
		neg_idx = find(ismember(database.cname, neg_shots));
		
		label(pos_idx) = 1;
		
		label(neg_idx) = -1;
		
		database.labels.(event) = label;
	end	
end

	disp('done!');
	save(db_file, 'database');
	clear database;
		
end

function pos_shots = load_shot_ann(ann_file)
	fh = fopen(ann_file, 'r');
	
	infos = textscan(fh, '%s %*q %s %*q %s %*q %s', 'delimiter', ' #$# ', 'MultipleDelimsAsOne', 1 );
	
	pos_shots = infos{2};
	
	fclose(fh);
end

function log (ker, msg)
	fh = fopen(sprintf('%s/%s.log', ker.log_dir, mfilename), 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

