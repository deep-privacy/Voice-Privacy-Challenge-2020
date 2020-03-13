import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np
import math

bn_shape=256

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")

log_printed = 10

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

        # Duplicate BN to have the same dimentions
        bn = readwrite.read_raw_mat(join(out_dir, 'ppg', key+'.bn'), bn_shape)
        ubsamp_facor = math.ceil(kaldi_f0.shape[0]/len(bn))
        bn_up_rep = np.repeat(bn, ubsamp_facor, axis=0)
        bn_up = bn_up_rep[:kaldi_f0.shape[0]]
        if log_printed > 0:
            print(f"Repeating ESPnet bn-features (dim:{len(bn)}) vector into vector of dim:{kaldi_f0.shape[0]}, subsamp_facor: {ubsamp_facor}")
            log_printed -= 1
        readwrite.write_raw_mat(bn_up, join(out_dir, 'ppg', key+'.bn'))


# Write xvector features
with ReadHelper('scp:'+xvector_file) as reader:
    for key, mat in reader:
        #print key, mat.shape
        plen = pitch2shape[key]
        mat = mat[np.newaxis]
        xvec = np.repeat(mat, plen, axis=0)
        readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))
