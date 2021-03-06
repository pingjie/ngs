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
# INPUT: $SAMPLE/raw/unaligned_1.fq
# OUTPUT: $SAMPLE/blast/blast.txt (blast output), $SAMPLE/blast/species.txt (species hit counts)
# REQUIRES: blastn (provided with Blast version 2), randomSample.py, parseBlast.py
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_BLAST="Usage: `basename $0` blast OPTIONS sampleID    --  run blast on randomly sampled subset of reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_BLAST="Usage:\n\t`basename $0` blast -p numProc -s species sampleID\n"
ngsHelp_BLAST+="Input:\n\tsampleID/orig/unaligned_1.fq\n"
ngsHelp_BLAST+="Output:\n\tsampleID/blast/blast.txt (blast output)\n\tsampleID/blast/species.txt (species hit counts)\n"
ngsHelp_BLAST+="Requires:\n\tblastn ( ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/ )\n\trandomSample.py ( https://github.com/safisher/ngs )\n\tparseBlast.py ( https://github.com/safisher/ngs )\n"
ngsHelp_BLAST+="Options:\n"
ngsHelp_BLAST+="\t-p numProc - number of cpu to use\n\n"
ngsHelp_BLAST+="\t-s species - expected species\n\n"
ngsHelp_BLAST+="Run blast on 5000 reads randomly sampled from raw/unaligned_1.fq. Blast paramters used are 'num_descriptions: 10 num_alignments: 10 word_size: 15 gapopen: 3 gapextend: 1 evalue: 1e-15'. The output is put in a directory called 'blast'. The species.txt file contains number of reads mapping to each species (mouse, rat, human, bacteria)."

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# BLAST args: -p value, sampleID
##########################################################################################

ngsArgs_BLAST() {
	if [ $# -lt 5 ]; then
		printHelp $COMMAND
		exit 0
	fi
		
	while getopts "p:s:" opt; do
		case $opt in
			p) NUMCPU=$OPTARG
				;;
			s) SPECIES=$OPTARG
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
# This will do a BLAST search on 5,000 untrimmed reads, using the nt database.
##########################################################################################

ngsCmd_BLAST() {
	prnCmd "# BEGIN: BLAST"
		
	# make relevant directory
	if [ ! -d $SAMPLE/blast ]; then 
		prnCmd "mkdir $SAMPLE/blast"
		if ! $DEBUG; then mkdir $SAMPLE/blast; fi
	fi
		
    # print version info in journal file
	prnCmd "# `blastn -version | tail -1`"
	
    # Get 5,000 randomly sampled reads
    # Usage: randomSample.py <num lines> <lines grouped> <input> <output>
	prnCmd "randomSample.py 5000 4 $SAMPLE/orig/unaligned_1.fq $SAMPLE/blast/raw.fq > $SAMPLE/blast/species.txt"
	if ! $DEBUG; then 
		randomSample.py 5000 4 $SAMPLE/orig/unaligned_1.fq $SAMPLE/blast/raw.fq > $SAMPLE/blast/species.txt
	fi
	
    # Convert fastq file to fasta file
	prnCmd "awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,\">\");print}; if(P==4)P=0; P++}' $SAMPLE/blast/raw.fq > $SAMPLE/blast/raw.fa"
	if ! $DEBUG; then 
		awk 'BEGIN{P=1}{if(P==1||P==2){gsub(/^[@]/,">");print}; if(P==4)P=0; P++}' $SAMPLE/blast/raw.fq > $SAMPLE/blast/raw.fa
	fi
	
    # Run BLAST. Output file should end with ".txt"
	prnCmd "blastn -query $SAMPLE/blast/raw.fa -db nt -num_descriptions 10 -num_alignments 10 -word_size 15 -gapopen 3 -gapextend 1 -evalue 1e-15 -num_threads $NUMCPU -out $SAMPLE/blast/blast.txt"
	if ! $DEBUG; then 
		blastn -query $SAMPLE/blast/raw.fa -db nt -num_descriptions 10 -num_alignments 10 -word_size 15 -gapopen 3 -gapextend 1 -evalue 1e-15 -num_threads $NUMCPU -out $SAMPLE/blast/blast.txt
	fi
	
    # Parse BLAST output. Will generate *.cvs and *.hits files.
    # Usage: parseBlast.py targetSpecies readsFastaFile blastFile
	prnCmd "parseBlast.py $SPECIES $SAMPLE/blast/raw.fa $SAMPLE/blast/blast"
	if ! $DEBUG; then 
		parseBlast.py $SPECIES $SAMPLE/blast/raw.fa $SAMPLE/blast/blast.txt
	fi
	
	prnCmd "# FINISHED: BLAST"
}
