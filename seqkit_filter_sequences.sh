#!/usr/bin/env bash


#Small script for filtering fasta/fastq files on Digital Research Alliance of Canada infrastructure 
#using Seqkit 2.3.1. 
#Code currently assumes all data files are DNA not RNA when asked to generate reverse complement.
#Code currently uses --by-seq --only-positive-strand --immediate-output --line-width 0 flags with seqkit grep
#--use-regexp is used if --max-mismatches is not used

#Tested on Graham.
#Has not been benchmarked yet.

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : March 13, 2023
#        - functional code with minimal error checking
#
#   Version 1.1 : March 16, 2023
#       - added flags for filtering by min/max length


VERSION='1.1.0'
DEFAULT_THREADS=${SLURM_JOB_CPUS_PER_NODE:-1}

>&2 echo "seqkit_filter_sequences.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d] [-m maxMismatches] [-l min_length] [-n max_length] [-t numThreads (default=$DEFAULT_THREADS)] [-i (invert match)]  [-r (reverse complement output)] [-p searchPattern -P replacementPattern ] <inputFile.fasta/fastq> <searchPattern>" 1>&2;
    echo "Use -l and -h to set min and max length of sequences" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2;
    echo "If not on a compute node the default number of threads is 1."     1>&2;
    echo "Use -i to invert the match (ie print all sequences that don't match)" 1>&2;
    echo "Use -r to reverse complement the matching/non matching sequences" 1>&2;
    echo "Use -m # to allow # mismatches. Does not work with regex patterns" 1>&2;
    echo "Use -p searchPattern -P replacementPattern to rename the headers" 1>&2;
    echo "Example : -p '.*(read=\d+)\s+(ch=\d+).*' -P 'filtered:"'$1:$2'"'" 1>&2;
    exit 1; 
}


while getopts ":drip:P:t:m:l:n:" o; do
    case "${o}" in
        d)  
            debug=1
            ;;
        r)  
            reverse=1
            ;;
        i)  
            invert=1
            ;;
        m)  
            misMatches="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $misMatches =~ $re ]] ; then
               echo "error: number of mismatches is not a number" >&2; exit 1
            fi
            ;;
        p)  
            pattern="${OPTARG}"
            ;;
        P)  
            replacement="${OPTARG}"
            ;;
        t)
            numThreads="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $numThreads =~ $re ]] ; then
               echo "error: number of threads (${numThreads}) is not a number" >&2; exit 1
            fi
            ;; 
        l)
            minLength="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $minLength =~ $re ]] ; then
               echo "error: min sequence length (${minLength}) is not a number" >&2; exit 1
            fi
            ;;  
        n)
            maxLength="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $maxLength =~ $re ]] ; then
               echo "error: max sequence length (${maxLength}) is not a number" >&2; exit 1
            fi
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


if [ -n "$pattern" ] && [ -z "$replacement" ]; then
  echo 'ERROR : -p and -P both needs values' >&2
  usage
elif [ -z "$pattern" ] && [ -n "$replacement" ]; then
  echo 'ERROR : -p and -P both needs values' >&2
  usage
fi


moduleLoad='module load StdEnv/2020 seqkit/2.3.1'
numThreads=${numThreads:-$DEFAULT_THREADS}
invertMatchFlag=${invert:+"--invert-match"}
minLengthFlag=${minLength:+"--min-len ${minLength}"}
maxLengthFlag=${maxLength:+"--max-len ${maxLength}"}
headerReplacementFlags=${pattern:+"--pattern '${pattern}' --replacement '${replacement}'"}
if [ -n "$misMatches" ];then
    mismatchesFlag="--max-mismatch ${misMatches}"
else
    regexFlag="--use-regexp"
fi
 
grepCommand=$(printf " && seqkit grep --threads %d %s %s %s --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern '%s'  %s " "${numThreads}" "${invertMatchFlag}" "${regexFlag}" "${mismatchesFlag}" "${searchPattern}" "${inputFile}")
if [ -n "$pattern" ] || [ -n "$minLengthFlag" ] || [ -n "$maxLengthFlag" ]; then
    replaceHeader=$(printf "| seqkit replace --threads %d %s %s %s --line-width 0" "${numThreads}" "${headerReplacementFlags}" "${minLengthFlag}" "${maxLengthFlag}")
fi


if [ -n "$reverse" ];then
    reverseComplement=$(printf '| seqkit seq --threads %d --reverse --complement --seq-type DNA --line-width 0' "${numThreads}")
fi

jobCommand=$(printf '%s %s %s %s' "${moduleLoad}" "${grepCommand}" "${replaceHeader}" "${reverseComplement}")


if [ -n "$debug" ];then
    echo "$jobCommand"
else
    printf "Running seqkit/2.3.1 with\n%s\n" "${jobCommand}" >&2
    
    eval "$jobCommand" && echo -n 'DONE' >&2  || echo -n 'FAILED' >&2
    
    echo " running seqkit" >&2
fi
