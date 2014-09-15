PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/bin:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/bin:/net/per900a/raid0/plsang/usr.local/bin:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/bin:$PATH
LD_LIBRARY_PATH=/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRARY_PATH

cd /net/per610a/export/das11f/plsang/codes/kaori-secode-vsd
matlab -nodisplay -r "mfcc_encode_home('rastamat', 20611, 22671)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 22672, 24732)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 24733, 26793)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 26794, 28854)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 28855, 30915)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 30916, 32976)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 32977, 35037)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 35038, 37098)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 37099, 39159)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 39160, 41206)" &
wait
