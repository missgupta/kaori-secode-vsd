# Written by Duy Le - ledduy@ieee.org
# Last update Jun 26, 2012
#!/bin/sh
# Force to use shell sh. Note that #$ is SGE command
#$ -S /bin/sh
# Force to limit hosts running jobs
#$ -q all.q@@bc3hosts,all.q@@bc4hosts
# Log starting time
date 
# for opencv shared lib
PATH=/net/per900a/raid0/plsang/software/gcc-4.8.1/release/bin:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/bin:/net/per900a/raid0/plsang/usr.local/bin:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/bin:$PATH
LD_LIBRARY_PATH=/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/boost_1_54_0/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/net/per610a/export/das11f/plsang/usr/lib/:/net/per610a/export/das11f/plsang/deepcaffe/gflags-master/build/lib:/usr/local/lib:$LD_LIBRARY_PATH

export PATH
export LD_LIBRARY_PATH

# Log info of the job to output file  *** CHANGED ***
echo [$HOSTNAME] [$JOB_ID] [matlab -nodisplay -r "deepcaffe_extract_feature('$1', '$2', '$3', $4, $5)"]
# change to the code dir  --> NEW!!! *** CHANGED ***
cd /net/per610a/export/das11f/plsang/codes/kaori-secode-vsd
# Log info of current dir
pwd
# Command - -->  must use " (double quote) for $2 because it contains a string  --- *** CHANGED ***
LD_PRELOAD="/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib64/libgcc_s.so.1" matlab -nodisplay -r "deepcaffe_extract_feature( '$1', '$2', '$3', $4, $5 )"

# Log ending time
date

