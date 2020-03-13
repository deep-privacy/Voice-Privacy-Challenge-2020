#!/bin/bash

. path.sh
. cmd.sh

nj=32
stage=0
batchsize=2 # Tweak the batchsize depanding on the amount of GPU RAM
gpu_id=2
fbank_conf=fbank.conf
pitch_conf=pitch.conf

. utils/parse_options.sh

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

data=$1

work_dir=pchampio

original_data_dir=data/${data}
data_dir=${work_dir}/data/${data}_hires

#####
# ESPnet linked config!! (librispeech model is already trained, run.sh)
###

# Trained with
# train_600 is used for Speech and Text seq2seq training!
### ./run.sh --train-config $(~/lab/espnet/utils/change_yaml.py conf/train.yaml -a eprojs=256 -a elayers=5 -a subsample='1_1_1' -a epochs=15 -a dunits=1024) --stage 4 --DAMPED_active_branch false --DAMPED_N_DOMAIN 0 --TRAIN_SET train_600 --resume ''
espnet_libri_egs=$ESPNET_PATH/egs/librispeech/asr1

# CMVN are computed globaly on librispeech default train set
cmvn_dir=$espnet_libri_egs/data/train_960

# Using bpemodel text bpemodel from defualt train set
nbpe=5000
dict=$espnet_libri_egs/data/lang_char/train_960_unigram${nbpe}_units.txt
bpemodel=$espnet_libri_egs/data/lang_char/train_960_unigram${nbpe}

# recog config
decode_config=$espnet_libri_egs/conf/decode.yaml

# Acoustic model
am_model_arch=train_600_pytorch_train_eprojs256_elayers3_subsample1_1_1_epochs15_dunits512_run.sh
am_model=snapshot.ep.3
am_model_fullpath=$espnet_libri_egs/exp/$am_model_arch/results/$am_model
lm_model=$espnet_libri_egs/

# LM model
lang_model_arch=train_rnnlm_pytorch_lm_unigram5000
lang_model=rnnlm.model.best
lang_model_fullpath=$espnet_libri_egs/exp/$lang_model_arch/$lang_model

# Damped
DAMPED_damped_dir='/home/pchampion/lab/damped'

###
# End ESPnet linked config
#####

# feature gen
fbankdir=${data_dir}/fbank
fbank_config=${work_dir}/conf/$fbank_conf
pitch_config=${work_dir}/conf/$pitch_conf
do_delta=false
make_fbank_log_dir=${work_dir}/exp/${data}_hires/make_fbank
make_dump_log_dir=${work_dir}/exp/${data}_hires/dump_feats
feat_recog_dir=${work_dir}/dump/${data}; mkdir -p ${feat_recog_dir}

# recog
recog_log_dir=${work_dir}/exp/${data}_hires/decode


# if [ -f $recog_log_dir/result.txt ]; then
  # printf "${CYAN}\nStage pchampio: ${RED} Skiping ${data} (already extracted).${NC}\n"
  # exit 0;
# fi


if [ $stage -le 0 ]; then
  printf "${CYAN}\nStage pchampio: Feature Generation & Json Data Preparation of ${data}.${NC}\n"

  utils/copy_data_dir.sh ${original_data_dir} ${data_dir}

  # Generate the fbank features; by default 80-dimensional fbanks with pitch on each frame
  steps/make_fbank_pitch.sh --cmd "$train_cmd" --nj ${nj} --write_utt2num_frames true \
    --pitch_config $pitch_config  \
    --fbank_config $fbank_config  \
    ${data_dir} ${make_fbank_log_dir} ${fbankdir}
  utils/fix_data_dir.sh ${data_dir}

  dump.sh --cmd "$train_cmd" --nj ${nj} --do_delta ${do_delta} \
      ${data_dir}/feats.scp ${cmvn_dir}/cmvn.ark ${make_dump_log_dir} \
      ${feat_recog_dir}

  data2json.sh --feat ${feat_recog_dir}/feats.scp --bpecode ${bpemodel}.model \
      ${data_dir} ${dict} > ${feat_recog_dir}/data.json
fi

dump_eproj=${work_dir}/exp/${data}_hires/dump_eproj; mkdir -p $dump_eproj

if [ $stage -le 1 ]; then
  printf "${CYAN}\nStage pchampio: BN extraction for ${data} using pre-trained ESPnet model.${NC}\n"
  printf " Log: ${recog_log_dir}/recog.log\n"

  $train_cmd ${recog_log_dir}/recog.log \
    DAMPED_N_DOMAIN=0 DAMPED_D_task='spk' DAMPED_damped_dir=$DAMPED_damped_dir \
    DAMPED_save_uttid_eproj=$dump_eproj \
    CUDA_VISIBLE_DEVICES=$gpu_id \
      asr_recog.py \
        --config ${decode_config} \
        --ngpu 1 \
        --backend pytorch \
        --batchsize $batchsize \
        --recog-json ${feat_recog_dir}/data.json \
        --result-label ${recog_log_dir}/data.recog-result.json \
        --model ${am_model_fullpath}  \
        --rnnlm ${lang_model_fullpath}

  score_sclite.sh --bpe ${nbpe} --bpemodel ${bpemodel}.model --wer true ${recog_log_dir} ${dict}

fi
