#!/usr/bin/env bash

#################
#  ESPNET PATH  #
#################

ESPNET_PATH=../espnet
if [ $USER = "pchampion" ]; then
  ESPNET_PATH=$HOME/lab/espnet
fi

KALDI_ROOT=$ESPNET_PATH/tools/kaldi

export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sctk/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ESPNET_PATH/tools/chainer_ctc/ext/warp-ctc/build
source $ESPNET_PATH/tools/venv/bin/activate
export PATH=$ESPNET_PATH/utils:$ESPNET_PATH/espnet/bin:$PATH

export OMP_NUM_THREADS=1

# NOTE(kan-bayashi): Use UTF-8 in Python to avoid UnicodeDecodeError when LC_ALL=C
export PYTHONIOENCODING=UTF-8
