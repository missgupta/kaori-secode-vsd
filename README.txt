*** How to run VSD system:
With default path configuration

Feature encoding
1. Select subset of features for clustering
ex: sift_select_features('colordescriptor', 6) 

2. Do clustering
do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2013', 'colordescriptor.6.sift', 80)
do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2014', 'idensetraj.mbh', 128)
do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2014', 'idensetraj.hoghof', 128)

do_clustering_kmeans('/net/per610a/export/das11f/plsang', 'mfcc.rastamat');
do_clustering_kmeans('/net/per610a/export/das11f/plsang', 'idensetraj.hoghof');
do_clustering_kmeans('/net/per610a/export/das11f/plsang', 'idensetraj.mbh');

tic; matlabpool open; densetraj_select_features('mbh'); matlabpool close; do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2014', 'idensetraj.mbh', 128); toc;
tic; matlabpool open; densetraj_select_features('hoghof'); matlabpool close; do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2014', 'idensetraj.hoghof', 128); toc;

**** Add PATH & LD_LIBRARY_PATH
PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/bin:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/bin:/net/per900a/raid0/plsang/usr.local/bin:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/bin:$PATH
LD_LIBRARY_PATH=/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRARY_PATH


Learning
calker_main('vsd2014', 'colordescriptor.6.sift.cb256.fisher.pca', 1, 1)
calker_main('vsd2014', 'idensetraj.hoghofmbh.cb256.fc.pca', 1, 1)12:09 PM 9/5/2014

%% DEVEL 2013 - TEST 2014
ker.dev_pat_list = {'devel2011', 'test2011'};
ker.dev_pat = 'devel2013-new';
ker.test_pat_list = {'test2014'};
ker.test_pat = 'test2014-new';

% Run again :-)
tic; matlabpool open; sift_select_features('covdet', 'hessian'); matlabpool close; do_clustering_gmm('/net/per610a/export/das11f/plsang/vsd2014', 'covdet.hessian.sift', 80); toc;

SIFT
gen_sge_code('sift_encode_fc_sge', 'vsd2014 keyframe-5 covdet hessian %d %d', 46058, 500, 2)

MFCC:

cm_gen_local_scripts('mfcc_encode_home', '''rastamat'', %d, %d', 41206, 20)


+++ late fusion
calker_late_fusion('vsd2014', 'mediaeval-vsd-2014.devel2013-new', 'test2013-new')
calker_late_fusion('vsd2014', 'mediaeval-vsd-2014.devel2013-new', 'test2014-new')
calker_late_fusion('vsd2014', 'mediaeval-vsd-2014.devel2014-new', 'test2014-new')

