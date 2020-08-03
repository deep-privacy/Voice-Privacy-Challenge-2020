#!/bin/bash

set -e

. path.sh
. cmd.sh

for data_dir in libri_dev_{enrolls,trials_f,trials_m} \
            vctk_dev_{enrolls,trials_f_all,trials_m_all} \
            libri_test_{enrolls,trials_f,trials_m} \
            vctk_test_{enrolls,trials_f_all,trials_m_all}; do

  break

    mkdir -p ./pchampio/F0_mod/data/${data_dir}

    python ./pchampio/F0_mod/create_xvector_f0_map.py ./data/${data_dir} exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/xvectors_${data_dir}/xvector.scp ./pchampio/F0_mod/data/${data_dir}

done

# extract f0 contour for the pool of speaker x-vector
if [ ! -f data/libritts_train_other_500/pitch.scp ]; then
  local/featex/02_extract_pitch.sh --nj 64 --pitch-config pchampio/conf/pitch_libriTTS.conf data/libritts_train_other_500
fi

# extarct stats from the pool of speaker x-vector
data_dir=libritts_train_other_500

mkdir -p ./pchampio/F0_mod/data/${data_dir}

python ./pchampio/F0_mod/create_xvector_f0_map.py ./data/${data_dir} exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/xvectors_${data_dir}/xvector.scp ./pchampio/F0_mod/data/${data_dir}
