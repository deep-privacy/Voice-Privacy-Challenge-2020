import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np
import scipy.signal as sps

bn_shape=256

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
nb2shape = {}
with ReadHelper('scp:'+pitch_file) as reader: # loop to get the uttid
    for key, mat in reader:
        nb2shape[key] = readwrite.read_raw_mat(join(out_dir, 'ppg', key+'.bn'), bn_shape).shape[0]
        yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)
        #kaldi_f0[unvoiced] = 0
        #unvoiced = np.where(yaapt_f0 == 0)[0]
        #readwrite.write_raw_mat(kaldi_f0, join(pitch_out_dir, key+'.f0'))
        yaapt_f0_resample_at_bn_len = sps.resample(yaapt_f0, nb2shape[key])
        readwrite.write_raw_mat(yaapt_f0_resample_at_bn_len, join(pitch_out_dir, key+'.f0'))


# Write xvector features
with ReadHelper('scp:'+xvector_file) as reader:
    for key, mat in reader:
        #print key, mat.shape
        plen = nb2shape[key]
        mat = mat[np.newaxis]
        xvec = np.repeat(mat, plen, axis=0)
        readwrite.write_raw_mat(xvec, join(xvec_out_dir, key+'.xvector'))
