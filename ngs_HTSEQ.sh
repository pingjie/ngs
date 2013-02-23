#!/bin/bash

# Copyright (c) 2012,2013, Stephen Fisher and Junhyong Kim, University of
# Pennsylvania.  All Rights Reserved.
#
# You may not use this file except in compliance with the Kim Lab License
# located at
#
#     http://kim.bio.upenn.edu/software/LICENSE
#
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License
# for the specific language governing permissions and limitations
# under the License.

##########################################################################################
# INPUT: rum.trim/RUM_Unique.sorted.bam
# OUTPUT: htseq/$SAMPLE.htseq.cnts.txt, htseq/$SAMPLE.htseq.log.txt, htseq/$SAMPLE.htseq.err.txt
# REQUIRES: HTSeq, runHTSeq.py
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_HTSEQ="Usage: `basename $0` htseq OPTIONS sampleID    --  run HTSeq on RUMs unique mappers\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_HTSEQ="Usage: `basename $0` htseq -s species -g prefix sampleID\n"
ngsHelp_HTSEQ+="\tRun HTSeq using runHTSeq.py script. This requires the sorted BAM file containing unique reads that is generated by 'post'.\n"
ngsHelp_HTSEQ+="\tOPTIONS:\n"
ngsHelp_HTSEQ+="\t\t-s species - species files 'drosophila', 'hg19', 'mm9', 'mm10', 'rat', 'rn5', 'saccer3', and 'zebrafish' are located in /lab/repo/resources/rum2.\n"
ngsHelp_HTSEQ+="\t\t-g prefix - identifier to extract all gene IDs from output. For example 'ENSDARG' is prefix for all zebrafish genes."

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# HTSEQ args: -s value, -g value, sampleID
##########################################################################################

ngsArgs_HTSEQ() {
	if [ $# -lt 5 ]; then
		printHelp $COMMAND
		exit 0
	fi
	
	while getopts "s:g:" opt; do
		case $opt in
			s) SPECIES=$OPTARG
				;;
			g) PREFIX=$OPTARG
				;;
			?) printf "Illegal option: '%s'\n" "$OPTARG"
				printHelp $COMMAND
				exit 0
				;;
		esac
	done
	shift $((OPTIND - 1))   # remove options from argument list
	
	SAMPLE=$1
}

##########################################################################################
# RUNNING COMMAND ACTION
# Run HTSeq on uniqely mapped RUM output and sorted by the POST command.
##########################################################################################

ngsCmd_HTSEQ() {
	prnCmd "# BEGIN: RUNNING HTSEQ"
	
	# make relevant directory
	if [ ! -d $SAMPLE/htseq ]; then 
		prnCmd "mkdir $SAMPLE/htseq"
		if ! $DEBUG; then mkdir $SAMPLE/htseq; fi
	fi
	
	# We assume that RUM worked and 'post' has completed.
	prnCmd "runHTSeq.py $SAMPLE/rum.trim/RUM_Unique.sorted.bam $SAMPLE/htseq/$SAMPLE $HTSEQ_REPO/$SPECIES/$SPECIES.gz"
	if ! $DEBUG; then 
		runHTSeq.py $SAMPLE/rum.trim/RUM_Unique.sorted.bam $SAMPLE/htseq/$SAMPLE $HTSEQ_REPO/$SPECIES/$SPECIES.gz
	fi
	
	# parse output into three files: gene counts ($SAMPLE.htseq.cnts.txt), 
	# warnings ($SAMPLE.htseq.err.txt), log ($SAMPLE.htseq.log.txt)
	prnCmd "grep $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
	prnCmd "grep -v $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out | grep -v Warning > $SAMPLE/htseq/$SAMPLE.htseq.log.txt"
	prnCmd "grep -v $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out | grep Warning > $SAMPLE/htseq/$SAMPLE.htseq.err.txt"
	prnCmd "rm $SAMPLE/htseq/$SAMPLE.htseq.out"
	if ! $DEBUG; then 
		grep $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt
		grep -v $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out | grep -v Warning > $SAMPLE/htseq/$SAMPLE.htseq.log.txt
		grep -v $PREFIX $SAMPLE/htseq/$SAMPLE.htseq.out | grep Warning > $SAMPLE/htseq/$SAMPLE.htseq.err.txt
		rm $SAMPLE/htseq/$SAMPLE.htseq.out
	fi
	
	prnCmd "# FINISHED: RUNNING HTSEQ"
}