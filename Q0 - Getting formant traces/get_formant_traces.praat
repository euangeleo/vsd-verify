# get_formant_traces.praat
#
# This script extracts voiced intervals from a selected Sound object, then finds F1 through
#   F4 values for that sample
#
# Sources:
#   voiced_extract_auto.txt
#     v 20020423 John Tøndering, modified quite a lot by Niels Reinholt Petersen
#     v 20200817 modified by Eric Jackson to run in Praat 6.0.04 (2015-11-01)
#
#     The extraction is made without the user having to specify arguments for the "To Pitch (ac)"
#     and "To TextGrid" commands.
#     Testing the script on a number of sentences 15 - 20 seconds long spoken by normal and pathological
#     voices has shown that a reasonably correct extraction of voiced intervals can be achieved
#     by the values of arguments specified below for the To Pitch (ac) and To TextGrid (vuv)
#     commands if the mean_period (To TextGrid (vuv)) varies as a function of the median F0 of the Sound
#     object. The script will handle fundamental frequencies between 60 and 400 Hz. If F0 is lower
#     (e.g. in a creaky male voice) og higher (e.g. in a voice using the falsetto register) the
#     'manually operated' version voiced_extract.psc should be used.

name$ = selected$("Sound")

To Pitch (ac)... 0.01 60 15 no 0.03 0.7 0.01 0.35 0.14 400

median_f0 = Get quantile... 0 0 0.5 Hertz
mean_period = 1/median_f0

select Sound 'name$'
plus Pitch 'name$'

To PointProcess (cc)
To TextGrid (vuv)... 0.02 mean_period

select Sound 'name$'
plus TextGrid 'name$'_'name$'
Extract intervals where... 1 no "is equal to" V
numberOfSelectedSounds = numberOfSelected ("Sound")
Concatenate

for i from 1 to 'numberOfSelectedSounds'
slet_fil$ = "'name$'_V_'i'"
select Sound 'slet_fil$'
Remove
endfor

nytnavn$ = "'name$'_voiced"
select Sound chain
Rename... 'nytnavn$'
select PointProcess 'name$'_'name$'
Remove

# How did I get the formant file? I think I may have used "FormantPro.praat", 
#  but if I wanted to do it myself without such complexity, how could I do it?
#########################################
# (select output sound: <original filename>_voiced)
#   FOR A WOMAN:
# To Formant (burg)... 0.005 5.0 5500.0 0.025 50.0
#   FOR A MAN:
# To Formant (burg)... 0.005 5.0 5000.0 0.025 50.0
#
# (select Formant object)
# Down to Table (settings need to be chosen)
# (select Table object)
# (save as tab-separated file <original filename>_voiced.Table)

select Sound 'nytnavn$'
To Formant (burg)... 0.005 5.0 5000.0 0.025 50.0
select Formant 'nytnavn$'
Down to Table... no yes 6 no 3 yes 3 no
select Table 'nytnavn$'
Save as tab-separated file: nytnavn$ + ".csv"
