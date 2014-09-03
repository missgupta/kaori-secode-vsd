
function ker = calker_build_kerdb(proj_name, exp_name, feature_ext, ker_type, feat_dim, cross)

% Build kernel database,
% call BuildKerDb('baseline'), or BuildKerDb('baseline', 'dense_sift')...
%

ker.type     = ker_type ;
ker.feat     = feature_ext ;
ker.fea_fmt  = 'dvf';
ker.num_dim = feat_dim; %98304;
ker.pyrLevel = [] ;
ker.histName = [feature_ext '.dev_hists.' ker_type];
ker.testHists = [feature_ext '.test_hists.' ker_type];
ker.name = feature_ext;
ker.resname = [feature_ext '.calker.' ker_type];
ker.devname = [feature_ext '.devel.' ker_type];
ker.testname = [feature_ext '.test.' ker_type];
ker.descname = [feature_ext '.desc.' ker_type];

ker.cross = 1; % whether to do cross validation or not
if exist('cross', 'var'),
	ker.cross = cross;
end
% common params for cross validation
ker.startC = -10;
ker.endC = 0;
ker.stepC = 2;

ker.startG = -12;
ker.endG = 2;
ker.stepG = 2;

end