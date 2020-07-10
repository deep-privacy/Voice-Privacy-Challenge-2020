#!/bin/bash

. path.sh
. cmd.sh

stage=0
data="libri_dev_enrolls"
uttid="1272-128104-0000"
data_file="am_nsf_data"

data_dir_out="${HOME}/tmp"
output="$data_dir_out/${uttid}_vtlp.mel"

touch $output

python pchampio/local/make_vtlp_mels.py \
  "./exp/$data_file/${data}/am_out_mel/" \
  "${uttid}.mel" \
  $output

python pchampio/local/plot_mel.py \
  "$data_dir_out" \
  "${uttid}_vtlp.mel"
