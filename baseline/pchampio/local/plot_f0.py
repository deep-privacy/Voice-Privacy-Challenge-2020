#!/usr/bin/env python

import matplotlib.pyplot as plt

import sys
from os.path import join, basename, dirname

from ioTools import readwrite
from kaldiio import WriteHelper, ReadHelper
import numpy as np
import json

from f0transformation import log_linear_transformation

args = sys.argv
data_dir = args[1]
xvector_file = args[2]
uttid = args[3]

dataname = basename(data_dir)
yaap_pitch_dir = join(data_dir, 'yaapt_pitch')

statsdir = "./pchampio/F0_mod/data/"

# Write pitch features
pitch_file = join(data_dir, 'pitch.scp')
pitch2shape = {}
with ReadHelper('scp:'+pitch_file) as reader:
    for key, mat in reader:
        if uttid != key:
            continue
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
        
        selected_target_speaker = ""
        with open(dirname(xvector_file)+"/"+"selected_x_vec"+"/"+key) as f:
            selected_target_speaker = f.read()

        target_speaker_stats = {}
        with open(statsdir+"/"+"libritts_train_other_500/"+selected_target_speaker) as f:
            target_speaker_stats = json.load(f)

        transfomation = {**source_stats, "mu_t":target_speaker_stats["mu_s"], "std_t":target_speaker_stats["std_s"]}

        f0t = log_linear_transformation(f0.copy(), transfomation)

        plt.rcParams.update({'font.size': 22})

        fig1 = plt.figure(figsize=(40,15))

        # and the first axes using subplot populated with data
        ax1 = fig1.add_subplot(111)
        line1 = ax1.plot(f0, 'o-', label='Original f0')
        line2 = ax1.plot(f0t, "xr-", label='Transformed f0')

        plt.xlabel("Time")
        plt.ylabel("f0 value")
        plt.legend()

        plt.savefig('foo.png')

