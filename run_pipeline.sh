#!/bin/bash
#SBATCH -t 1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G

#Script for running entire filtering pipeline with default parameters on Digital Research Alliance Infrastructure.
#Has not been benchmarked yet. Does not check for pre-existing output folder

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : April 08, 2024
#        - functional code with minimal error checking


VERSION='1.0.0'

if [ -n "${SLURM_JOB_ID:-}" ] ; then
    SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}') )
else
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi


>&2 echo "run_pipeline.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d] <input_folder> <output_folder>" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2;
    echo "Should not be run on a login node."     1>&2;
    exit 1; 
}


while getopts ":d" o; do
    case "${o}" in
        d)  
            debug=1
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

command1="module load StdEnv/2020 && mkdir -p ${tmp_output_folder} && chmod +x ${SCRIPT_DIR}/fastp_filtering.sh ${SCRIPT_DIR}/IgM_filtering.sh ${SCRIPT_DIR}/fastqc.sh"
command2="${SCRIPT_DIR}/fastp_filtering.sh -D ${input_folder} ${tmp_output_folder}/fastp-filtered"
command3="${SCRIPT_DIR}/IgM_filtering.sh  ${tmp_output_folder}/fastp-filtered ${tmp_output_folder}/IgM-filtered"
command4="${SCRIPT_DIR}/fastqc.sh ${tmp_output_folder} ${tmp_output_folder}/fastqc_data"
command5="${SCRIPT_DIR}/seqkit_stats.sh ${tmp_output_folder} ${tmp_output_folder}/sequence_stats"
command6="mv ${tmp_output_folder} ${output_folder}"

command="${command1} && ${command2} && ${command3} && ${command4} && ${command5} && ${command6}"

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

