import sys
from os.path import join, basename, dirname

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np
import json

from f0transformation import log_linear_transformation
import ast
import math

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
out_dir = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')
xvec_out_dir = join(out_dir, "xvector")
pitch_out_dir = join(out_dir, "f0")

statsdir = "./pchampio/F0_mod/data/"

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

        source_stats = {}
        with open(statsdir+dataname+"/"+key.split("-")[0].split("_")[0]) as f:
            source_stats = json.load(f)
        
        selected_target_speaker_list = []
        with open(dirname(xvector_file)+"/"+"selected_x_vec"+"/"+key) as f:
            selected_target_speaker_list = ast.literal_eval(f.read())

        pseudo_speaker_f0_stats = {"mu_s":0, "var_s":0, "std_s":0}
        top_one_std = 0
        top_one_mu = 0
        for selected_target_speaker in selected_target_speaker_list:
            target_speaker_stats = {}
            with open(statsdir+"/"+"libritts_train_other_500/"+selected_target_speaker) as f:
                target_speaker_stats = json.load(f)
                mu = target_speaker_stats["mu_s"]
                var = target_speaker_stats["var_s"]
                if top_one_std == 0:
                    top_one_std = target_speaker_stats["std_s"]
                if top_one_mu == 0:
                    top_one_mu = target_speaker_stats["mu_s"]
                pseudo_speaker_f0_stats["mu_s"] += mu
                pseudo_speaker_f0_stats["var_s"] += var
        pseudo_speaker_f0_stats["var_s"] /= len(selected_target_speaker_list)
        pseudo_speaker_f0_stats["mu_s"]  /= len(selected_target_speaker_list)
        pseudo_speaker_f0_stats["std_s"] = math.sqrt(pseudo_speaker_f0_stats["var_s"])

        transfomation = {**source_stats, "mu_t":top_one_mu, "std_t":top_one_std}
        #  transfomation = {**source_stats, "mu_t":target_speaker_stats["mu_s"], "std_t":top_one_std}
        #  transfomation = {**source_stats, "mu_t":target_speaker_stats["mu_s"], "std_t":target_speaker_stats["std_s"]}
        print(key, transfomation)

        f0t = log_linear_transformation(f0.copy(), transfomation)

        readwrite.write_raw_mat(f0t, join(pitch_out_dir, key+'.f0'))
