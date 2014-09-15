PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/bin:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/bin:/net/per900a/raid0/plsang/usr.local/bin:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/bin:$PATH
LD_LIBRARY_PATH=/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRARY_PATH

cd /net/per610a/export/das11f/plsang/codes/kaori-secode-vsd2013
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 1, 2303)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 2304, 4606)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 4607, 6909)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 6910, 9212)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 9213, 11515)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 11516, 13818)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 13819, 16121)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 16122, 18424)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 18425, 20727)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 20728, 23030)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 23031, 25333)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 25334, 27636)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 27637, 29939)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 29940, 32242)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 32243, 34545)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 34546, 36848)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 36849, 39151)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 39152, 41454)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 41455, 43757)" &
matlab -nodisplay -r "densetraj_encode_sge('vsd2014', 'keyframe-5', 43758, 46058)" &
wait
