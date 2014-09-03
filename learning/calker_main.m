function calker_main(feature_ext, feat_dim, ker_type, start_event, end_event)

addpath('/net/per900a/raid0/plsang/tools/kaori-secode-calker-vsd2013/support');
addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');
addpath('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox');
addpath('/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013');

% run vl_setup with no prefix
% vl_setup('noprefix');
vl_setup;

proj_name = 'vsd2014';
exp_name = 'mediaeval-vsd-2014.devel2013-new';
seg_name = 'keyframe-5';

events = {'objviolentscenes', 'subjviolentscenes'};
%events = {'explosion', 'gunshot', 'scream'};

if ~exist('suffix', 'var'),
	suffix = '--calker-vsd2013-nocv';
end

if ~exist('feat_dim', 'var'),
	feat_dim = 4000;
end

if ~exist('ker_type', 'var'),
	ker_type = 'kl2';
end

if ~exist('cross', 'var'),
	cross = 0;
end

if ~exist('open_pool', 'var'),
	open_pool = 0;
end

% if isempty(strfind(suffix, '-vsd2013')),
	% error('**** Suffix does not contain vsd2013 !!!!!\n');
% end

ker = calker_build_kerdb(feature_ext, ker_type, feat_dim, cross, suffix);

ker.events = events;
ker.dev_pat = 'devel2013';
ker.test_pat = 'test2013';

calker_exp_dir = sprintf('%s/%s/experiments/%s-calker/%s%s', ker.proj_dir, proj_name, exp_name, ker.feat, ker.suffix);
ker.log_dir = fullfile(calker_exp_dir, 'log');
 
%if ~exist(calker_exp_dir, 'file'),
mkdir(calker_exp_dir);
mkdir(fullfile(calker_exp_dir, 'metadata'));
mkdir(fullfile(calker_exp_dir, 'kernels'));
mkdir(fullfile(calker_exp_dir, 'kernels', ker.dev_pat));
mkdir(fullfile(calker_exp_dir, 'kernels', ker.test_pat));
mkdir(fullfile(calker_exp_dir, 'scores'));
mkdir(fullfile(calker_exp_dir, 'scores', ker.test_pat));
mkdir(fullfile(calker_exp_dir, 'models'));
mkdir(fullfile(calker_exp_dir, 'log'));
%end

calker_create_database(proj_name, exp_name, seg_name, ker);
calker_create_traindb(proj_name, exp_name, ker);

%open pool
if matlabpool('size') == 0 && open_pool > 0, matlabpool(open_pool); end;
%calker_cal_train_kernel(proj_name, exp_name, ker);
%calker_train_kernel(proj_name, exp_name, ker, events);

%calker_cal_test_kernel(proj_name, exp_name, ker);
%calker_test_kernel(proj_name, exp_name, ker, events);
%calker_cal_rank(proj_name, exp_name, ker, events);
%calker_cal_map(proj_name, exp_name, ker, events);

%close pool
if matlabpool('size') > 0, matlabpool close; end;
