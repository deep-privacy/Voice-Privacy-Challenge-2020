#!/usr/bin/env python

import sys
import os
from os.path import join, basename
import torch

from ioTools import readwrite
from kaldiio import ReadHelper

args = sys.argv
bn_dir = args[1]
out_dir = args[2]

ppg_out_dir = join(out_dir, "ppg")

print("Writing ESPnet BN feats as PPG feats.....")
for filename in os.listdir(bn_dir):
    bn_feat = torch.load(join(bn_dir, filename)).cpu()
    readwrite.write_raw_mat(bn_feat.numpy(), join(ppg_out_dir, os.path.splitext(filename)[0]+'.bn'))

print("Finished writing BN feats.")
