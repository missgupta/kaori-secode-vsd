function calker_create_database(proj_name, exp_name, seg_name, ker)

common_dir = sprintf('%s/%s/metadata/common', ker.proj_dir, proj_name);
calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
calker_common_exp_dir = sprintf('%s/%s/experiments/%s-calker/common/%s', ker.proj_dir, proj_name, exp_name, ker.feat);
if ~exist(calker_common_exp_dir, 'file'),
	mkdir(calker_common_exp_dir);
end


pats = [{'devel2013'} {'test2013'}];

% load event list
events = ker.events;
% create db for dev part

skip_exist = 0;
use_ps_video_only = 1; % only use pre-specified videos, discard ad-hoc videos

pattern = '(?<video>VSD\d+_\d+).shot\d+_\d+';
	
for pat_ = pats,
    pat = pat_{:};
    
    db_file = fullfile(calker_common_exp_dir, ['database_' pat '.mat']);
	if exist(db_file, 'file'),
		fprintf('File [%s] already exist! skip!\n', db_file);
		continue;
	end
	
	[ shots, shot_infos, v_infos, v_paths ] = vsd_load_shots('keyframe-5', pat);
    
    if skip_exist && exist(db_file,'file')~=0,
        fprintf('Skipped creating db [%s]!!\n', db_file);
    else
        
        fprintf('creating the database...');

        database = struct;

        
        database.cname = {}; % name of each video
		database.labels = struct;
        database.path = {}; % contain the pathes for each image of each class
        database.video = []; % video index for each segment
		database.num_shot = length(shots);
		
        for ii = 1:length(shots),
            shot_id = shots{ii};

			info = regexp(shot_id, pattern, 'names');
        
			video_id = info.video;
	
            fprintf('Processing [%d/%d] videos...\n', ii, length(shots));
            database.cname{ii} = shot_id;        

          	c_path = sprintf('%s/%s/feature/%s/%s/%s/%s/%s.mat',...
				ker.proj_dir, proj_name, seg_name, ker.feat_raw, pat, video_id, shot_id);                  
			
            database.path = [database.path, c_path];

        end;
	
		%ann_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/annotation/keyframe-5/vsd13-dev2013-Shot-0.8';
		ann_dir = '/net/per610a/export/das11f/ledduy/mediaeval-vsd-2013/annotation/keyframe-5/vsd13-dev2013-Shot-Audios-0.8';
		
        for jj = 1:length(events),
            event = events{jj};
			
			pos_ann_file = sprintf('%s/%s.pos.ann', ann_dir, event); 	% label 1
			
			pos_shots = load_shot_ann(pos_ann_file);
			
			neg_ann_file = sprintf('%s/%s.neg.ann', ann_dir, event); 	% label 1
			
			neg_shots = load_shot_ann(neg_ann_file);
		    
			label = -1*ones(1, length(shots));
			
			pos_idx = find(ismember(shots, pos_shots));
			
			label(pos_idx) = 1;
            
			database.labels.(event) = label;
        end
		
        disp('done!');
        
        save(db_file, 'database');
        clear database;
    end
end

end

function pos_shots = load_shot_ann(ann_file)
	fh = fopen(ann_file, 'r');
	
	infos = textscan(fh, '%s %s %s %s', 'delimiter', ' #$# ', 'MultipleDelimsAsOne', 1 );
	
	pos_shots = infos{2};
	
	fclose(fh);
end

function label = getlabel(vid, videos)

	label = 0;
	for ii = 1:length(videos),
		%% BUG found when using strfind or findstr which will find the first inclusion string
		% if(size(cell2mat(strfind(videos{ii}, vid))) ~= 0),
		%	label = ii;
		% end
		
		if strmatch(vid, videos{ii}, 'exact'),
			label = ii;
		end
	end
	
	if label == 0,
		label = length(videos) + 1; % background label
	end
end

function log (ker, msg)
	fh = fopen(sprintf('%s/%s.log', ker.log_dir, mfilename), 'a+');
    msg = [msg, ' at ', datestr(now), '\n'];
	fprintf(fh, msg);
	fclose(fh);
end

