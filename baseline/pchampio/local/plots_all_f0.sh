#!/bin/bash

. path.sh
. cmd.sh

output="mel_plot_f0"
copy_wav=true

set -e
set -u
set -o pipefail

. utils/parse_options.sh

./pchampio/local/make_plot_f0.sh \
  --uttid 1462-170142-0000 \
  --data libri_dev_trials_f \
  --output $output

./pchampio/local/make_plot_f0.sh \
  --uttid 1272-135031-0000 \
  --data libri_dev_trials_m \
  --output $output

./pchampio/local/make_plot_f0.sh \
  --uttid p234_293_mic2 \
  --data vctk_dev_trials_f_all \
  --output $output

./pchampio/local/make_plot_f0.sh \
  --uttid p247_413_mic2 \
  --data vctk_dev_trials_m_all \
  --output $output
