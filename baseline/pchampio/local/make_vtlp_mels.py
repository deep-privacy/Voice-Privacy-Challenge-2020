#!/usr/bin/env python

from ioTools import readwrite
import sys
from os.path import join
import numpy as np
import random
import torch
import math

args = sys.argv
mspec_file = args[1]
key = args[2]
output = args[3]

filter_banks = readwrite.read_raw_mat(join(mspec_file, key), 80)
print("Shape:", filter_banks.shape)

# https://github.com/daemon/squawk/blob/0d2b352c1d7e6e890c8698315d9bce091f2f8b61/squawk/data/preprocessing/augment.py#L245-L270
def create_vtlp_fb_matrix(n_freqs, f_min, f_max, n_mels, sample_rate, alpha, f_hi=4800, training=True):
    # type: (int, float, float, int, int, float, int, bool) -> torch.Tensor
    # freq bins
    # Equivalent filterbank construction by Librosa
    S = sample_rate
    all_freqs = torch.linspace(0, sample_rate // 2, n_freqs)

    # calculate mel freq bins
    # hertz to mel(f) is 2595. * math.log10(1. + (f / 700.))
    m_min = 2595.0 * math.log10(1.0 + (f_min / 700.0))
    m_max = 2595.0 * math.log10(1.0 + (f_max / 700.0))
    m_pts = torch.linspace(m_min, m_max, n_mels + 2)
    # mel to hertz(mel) is 700. * (10**(mel / 2595.) - 1.)
    f_pts = 700.0 * (10 ** (m_pts / 2595.0) - 1.0)
    if training:
        f_pts[f_pts <= f_hi * min(alpha, 1) / alpha] *= alpha
        f = f_pts[f_pts > f_hi * min(alpha, 1) / alpha]
        f_pts[f_pts > f_hi * min(alpha, 1) / alpha] = S / 2 - ((S / 2 - f_hi * min(alpha, 1)) /
                                                               (S / 2 - f_hi * min(alpha, 1) / alpha)) * (S / 2 - f)
    # calculate the difference between each mel point and each stft freq point in hertz
    f_diff = f_pts[1:] - f_pts[:-1]  # (n_mels + 1)
    slopes = f_pts.unsqueeze(0) - all_freqs.unsqueeze(1)  # (n_freqs, n_mels + 2)
    # create overlapping triangles
    zero = torch.zeros(1)
    down_slopes = (-1.0 * slopes[:, :-2]) / f_diff[:-1]  # (n_freqs, n_mels)
    up_slopes = slopes[:, 2:] / f_diff[1:]  # (n_freqs, n_mels)
    fb = torch.max(zero, torch.min(down_slopes, up_slopes))
    return fb

fb = create_vtlp_fb_matrix(80, 0, 8000, 80, 16000,
                                   random.random() * 0.2 + 0.9, training=True)


vtlp_features = torch.matmul(torch.tensor(filter_banks), fb).numpy()
readwrite.write_raw_mat(vtlp_features, output)
print("Output vtlp shape:", vtlp_features.shape)

