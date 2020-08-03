import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")

# Write pitch features
pitch_file = join(data_dir, 'pitch.scp')
pitch2shape = {}
with ReadHelper('scp:'+pitch_file) as reader:
    for key, mat in reader:
        pitch2shape[key] = mat.shape[0]
        kaldi_f0 = mat[:, 1].squeeze().copy()
        yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)
        #unvoiced = np.where(yaapt_f0 == 0)[0]
        #kaldi_f0[unvoiced] = 0
        #readwrite.write_raw_mat(kaldi_f0, join(pitch_out_dir, key+'.f0'))
        f0 = np.zeros(kaldi_f0.shape)
        f0[:yaapt_f0.shape[0]] = yaapt_f0
        readwrite.write_raw_mat(f0, join(pitch_out_dir, key+'.f0'))


# Write xvector features
with ReadHelper('scp:'+xvector_file) as reader:
    for key, mat in reader:
        print(key)
        #print key, mat.shape
        keys = pitch2shape.keys()
        key_utts = list(filter(lambda x: x.startswith(key), keys))
        for key  in key_utts:
            #print key, mat.shape
            plen = pitch2shape[key]
            _mat = mat[np.newaxis]
            xvec = np.repeat(_mat, plen, axis=0)
            #  xvec = np.repeat(np.random.rand(512), plen, axis=0)
            readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))


"""
with ReadHelper('scp:'+'exp/models/2_xvect_extr/exp/xvector_nnet_1a/anon/xvectors_libri_dev_trials_f/spk_xvector.scp') as reader:
    for key, mat in reader:
        print(mat.shape)
        mat = mat[np.newaxis]
        print(mat.shape)
        xvec = np.repeat(mat, 12, axis=0)
        print(xvec.shape)
        print(key)
        a = readwrite.read_raw_mat( join("exp/am_nsf_data/libri_dev_trials_f/xvector", key+"-170145-0022"+'.xvector'), 512)[0]
        b = mat
        print(a[:10])
        print(b[:10])
        print(a==b)
        break
"""
