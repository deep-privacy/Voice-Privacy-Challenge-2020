#!/bin/bash

. path.sh
. cmd.sh

nj=32
stage=0
batchsize=1 # Tweak the batchsize depanding on the amount of GPU RAM
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
### ./run.sh --train-config $(~/lab/espnet/utils/change_yaml.py conf/train.yaml -a eprojs=256 -a elayers=3 -a subsample='1_1_1' -a epochs=15 -a dunits=512) --stage 4 --DAMPED_active_branch false --DAMPED_N_DOMAIN 0 --TRAIN_SET train_600 --resume '' --RECOG_SET 'test_other'
### fine tuned with ./run.sh --train-config ./conf/train_eprojs256_elayers3_subsample1_1_1_epochs15_dunits512.yaml --stage 4 --TRAIN_SET train_loc_60 --resume 'snapshot.ep.41' --RECOG_SET 'test_other'
### Results:
### WER
# | dataset                                    | Snt  | Wrd   | Corr | Sub  | Del | Ins | Err  | S.Err |
# | ---                                        | ---  | ---   | ---  | ---  | --- | --- | ---  | ---   |
# | decode_test_clean_model.acc.best_decode_lm | 2620 | 52576 | 93.6 | 5.8  | 0.6 | 1.0 | 7.4  | 60.2  |
# | decode_test_other_model.acc.best_decode_lm | 2939 | 52343 | 84.8 | 13.5 | 1.7 | 2.6 | 17.9 | 79.9  |

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
am_model_arch=train_loc_60_pytorch_train_eprojs256_elayers3_subsample1_1_1_epochs15_dunits512_run.sh
am_model=snapshot.ep.41
am_model_fullpath=$espnet_libri_egs/exp/$am_model_arch/results/$am_model

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

  ngpu=1
  # obtain the number of GPUs on the node
  which nvidia-smi >/dev/null 2>&1; if [ $? -eq 0 ]; then ngpu=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l); fi

  # split data
  splitjson.py --parts ${ngpu} ${feat_recog_dir}/data.json

  pids=() # initialize pids
  for JOB in $(seq 1 $ngpu); do
  (
    printf " Log: ${recog_log_dir}/recog.${JOB}.log\n"

    $train_cmd ${recog_log_dir}/recog.${JOB}.log \
      DAMPED_N_DOMAIN=0 DAMPED_D_task='spk' DAMPED_damped_dir=$DAMPED_damped_dir \
      DAMPED_save_uttid_eproj=$dump_eproj \
      CUDA_VISIBLE_DEVICES=$(($JOB - 1)) \
        asr_recog.py \
          --config ${decode_config} \
          --ngpu 1 \
          --backend pytorch \
          --batchsize $batchsize \
          --recog-json ${feat_recog_dir}/split${ngpu}utt/data.${JOB}.json \
          --result-label ${recog_log_dir}/data.recog-result.${JOB}.json \
          --model ${am_model_fullpath}

    score_sclite.sh --bpe ${nbpe} --bpemodel ${bpemodel}.model --wer true ${recog_log_dir} ${dict}
  ) &
  pids+=($!) # store background pids
  done
  i=0; for pid in "${pids[@]}"; do wait ${pid} || ((++i)); done
  [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
  echo "Finished"

fi
