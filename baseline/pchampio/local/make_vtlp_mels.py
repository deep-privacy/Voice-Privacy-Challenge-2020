#!/usr/bin/env python

from ioTools import readwrite
import sys
from os.path import join
import numpy as np
import random
import torch
import math
import torchaudio


args = sys.argv
mspec_file = args[1]
key = args[2]
output = args[3]


def create_vtlp_fb_matrix(
    n_freqs, f_min, f_max, n_mels, sample_rate, alpha, f_hi=4800, training=True
):
    # type: (int, float, float, int, int, float, int, bool) -> torch.Tensor
    r"""Create a frequency bin conversion matrix.
    Args:
        n_freqs (int): Number of frequencies to highlight/apply
        f_min (float): Minimum frequency (Hz)
        f_max (float): Maximum frequency (Hz)
        n_mels (int): Number of mel filterbanks
        sample_rate (int): Sample rate of the audio waveform
        alpha (float): Warping factor
        f_hi (int): Boundary frequency. Default value is 4800.
        training (bool) apply_vtlp or not
    Returns:
        torch.Tensor: Triangular filter banks (fb matrix) of size (``n_freqs``, ``n_mels``)
        meaning number of frequencies to highlight/apply to x the number of filterbanks.
        Each column is a filterbank so that assuming there is a matrix A of
        size (..., ``n_freqs``), the applied result would be
        ``A * create_fb_matrix(A.size(-1), ...)``.
    """
    # Equivalent filterbank construction by Librosa
    all_freqs = torch.linspace(0, sample_rate // 2, n_freqs)

    # calculate mel freq bins
    # hertz to mel(f) is 2595. * math.log10(1. + (f / 700.))
    m_min = 2595.0 * math.log10(1.0 + (f_min / 700.0))
    m_max = 2595.0 * math.log10(1.0 + (f_max / 700.0))
    m_pts = torch.linspace(m_min, m_max, n_mels + 2)
    # mel to hertz(mel) is 700. * (10**(mel / 2595.) - 1.)
    f_pts = 700.0 * (10 ** (m_pts / 2595.0) - 1.0)
    if training:
        print("VTLP alpha:", alpha)
        scale = f_hi * min(alpha, 1)
        f_boundary = scale / alpha
        f_pts[f_pts <= f_boundary] *= alpha
        half_sr = sample_rate / 2
        f = f_pts[f_pts > f_boundary]
        f_pts[f_pts > f_boundary] = half_sr - (half_sr - scale) / (
            half_sr - scale / alpha
        ) * (half_sr - f)

    # calculate the difference between each mel point and each stft freq point in hertz
    f_diff = f_pts[1:] - f_pts[:-1]  # (n_mels + 1)
    slopes = f_pts.unsqueeze(0) - all_freqs.unsqueeze(1)  # (n_freqs, n_mels + 2)
    # create overlapping triangles
    zero = torch.zeros(1)
    down_slopes = (-1.0 * slopes[:, :-2]) / f_diff[:-1]  # (n_freqs, n_mels)
    up_slopes = slopes[:, 2:] / f_diff[1:]  # (n_freqs, n_mels)
    fb = torch.max(zero, torch.min(down_slopes, up_slopes))
    return fb


class VtlpMelScale(torch.nn.Module):

    __constants__ = ["n_mels", "sample_rate", "f_min", "f_max"]

    def __init__(
        self, n_mels=80, sample_rate=8000, f_min=0.0, f_max=None, n_stft=None
    ):
        super().__init__()
        self.n_mels = n_mels
        self.sample_rate = sample_rate
        self.f_max = f_max if f_max is not None else float(sample_rate // 2)
        self.f_min = f_min

        assert f_min <= self.f_max, "Require f_min: %f < f_max: %f" % (
            f_min,
            self.f_max,
        )

    def forward(self, specgram):
        # pack batch
        shape = specgram.size()
        specgram = specgram.reshape(-1, shape[-2], shape[-1])

        fb = create_vtlp_fb_matrix(
            specgram.size(1),
            self.f_min,
            self.f_max,
            self.n_mels,
            self.sample_rate,
            random.random() * 0.20 + 0.80,
            training=self.training,
        ).to(specgram.device)
        # (channel, frequency, time).transpose(...) dot (frequency, n_mels)
        # -> (channel, time, n_mels).transpose(...)
        print(specgram.shape)
        print(fb.shape)
        mel_specgram = torch.matmul(specgram, fb).transpose(1, 2)
        # unpack batch
        mel_specgram = mel_specgram.reshape(shape[:-2] + mel_specgram.shape[-2:])
        return mel_specgram


if __name__ == "__main__":
    filter_banks = torch.tensor(readwrite.read_raw_mat(join(mspec_file, key), 80).T)
    print("Shape:", filter_banks.shape)

    specgram = torchaudio.transforms.MelSpectrogram(n_mels=80, n_fft=80)
    vtlp_features = specgram.mel_scale(filter_banks).numpy()

    readwrite.write_raw_mat(vtlp_features, output)
