#
# Original Author: Robert Balas (balasr@iis.ee.ethz.ch)
#
###############################################################################

###############################################################################
# Common functions

# Map multiple flag values to "YES" or NO
# Use like this, to test variable MYVAR
# ifeq ($(call IS_YES($(MYVAR)),YES)
YES_VALS=Y YES 1 y yes TRUE true enable
IS_YES=$(if $(filter $(YES_VALS),$(1)),YES,NO)
NO_VALS=N NO 0 n no FALSE false
IS_NO=$(if $(filter $(NO_VALS),$(1)),NO,YES)

###############################################################################
# Common variables
BANNER=*******************************************************************************************

###############################################################################


