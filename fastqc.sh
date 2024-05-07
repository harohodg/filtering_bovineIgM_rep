#!/bin/bash
#SBATCH -t 0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G

#Script for running fastqc on all *.fastq.gz files in an input folder on Digital Research Alliance Infrastructure.
#Has not been benchmarked yet. Does not check for pre-existing output folder

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : April 07, 2024
#        - functional code with minimal error checking
#    Version 1.0.1 : April 10, 2024
#        - fixed bug with how SCRIPT DIR was calculated


VERSION='1.0.1'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [ -n "${SLURM_JOB_ID:-}" ] ; then
    command_run=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
    if [ "$command_run" != "/bin/sh" ]; then
        SCRIPT_DIR=$(dirname "${command_run}" )
    fi
fi

>&2 echo "fastqc.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d]  <input_folder> <output_folder>" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2
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
nextflow_temp_folder=${output_folder}-nextflow_scratch

module_load='module load StdEnv/2020 nextflow/23.04.3'
command="${module_load} && mkdir -p ${tmp_output_folder} && NXF_WORK=${nextflow_temp_folder} nextflow run -pool-size "'$SLURM_CPUS_ON_NODE'" -resume ${SCRIPT_DIR}/fastqc.nf --input_folder ${input_folder}  --output_dir ${tmp_output_folder} && mv ${tmp_output_folder} ${output_folder} && rm -r ${nextflow_temp_folder}"

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

