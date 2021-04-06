# IMPORT statements

import parselmouth
import tgt
import csv
import io
import numpy as np
import pandas as pd
from scipy.signal import savgol_filter
from scipy.stats import kde
from scipy.spatial import ConvexHull

import matplotlib.pyplot as plt
%matplotlib inline
import seaborn as sns

sns.set() # Use seaborn's default style to make attractive graphs

get_formants(path, gender):
    """Return the cleaned formants from a sound file: smoothed, and
    voiced intervals only

    Returned as a Pandas dataframe with the following columns:
    "row", "time(s)", "nformants", "F1(Hz)", "F2(Hz)", "F3(Hz)", "F4(Hz)", "F5(Hz)"

    keyword arguments:
    path -- the path to a sound file whose formants will be found
    gender -- the gender of the (single) speaker in the sound file
              (used to tailor some formant calculation parameters)
    """        

    # CONSTANTS

    # Formant analysis parameters
    time_step = 0.005
    max_formant_num = 5
    if gender == "male":
        max_formant_freq = 5500
    elif gender == "female":
        max_formant_freq = 5000
    else:
        sys.exit("get_formants: Improper gender: {}".format(gender))
    window_length = 0.025
    preemphasis = 50

    # Pitch analysis parameters
    pitch_time_step = 0.005
    pitch_floor = 60
    max_candidates = 15
    very_accurate = False
    silence_thresh = 0.03
    voicing_thresh = 0.7
    octave_cost = 0.01
    oct_jump_cost = 0.35
    vuv_cost = 0.14
    pitch_ceiling = 600.0
    max_period = 0.02

    # Other constants
    tier = 1

    # Get raw formants
    sound = parselmouth.Sound(path)
    raw_formants = sound.to_formant_burg(time_step, max_formant_num,
                                     max_formant_freq, window_length,
                                     preemphasis)

    formant_table = parselmouth.praat.call(raw_formants, "Down to Table...",
                                           False, True, 6, False, 3, True, 3,
                                           False)

    formant_df = pd.read_csv(io.StringIO(parselmouth.praat.call(data_table,
                                                                "List", True)),
                                         sep='\t')

    # Smooth formants: window size 5, polynomial order 3

    formant_df["F1(Hz)"] = savgol_filter(formant_df["F1(Hz)"], 5, 3)
    formant_df["F2(Hz)"] = savgol_filter(formant_df["F2(Hz)"], 5, 3)
    formant_df["F3(Hz)"] = savgol_filter(formant_df["F3(Hz)"], 5, 3)

    # Get voiced intervals:
    pitch = sound.to_pitch_ac(pitch_time_step, pitch_floor, max_candidates,
                          very_accurate, silence_thresh, voicing_thresh,
                          octave_cost, oct_jump_cost, vuv_cost, pitch_ceiling)

    mean_period = 1/parselmouth.praat.call(pitch, "Get quantile", 0.0, 0.0, 0.5, "Hertz")
    pulses = parselmouth.praat.call([sound, pitch], "To PointProcess (cc)")
    tgrid = parselmouth.praat.call(pulses, "To TextGrid (vuv)", 0.02, mean_period)
    VUV = pd.DataFrame(pd.read_csv(io.StringIO(tgt.io.export_to_table(tgrid.to_tgt(),
                                                                      separator=','))))
    voiced_interval_array = pd.IntervalIndex.from_arrays(VUV['start_time'][VUV["text"] == "V"],
                                                     VUV['end_time'][VUV["text"] == "V"],
                                                     closed='left')
    formant_voiced = formant_df[voiced_interval_array.get_indexer(formant_df["time(s)"].values) != -1]

    # TODO: Add formant range checking here
    # For now: remove any rows where less than four formants were found
    filter = formant_voiced["nformants"] > 3
    return formant_voiced(filter)
