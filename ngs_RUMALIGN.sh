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
# SINGLE-END READS
# INPUT: trimAT/unaligned_1.fq
# OUTPUT: rum.trim/RUM.sam
#
# PAIRED-END READS
# INPUT: trimAT/unaligned_1.fq and trimAT/unaligned_2.fq
# OUTPUT: rum.trim/RUM.sam
#
# REQUIRES: RUM version 2
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_RUMALIGN="Usage: `basename $0` rumalign OPTIONS sampleID    --   run RUM on trimmed reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_RUMALIGN="Usage: `basename $0` rumalign -p numProc -s species [-se] sampleID\n"
ngsHelp_RUMALIGN+="\tRuns RUM using the trimmed files from trimAT. Output is stored in directory 'rum.trim'.\n"
ngsHelp_RUMALIGN+="\tOPTIONS:\n"
ngsHelp_RUMALIGN+="\t\t-p numProc - number of cpu to use.\n"
ngsHelp_RUMALIGN+="\t\t-s species - species files are located in $RUM_REPO ('drosophila', 'hg19', 'mm9', 'mm10', 'rat', 'rn5', 'saccer3', 'zebrafish').\n"
ngsHelp_RUMALIGN+="\t\t-se - single-end reads (default: paired-end)"

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# RUMALIGN args: -p value, -s value, -se (optional), sampleID
##########################################################################################

ngsArgs_RUMALIGN() {
	if [ $# -lt 5 ]; then
		printHelp $COMMAND
		exit 0
	fi
	
	# getopts doesn't allow for optional arguments so handle them manually
	while true; do
		case $1 in
			-p) NUMCPU=$2
				shift; shift;
				;;
			-s) SPECIES=$2
				shift; shift;
				;;
			-se) SE=true
				shift;
				;;
			-*) printf "Illegal option: '%s'\n" "$1"
				printHelp $COMMAND
				exit 0
				;;
			*) break ;;
		esac
	done
	
	SAMPLE=$1
}


##########################################################################################
# RUNNING COMMAND ACTION
# Run RUM job, assuming RUM version 2.
##########################################################################################

ngsCmd_RUMALIGN() {
	if $SE; then prnCmd "# BEGIN: RUM SINGLE-END ALIGNMENT"
	else prnCmd "# BEGIN: RUM PAIRED-END ALIGNMENT"; fi
	
	# make relevant directory
	if [ ! -d $SAMPLE/rum.trim ]; then 
		prnCmd "mkdir $SAMPLE/rum.trim"
		if ! $DEBUG; then mkdir $SAMPLE/rum.trim; fi
	fi
	
	# print version info in journal file
	prnCmd "# `rum_runner version`"
	
	if $SE; then
		# single-end
		prnCmd "rum_runner align --output $SAMPLE/rum.trim --name $SAMPLE --index $RUM_REPO/$SPECIES --chunks $NUMCPU $SAMPLE/trimAT/unaligned_1.fq"
		if ! $DEBUG; then 
			rum_runner align --output $SAMPLE/rum.trim --name $SAMPLE --index $RUM_REPO/$SPECIES --chunks $NUMCPU $SAMPLE/trimAT/unaligned_1.fq
		fi
		
		prnCmd "# FINISHED: RUM SINGLE-END ALIGNMENT"
	else
		# paired-end
		prnCmd "rum_runner align --output $SAMPLE/rum.trim --name $SAMPLE --index $RUM_REPO/$SPECIES --chunks $NUMCPU $SAMPLE/trimAT/unaligned_1.fq $SAMPLE/trimAT/unaligned_2.fq"
		if ! $DEBUG; then 
			rum_runner align --output $SAMPLE/rum.trim --name $SAMPLE --index $RUM_REPO/$SPECIES --chunks $NUMCPU $SAMPLE/trimAT/unaligned_1.fq $SAMPLE/trimAT/unaligned_2.fq
		fi
		
		prnCmd "# FINISHED: RUM PAIRED-END ALIGNMENT"
	fi
}