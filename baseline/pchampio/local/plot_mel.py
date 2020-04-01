#!/usr/bin/env python

from ioTools import readwrite
import sys
from os.path import join

import numpy
import matplotlib.pyplot as plt

args = sys.argv
mspec_file = args[1]
key = args[2]

filter_banks = readwrite.read_raw_mat(join(mspec_file, key), 80)

print("Shape:", filter_banks.shape)

plt.imshow(filter_banks.T, cmap=plt.cm.jet, extent=[0, filter_banks.shape[0], 0, filter_banks.shape[1]])
plt.xlabel("Frames", fontsize=9, color='gray')
plt.ylabel('Filter banks (80)', fontsize=9, color='gray')
plt.title('Audio Spectrogram (dB)', fontsize=12, color='gray')
plt.yticks(fontsize=7, rotation=0, color='gray')
plt.xticks(fontsize=7, rotation=0, color='gray')
plt.tick_params(axis='both')
plt.gca().spines['top'].set_color('gray')
plt.gca().spines['bottom'].set_color('gray')
plt.gca().spines['left'].set_color('gray')
plt.gca().spines['right'].set_color('gray')
plt.savefig('filter_banks.png', dpi=400)
