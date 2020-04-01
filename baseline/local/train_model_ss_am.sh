#!/bin/bash

# Training speech synthesis acoustic model (see the trained model in /baseline/exp/models/3_ss_am/) LibriTTS-train-clean-100

. ./cmd.sh
. ./path.sh

set -e

corpora=corpora
libritts_corpus=$(realpath $corpora/LibriTTS)

xvec_nnet_dir=exp/models/2_xvect_extr/exp/xvector_nnet_1a

am_nsf_train_data="libritts_train_clean_100"
feats_out_dir=$(realpath pchampio/exp/TRAIN_out_am_nsf_data)

stage=0

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
fi

if [ $stage -le 1 ]; then
  local/vc/am/00_run.sh ${feats_out_dir} || exit 1;
  echo "Model is trained and stored at ${nii_scripts}/acoustic-modeling/project-DAR-continuous/MODELS/DAR_001/"
fi

if [ $stage -le 2 ]; then
  echo "copy model in pchampio/models/3_ss_am"
  mkdir pchampio/models/3_ss_am -p
  cp -r ${nii_scripts}/acoustic-modeling/project-DAR-continuous/MODELS/DAR_001/* pchampio/models/3_ss_am
fi
