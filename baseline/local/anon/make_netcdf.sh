#!/bin/bash

. path.sh
. cmd.sh

stage=0
f0_mod="false"

. utils/parse_options.sh

if [ $# != 4 ]; then
  echo "Usage: "
  echo "  $0 [options] <train-dir> <ppg-file> <xvec-out-dir> <data-out-dir>"
  echo "Options"
  echo "   --stage 0     # Number of CPUs to use for feature extraction"
  exit 1;
fi

# Debug example:
# $ local/anon/make_netcdf.sh data/libri_dev_trials_f exp/models/1_asr_am/exp/nnet3_cleaned/ppg_libri_dev_trials_f/phone_post.scp exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/xvectors_libri_dev_trials_f/pseudo_xvecs/pseudo_xvector.scp /srv/storage/talc@talc-data.nancy/multispeech/calcul/users/pchampion/lab/voice_privacy/Voice-Privacy-Challenge-2020/baseline/exp/am_nsf_data/libri_dev_trials_f

src_data=$1

ppg_file=$2
xvector_file=$3

out_dir=$4


if [ $stage -le 0 ]; then
  mkdir -p $out_dir/scp $out_dir/xvector $out_dir/f0 $out_dir/ppg

  echo "Writing SCP file.."
  cut -f 1 -d' ' ${src_data}/utt2spk > ${out_dir}/scp/data.lst || exit 1;
fi

# initialize pytools
. local/vc/am/init.sh

if [ $stage -le 1 ]; then
  python local/featex/create_ppg_data.py ${ppg_file} ${out_dir} || exit 1;
fi

if [ $stage -le 2 ]; then
  echo "Writing xvector and F0 for train."
  python local/featex/create_xvector_f0_data.py ${src_data} ${xvector_file} ${out_dir} || exit 1;

  if $f0_mod; then
    echo "Apply linear transformation on F0."
    python pchampio/F0_mod/transform_f0_data.py ${src_data} ${xvector_file} ${out_dir} || exit 1;
  fi

  exit 0
fi

if [ $stage -le 3 ]; then
  echo "Writing back original xvector for NSF."
  python local/featex/copy_xvector_f0_data.py ${src_data} ${xvector_file} ${out_dir} || exit 1;
  exit 0
fi
