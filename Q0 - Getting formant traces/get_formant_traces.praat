# get_formant_traces.praat
#    """Find F1 through F4 values for a Sound object and write them to a CSV;
#       additionally, find the voiced intervals from that Sound object and
#       write the interval boundary times to a CSV.
#    """
#
# Sources:
#   voiced_extract_auto.txt
#     v 20020423 John Tøndering, modified quite a lot by Niels Reinholt Petersen
#     v 20200817 modified by Eric Jackson to run in Praat 6.0.04 (2015-11-01)
#
#     The extraction is made without the user having to specify arguments for
#       the "To Pitch (ac)" and "To TextGrid" commands. These have now been
#       moved to a block of constants within this script. Testing the script
#       on a number of sentences 15 - 20 seconds long spoken by normal and
#       pathological voices has shown that a reasonably correct extraction of
#       voiced intervals can be achieved by the values of arguments specified
#       below for the To Pitch (ac) and To TextGrid (vuv) commands if the
#       mean_period (To TextGrid (vuv)) varies as a function of the median F0
#       of the Sound object. The script will handle fundamental frequencies
#       between 60 and 600 Hz. If F0 is lower (e.g. in a creaky male voice) or
#       higher (e.g. in a voice using the falsetto register) the 'manually
#       operated' version voiced_extract.psc should be used.
#
#      The original goal of my 2020 rewrite of this script was to first modify
#       a new Sound object so that it consisted only of the voiced segments
#       from the original object, then calculate the formant traces on this
#       new Sound. However, this results in problematic formant values at each
#       point where the window used for formant calculation spans the boundary
#       where an unvoiced segment was removed. To address this, the formant
#       calculation is now done on the original file, but time points for
#       each voiced segment are output, as well. These can be used in Pandas
#       to filter the formant traces and remove unvoiced sections there. (It
#       should be possible to perform this same check in Praat, also, but by
#       passing the whole formant traces to Pandas, smoothing can be done
#       there prior to the removal of unvoiced segments.
#       

# CONSTANTS

# Formant analysis parameters
#   FOR A WOMAN:
# To Formant (burg)... 0.005 5.0 5500.0 0.025 50.0
#   FOR A MAN:
# To Formant (burg)... 0.005 5.0 5000.0 0.025 50.0

time_step = 0.005
max_formant_num = 5
max_formant_freq = 5500
window_length = 0.025
preemphasis = 50

# Pitch analysis parameters
pitch_time_step = 0.005
pitch_floor = 60
max_candidates = 15
very_accurate = 0
silence_thresh = 0.03
voicing_thresh = 0.7
octave_cost = 0.01
oct_jump_cost = 0.35
vuv_cost = 0.14
pitch_ceiling = 600.0
max_period = 0.02

# Other constants
tier = 1
outfile_vuv$ = "/home/emj/ActiveFiles/Personal Development/Personal projects/Vocoid heatmap/Q0 - Getting formant traces/voiced_intervals.csv"

# SCRIPT START

# 1. Check whether the result file exists:
if fileReadable (outfile_vuv$)
	pause The file 'outfile_vuv$' already exists! Do you want to overwrite it?
	filedelete 'outfile_vuv$'
endif

# Create a header row for the result file: (remember to edit this if you add or change the analyses!)
header$ = "interval	start	finish'newline$'"
fileappend "'outfile_vuv$'" 'header$'


# 2. Generate pitch track from sound, use that to find Voiced / Unvoiced intervals
name$ = selected$("Sound")

select Sound 'name$'
To Pitch (ac)... pitch_time_step pitch_floor max_candidates very_accurate silence_thresh voicing_thresh octave_cost oct_jump_cost vuv_cost pitch_ceiling

median_f0 = Get quantile... 0 0 0.5 Hertz
mean_period = 1/median_f0

select Sound 'name$'
plus Pitch 'name$'

To PointProcess (cc)
To TextGrid (vuv)... max_period mean_period

# 3. For each interval, output start and end time to file
numberOfIntervals = Get number of intervals... tier

# Pass through all intervals in the designated tier, and if they are voiced, find the start and end time
for interval to numberOfIntervals
	label$ = Get label of interval... tier interval
	if label$ == "V"
		interval$ = string$: interval
		start = Get starting point... tier interval
		start$ = string$: start
		end = Get end point... tier interval
		end$ = string$: end

		# Save result to text file:
		resultline$ = interval$ + tab$ + start$ + tab$ + end$ + newline$
		fileappend "'outfile_vuv$'" 'resultline$'

		# select the TextGrid so we can iterate to the next interval:
		select TextGrid 'name$'_'name$'
	endif
endfor

# 4. Calculate and write out formants for this Sound object
select Sound 'name$'
To Formant (burg)... time_step max_formant_num max_formant_freq window_length preemphasis

Down to Table... no yes 6 no 3 yes 3 no
Save as tab-separated file: name$ + "_formants.csv"

