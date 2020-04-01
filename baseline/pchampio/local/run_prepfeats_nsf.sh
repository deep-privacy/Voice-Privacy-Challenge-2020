#!/bin/bash

. path.sh
. cmd.sh

set -e

#===== begin config =======
nj=40
stage=1 # stage 0 (nb/ppg,Xvector,f0) should be already performed by local/train_model_ss_am.sh

# Chain model for PPG extraction
ppg_model=         # change this to your pretrained chain model
ppg_dir=           # change this to the dir where PPGs will be stored

# Xvector extractor
xvec_nnet_dir=     # change this to pretrained xvector model

#===== end config =========

. utils/parse_options.sh

feat_out_dir="$1"

# Output directories for netcdf data that will be used by AM & NSF training
train_out=${feat_out_dir}/am_nsf_train # change this to the dir where train, dev data and scp files will be stored
test_out=${feat_out_dir}/am_nsf_test # change this to dir where test data will be stored

# Extract 80 dimensional mel spectrograms FROM the ss_am model (model 3)
if [ $stage -le 1 ]; then
  echo "Stage 1: Extract melspec from acoustic model of train set"
  local/vc/am/01_gen.sh ${train_out} || exit 1;

  echo "Stage 1: Extract melspec from acoustic model of test set"
  local/vc/am/01_gen.sh ${test_out} || exit 1;
fi
