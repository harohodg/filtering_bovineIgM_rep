#!/usr/bin/env bash


#Small script for extracting sequences from fasta/fastq files on Digital Research Alliance of Canada infrastructure 
#using Seqkit 2.3.1.
#Code currently uses --immediate-output -only-positive-strand  flags with seqkit locate
#--use-regexp is used if --max-mismatches is not used 
#--non-greedy is used if -g is not passed in

#Tested on Graham.
#Has not been benchmarked yet.

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : March 13, 2023
#        - functional code with minimal error checking
#
#To Do
#   - add flags for min/max length filter

VERSION='1.0.0'
DEFAULT_THREADS=${SLURM_JOB_CPUS_PER_NODE:-1}
DEFAULT_SEPARTOR="\t"

>&2 echo "seqkit_extract_sequences.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d] [-m maxMismatches] [-g greedy] [-s separator (default '$DEFAULT_SEPARTOR')] [-t num threads (default $DEFAULT_THREADS)] <inputFile.fasta/fastq> <searchPattern>" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2;
    echo "Use -m # to allow # mismatches. Does not work with regex patterns" 1>&2;
    echo "Use -g to enable greedy matches. Ie each match will be printed to a new line" 1>&2;
    echo "Use -s separator to set the output separator" 1>&2;
    echo "If not on a compute node the default number of threads is 1."     1>&2;
    exit 1; 
}


while getopts ":dt:m:gs:" o; do
    case "${o}" in
        d)  
            debug=1
            ;;
        t)
            numThreads="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $numThreads =~ $re ]] ; then
               echo "error: number of threads is not a number" >&2; exit 1
            fi
            ;;
        g)  
            greedy=1
            ;;
        m)  
            misMatches="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $misMatches =~ $re ]] ; then
               echo "error: number of mismatches is not a number" >&2; exit 1
            fi
            ;;
        s)
            separator="$OPTARG"
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))



if [[ "$#" -lt 2 ]]; then
    echo 'Incorrect number of arguments.'
    usage
else
    inputFile="$1"
    searchPattern="$2"
fi

moduleLoad='module load StdEnv/2020 seqkit/2.3.1' 
separator=${separator:-$DEFAULT_SEPARTOR}
numThreads=${numThreads:-$DEFAULT_THREADS}
if [ -z "$greedy" ];then
    greedyFlag="--non-greedy"
fi
if [ -n "$misMatches" ];then
    mismatchesFlag="--max-mismatch ${misMatches}"
else
    regexFlag="--use-regexp"
fi


#jobCommand=$(printf $'%s && seqkit locate --threads %d --immediate-output %s --only-positive-strand %s %s --line-width 0 --pattern \'%s\' %s %s | awk -v OFS=\'%s\' \'{ if (NR == 1) {print $1,$2,$3,$4,$5,$6,"length",$7}  else {print $1,$2,$3,$4,$5,$6,$6-$5+1,$7}}\'' "${moduleLoad}" "${numThreads}" "${greedyFlag}" "${regexFlag}" "${mismatchesFlag}" "${searchPattern}" "${inputFile}" "${separator}")
jobCommand="${moduleLoad} && seqkit locate --threads ${numThreads} --immediate-output ${greedyFlag} ${regexFlag} ${mismatchesFlag} --only-positive-strand --pattern ${searchPattern} ${inputFile} | awk -v OFS='${separator}'"$' \'{ if (NR == 1) { {print $1,$2,$3,$4,$5,$6,"length",$7} } else {print $1,$2,$3,$4,$5,$6,$6-$5+1,$7} }\' '

if [ -n "$debug" ];then
    echo "$jobCommand"
else
    printf "Running seqkit/2.3.1 with\n%s\n" "${jobCommand}" >&2
    
    eval "$jobCommand" && echo -n 'DONE' >&2  || echo -n 'FAILED' >&2
    
    echo " running seqkit" >&2
fi
