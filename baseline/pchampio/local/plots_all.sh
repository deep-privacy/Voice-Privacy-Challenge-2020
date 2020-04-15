#!/bin/bash

. path.sh
. cmd.sh

output="mel_plot"
copy_wav=true

set -e
set -u
set -o pipefail

. utils/parse_options.sh


for exp in "am_nsf_data_baseline" "am_nsf_data_asr_bn" "am_nsf_data_asr_adv_bn"; do
  ./pchampio/local/make_plot_mel.sh \
    --uttid 1462-170142-0000 \
    --data libri_dev_trials_f \
    --data-file  "$exp" \
    --output $output \
    --copy-wav $copy_wav

  ./pchampio/local/make_plot_mel.sh \
    --uttid 1272-135031-0000 \
    --data libri_dev_trials_m \
    --data-file  "$exp" \
    --output $output \
    --copy-wav $copy_wav

  ./pchampio/local/make_plot_mel.sh \
    --uttid p234_293_mic2 \
    --data vctk_dev_trials_f_all \
    --data-file  "$exp" \
    --output $output \
    --copy-wav $copy_wav

  ./pchampio/local/make_plot_mel.sh \
    --uttid p247_413_mic2 \
    --data vctk_dev_trials_m_all \
    --data-file  "$exp" \
    --output $output \
    --copy-wav $copy_wav
done
