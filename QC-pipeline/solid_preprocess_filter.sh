#!/bin/sh
#
# Script to run SOLiD_preprocess_filter steps on SOLiD data
#
# Usage: solid_preprocess_filter.sh [options] <csfasta> <qual>
#
function usage() {
    echo "Usage: solid_process_filter.sh [options] <csfasta> <qual>"
    echo ""
    echo "Run SOLiD_preprocess_filter_v2.pl script and calculate filtering"
    echo "statistics."
    echo ""
    echo "Options:"
    echo ""
    echo "By default the preprocess/filter program is run using FLS Bioinf"
    echo "settings."
    echo ""
    echo "However: any options explicitly specified on the command line are"
    echo "used instead of the FLS Bioinf settings (which are essentially"
    echo "ignored, with the defaults for any parameter reverting to those"
    echo "in the underlying SOLiD_preprocess_filter_v2.pl program)."
    echo ""
    echo "Input"
    echo "  csfasta and qual file pair"
    echo ""
    echo "Output"
    echo "  <csfasta_base>_T_F3.csfasta and <cfasta_base>_QV_T_F3.qual"
}
# Check command line
if [ $# -lt 2 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
    usage
    exit
fi
#
#===========================================================================
# Import function libraries
#===========================================================================
#
if [ -f functions.sh ] ; then
    # Import local copies
    . functions.sh
else
    # Import versions in share
    . `dirname $0`/../share/functions.sh
fi
#
#===========================================================================
# Main script
#===========================================================================
#
# Set umask to allow group read-write on all new files etc
umask 0002
#
# Collect the user arguments to supply to SOLiD_preprocess_filter
while [ $# -gt 2 ] ; do
    FILTER_OPTIONS="$FILTER_OPTIONS $1"
    shift
done
#
# Collect inputs
csfasta=$(abs_path $1)
qual=$(abs_path $2)
#
# Check files exist
if [ ! -f "$csfasta" ] ; then
    echo "ERROR csfasta file not found: $csfasta"
    usage
    exit 1
fi
if [ ! -f "$qual" ] ; then
    echo "ERROR qual file not found: $qual"
    usage
    exit 1
fi
#
# Set up environment
QC_SETUP=`dirname $0`/qc.setup
if [ -f "${QC_SETUP}" ] ; then
    echo Sourcing qc.setup to set up environment
    . ${QC_SETUP}
else
    echo WARNING qc.setup not found in `dirname $0`
fi
#
# Set the programs
# Override these defaults by setting them in qc.setup
: ${SOLID_PREPROCESS_FILTER:=SOLiD_preprocess_filter_v2.pl}
: ${FILTER_OPTIONS:="-x y -p 3 -q 22 -y y -e 10 -d 9"}
#
# Report
echo ========================================================
echo SOLiD_preprocess_filter
echo ========================================================
echo Started   : `date`
echo Running in: `pwd`
echo csfasta   : $csfasta
echo qual      : $qual
echo Filter options: $FILTER_OPTIONS
#
# Output file names
processed_csfasta=$(baserootname $csfasta)_T_F3.csfasta
processed_qual=$(baserootname $csfasta)_QV_T_F3.qual
#
# Check if processed files already exist
if [ -f "${processed_csfasta}" ] && [ -f "${processed_qual}" ] ; then
    echo Filtered csfasta and qual files already exist, skipping preprocess filter
else
    # Make a temporary directory to run in
    # This stops incomplete processing files being written to the working
    # directory which might be left behind if the preprocessor stops (or
    # is stopped) prematurely
    wd=`pwd`
    tmp=`mktemp -d`
    cd $tmp
    echo "Working in temporary directory ${tmp}"
    # Run preprocessor
    cmd="${SOLID_PREPROCESS_FILTER} -o $(baserootname $csfasta) ${FILTER_OPTIONS} -f ${csfasta} -g ${qual}"
    echo $cmd
    $cmd
    # Move back to working dir and copy preprocessed files
    cd $wd
    if [ -f "${tmp}/${processed_csfasta}" ] ; then
	/bin/cp ${tmp}/${processed_csfasta} .
	echo Created ${processed_csfasta}
    else
	echo WARNING no file ${processed_csfasta}
    fi
    if [ -f "${tmp}/${processed_qual}" ] ; then
	/bin/cp ${tmp}/${processed_qual} .
	echo Created ${processed_qual}
    else
	echo WARNING no file ${processed_csfasta}
    fi
    # Remove temporary dir
    /bin/rm -rf ${tmp}
fi
#
# Filter statistics: run separate filtering_stats.sh script
FILTERING_STATS=`dirname $0`/filtering_stats.sh
if [ -f "${FILTERING_STATS}" ] ; then
    if [ -f "${processed_csfasta}" ] ; then
	${FILTERING_STATS} ${csfasta} SOLiD_preprocess_filter.stats
    else
	echo ERROR output csfasta file not found, filtering stats calculcation skipped
    fi
else
    echo ERROR ${FILTERING_STATS} not found, filtering stats calculation skipped
fi
#
echo solid_preprocess_filter completed: `date`
exit
##
#
