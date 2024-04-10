#!/bin/bash
#SBATCH -t 1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G

#Script for running fastp on all *.fastq.gz files in an input folder on Digital Research Alliance Infrastructure.
#Puts results in output_folder/<file_basename>/<file_basename-fastp>
#Has not been benchmarked yet. Does not check for pre-existing output folder

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : March 29, 2024
#        - functional code with minimal error checking
#    Version 1.0.1 : April 10, 2024
#        - fixed bug with how SCRIPT DIR was calculated

VERSION='1.0.1'
DEFAULT_MIN_LENGTH=700
DEFAULT_MAX_LENGTH=1200

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [ -n "${SLURM_JOB_ID:-}" ] ; then
    command_run=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
    if [ "$command_run" != "/bin/sh" ]; then
        SCRIPT_DIR=$(dirname "${command_run}" )
    fi
fi

>&2 echo "fastp-filtering.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d] [-D] [-m min_read_length (default '$DEFAULT_MIN_LENGTH')] [-M max_read_length (default '$DEFAULT_MAX_LENGTH')]  <input_folder> <output_folder>" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2;
    echo "Use -D to run fastp with dedup flag set." 1>&2;
    echo "Set min/max length flags to zero to disable length filtering" 1>&2;
    echo "Should not be run on a login node."     1>&2;
    exit 1; 
}


while getopts ":dDm:M:" o; do
    case "${o}" in
        d)  
            debug=1
            ;;
        D)
            deduplicate=1
            ;;
        m)  
            min_read_length="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $min_read_length =~ $re ]] ; then
               echo "error: min_read_length ($min_read_length) is not a number" >&2; exit 1
            fi
            ;;
        M)  
            max_read_length="$OPTARG"
            re='^[0-9]+$'
            if ! [[ $max_read_length =~ $re ]] ; then
               echo "error: max_read_length ($max_read_length) is not a number" >&2; exit 1
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

if [[ "$#" -ne 2 ]]; then
    echo 'Incorrect number of arguments.'
    usage
else
    input_folder=$(realpath "$1")
    output_folder=$(realpath --canonicalize-missing "$2")
fi
tmp_output_folder=${output_folder}.partial
nextflow_temp_folder=${output_folder}-nextflow_scratch
min_read_length=${min_read_length:-$DEFAULT_MIN_LENGTH}
max_read_length=${max_read_length:-$DEFAULT_MAX_LENGTH}
deduplication_flag=${deduplicate:+'--deduplicate_reads yes'}

module_load='module load StdEnv/2020 nextflow/23.04.3'
command="${module_load} && mkdir -p ${tmp_output_folder} && NXF_WORK=${nextflow_temp_folder} nextflow run -pool-size "'$SLURM_CPUS_ON_NODE'" -resume ${SCRIPT_DIR}/fastp_filtering.nf --input_folder ${input_folder}  --output_dir ${tmp_output_folder} --min_read_length ${min_read_length} --max_read_length ${max_read_length} ${deduplication_flag} && mv ${tmp_output_folder} ${output_folder} && rm -r ${nextflow_temp_folder}"

if [ -n "$debug" ];then
    echo "$command"
else  
    echo                       >&2
    echo "${command}"          >&2
    echo                       >&2
    echo '-------------------' >&2
    echo
    
    eval "$command" && echo 'DONE' >&2  || echo 'FAILED' >&2
fi

