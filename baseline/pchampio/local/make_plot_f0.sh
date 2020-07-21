#!/bin/bash

. path.sh
. cmd.sh

data="libri_dev_enrolls"
uttid="1272-128104-0000"

output="f0_plot"

set -e
set -u
set -o pipefail

. utils/parse_options.sh

mkdir -p $output/$data

printf "${RED}Stage: -1 - Computing plot${NC}\n"
python pchampio/local/plot_f0.py \
  "./data/${data}" \
  "exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/xvectors_${data}/pseudo_xvecs/." \
  "${uttid}"

mv -v foo.png $output/$data/${uttid}.png
