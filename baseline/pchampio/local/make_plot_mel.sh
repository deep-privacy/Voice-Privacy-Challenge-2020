#!/bin/bash

. path.sh
. cmd.sh

stage=0
data="libri_dev_enrolls"
uttid="1272-128104-0000"
copy_wav=true

data_file="am_nsf_data_pchampio_1"
data_file="am_nsf_data_baseline"

set -e
set -u
set -o pipefail

. utils/parse_options.sh

mkdir -p mel_plots/$data

if [ ! -f data/${data}_mspec/feats.scp ]; then
  printf "${RED}Stage: -2 - Generate target melspec${NC}\n"
  ./local/featex/extract_melspec.sh data/${data} data/${data}_mspec
  mkdir -p ./data/${data}_mspec/mel/
  python ./local/featex/create_melspec_data.py data/${data}_mspec/feats.scp $(pwd)/data/${data}_mspec
fi

if [ ! -f mel_plots/$data/${uttid}_expected.mel ]; then
  printf "${RED}Stage: -1 - Computing target plot${NC}\n"
  python pchampio/local/plot_mel.py \
    "./data/${data}_mspec/mel" \
    "${uttid}.mel"

  mv -v filter_banks.png mel_plots/$data/${uttid}_expected.png
  cp -v "./data/${data}_mspec/mel/${uttid}.mel" mel_plots/$data/${uttid}_expected.mel

  if $copy_wav; then
    original_wav=$(cat data/$data/wav.scp | grep "$uttid" | awk '{print $2}')
    cp -v "$original_wav" mel_plots/$data/${uttid}_original.wav
    sox -t wav mel_plots/$data/${uttid}_original.wav -t mp3 mel_plots/$data/${uttid}_original.mp3
  fi
fi

if [ $stage -le 1 ]; then
  printf "${RED}Stage: 1 - Generate plot from generated mel from system${NC}\n"
  python pchampio/local/plot_mel.py \
    "./exp/$data_file/${data}/am_out_mel/" \
    "${uttid}.mel"

  index=$(ls mel_plots/$data/*${uttid}*.png | wc -l)
  mv -v filter_banks.png mel_plots/$data/generated_${uttid}-${index}_ss_am_mel.png
  cp -v "./exp/$data_file/${data}/am_out_mel/${uttid}.mel" mel_plots/$data/generated_${uttid}-${index}_ss_am_mel.mel

  if $copy_wav; then
    cp -v "./exp/$data_file/${data}/nsf_output_wav/${uttid}.wav" mel_plots/$data/generated_${uttid}-$index.wav
    sox -t wav mel_plots/$data/generated_${uttid}-$index.wav -t mp3 mel_plots/$data/generated_${uttid}-$index.mp3
  fi
fi
