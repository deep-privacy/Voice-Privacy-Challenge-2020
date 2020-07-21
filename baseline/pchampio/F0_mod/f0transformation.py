import numpy as np
        

"""
F0 conversionusing a linear mean-variance transformation in the log-F0 domain

Taken from: https://github.com/unilight/cdvae-vc/blob/6470b0e587d40f6d1d91712a0dacef5ff8d661ce/util/f0transformation.py
"""

def log_linear_transformation(f0, stats):
    """
    linear transformation of log-f0
    """


    lf0 = np.where(f0 > 1, f0, 0)
    np.log(lf0, out=lf0, where=lf0 > 0)
    mu_o = lf0.mean()
    lf0 = np.where(lf0 > 1., (lf0 - stats['mu_s'])/stats['std_s'] * stats['std_t'] + stats['mu_t'], lf0)
    mu_t = lf0.mean()
    f0t = np.where(lf0 > 1., np.exp(lf0), lf0)
    #  if mu_o > mu_t:
        #  # don't transfomation the f0 so that we compress down the info (don't make it sond grave)
        #  f0t = f0


    return f0t
