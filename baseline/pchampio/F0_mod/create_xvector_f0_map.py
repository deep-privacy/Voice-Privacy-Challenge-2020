import sys
from os.path import join, basename

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np
import math
import json

from f0transformation import log_linear_transformation

args = sys.argv
data_dir = args[1]
xvector_file = args[2] # un-used
stats_file = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')

def calc_stats(f0):
    # Calculate mean and std of f0
    ## TODO(Denis): use median instead of mean.
    f0 = f0[f0 > 1.]
    f0 = np.log(f0) # transfomation will be done in the log-F0 domain, so stats must be computed in this same domain.
    mu, std = f0.mean(), f0.std()

    return {
        "mu_s" : mu,
        "std_s": std,
    }


# Write pitch features
pitch_file = join(data_dir, 'pitch.scp')
pitch2shape = {}
with ReadHelper('scp:'+pitch_file) as reader:
    print("f0 features: " + data_dir)
    for key, mat in reader:
        kaldi_f0 = mat[:, 1].squeeze().copy()
        yaapt_f0 = readwrite.read_raw_mat(join(yaap_pitch_dir, key+'.f0'), 1)

        f0 = np.zeros(kaldi_f0.shape)
        f0[:yaapt_f0.shape[0]] = yaapt_f0
        #  print(key, f0[0:100], len(f0))

        if key.split("-")[0].split("_")[0] not in pitch2shape:
            pitch2shape[key.split("-")[0].split("_")[0]] = np.array([])
        pitch2shape[key.split("-")[0].split("_")[0]] = np.concatenate((pitch2shape[key.split("-")[0].split("_")[0]], f0))



        #  f0t = log_linear_transformation(f0.copy(), calc_stats(f0.copy()))

        #  stat_f0 = f0t[f0t > 1.]
        #  stat_f0 = np.log(stat_f0) # transfomation will be done in the log-F0 domain, so stats must be computed in this same domain.
        #  mu, std = stat_f0.mean(), stat_f0.std()
        #  print("T", key, mu, std)

        #  sys.exit(0)


for key, val in pitch2shape.items():
    print(key, calc_stats(val))
    with open(stats_file + '/' + key, 'w') as outfile:
        json.dump(calc_stats(val), outfile)



