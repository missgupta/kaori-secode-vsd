PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/bin:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/bin:/net/per900a/raid0/plsang/usr.local/bin:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/bin:$PATH
LD_LIBRARY_PATH=/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/usr/local/lib:$LD_LIBRARY_PATH
export PATH
export LD_LIBRARY_PATH

cd /net/per610a/export/das11f/plsang/codes/kaori-secode-vsd
matlab -nodisplay -r "mfcc_encode_home('rastamat', 1, 2061)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 2062, 4122)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 4123, 6183)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 6184, 8244)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 8245, 10305)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 10306, 12366)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 12367, 14427)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 14428, 16488)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 16489, 18549)" &
matlab -nodisplay -r "mfcc_encode_home('rastamat', 18550, 20610)" &
wait
