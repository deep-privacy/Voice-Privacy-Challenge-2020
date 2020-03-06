#!/bin/bash

# Training speech synthesis neural source filter (NSF) model  (see the trained model in /baseline/exp/models/4_nsf_am/) on LibriTTS-train-clean-100
# TO CORRECT

. ./cmd.sh
. ./path.sh

set -e

corpora=corpora
libritts_corpus=$(realpath $corpora/LibriTTS)

xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a

am_nsf_train_data="libritts_train_clean_100"
feats_out_dir=$(realpath pchampio/exp/TRAIN_out_am_nsf_data)

stage=1

. utils/parse_options.sh

if [ $stage -le 0 ]; then
  if [ ! -f /tmp/cache/${am_nsf_train_data}/wav.scp ]; then
    echo "Data prep of $am_nsf_train_data"
    local/data_prep_libritts.sh ${libritts_corpus}/train-clean-100 data/${am_nsf_train_data} || exit 1;
    mkdir -p /tmp/cache
    cp -r data/${am_nsf_train_data} /tmp/cache
  else
    echo "Copy data of $am_nsf_train_data from cache"
    cp -r /tmp/cache/${am_nsf_train_data}/* data/${am_nsf_train_data}
  fi
  local/run_prepfeats_am_nsf.sh \
	--xvec-nnet-dir ${xvec_nnet_dir} \
	${am_nsf_train_data} ${feats_out_dir} || exit 1;

  cat data/${am_nsf_train_data}/wav.scp | awk -v fo="$feats_out_dir" '{print "ln -s " $2, fo"/am_nsf_train/wav/"$1".wav\0"}' | xargs -0 bash -c
fi

if [ $stage -le 1 ]; then
  local/vc/nsf/00_run.sh ${feats_out_dir} || exit 1;
  echo "Model is trained and stored at ${nii_scripts}/waveform-modeling/project-NSF/MODELS/h-sinc-NSF/"
fi

if [ $stage -le 2 ]; then
  echo "copy model in pchampio/models/4_nsf"
  mkdir pchampio/models/4_nsf -p
  cp -r ${nii_scripts}/waveform-modeling/project-NSF/MODELS/h-sinc-NSF/ pchampio/models/4_nsf
fi
