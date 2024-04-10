#!/bin/bash
#SBATCH -t 1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G

#Script for launching an interactive job on Digital Research Alliance Infrastructure.

#Author : Harold Hodgins <hhodgins@uwaterloo.ca>

#History:
#    Version 1.0 : April 10, 2024
#        - functional code with minimal error checking


VERSION='1.0.0'
DEFAULT_NUM_CPU=4
DEFAULT_TOTAL_MEM="8G"
DEFAULT_RUN_TIME='1:00:00'

>&2 echo "launch_interactive_job.sh version $VERSION"

# Echo usage if something isn't right.
usage() { 
    echo "Usage: $0 [-d] [-S job_name] [-l log_file] [-a slurm_account] [-c num_cpu (default : $DEFAULT_NUM_CPU)]  [-m total_mem (default : $DEFAULT_TOTAL_MEM)] [-t run_time (default : $DEFAULT_RUN_TIME)]" 1>&2; 
    echo "Use -d to print what would have been run but not actually run it" 1>&2;
    exit 1; 
}


while getopts ":dS:l:a:c:m:t:" o; do
    case "${o}" in
        d)  
            debug=1
            ;;
        S)  
            job_name="$OPTARG"
            ;;
        l)  
            log_file="$OPTARG"
            ;;
        a)  
            slurm_account="$OPTARG"
            ;;
        c)  
            num_cpu="$OPTARG"
            ;;
        m)  
            total_mem="$OPTARG"
            ;;
        t)  
            run_time="$OPTARG"
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

if [[ "$#" -ne 0 ]]; then
    echo 'Incorrect number of arguments.'
    usage
fi

screen_job_name_flag=${job_name:+"-S ${job_name}"}
slurm_job_name_flag=${job_name:+"--job-name=${job_name}"}
log_file_flag=${log_file:+"-L ${log_file}"}
slurm_account_flag=${slurm_account:+"--account=${slurm_account}"}
num_cpu=${num_cpu:-$DEFAULT_NUM_CPU}
total_mem=${total_mem:-$DEFAULT_TOTAL_MEM}
run_time=${run_time:-$DEFAULT_RUN_TIME}

command="screen ${screen_job_name_flag} ${slurm_job_name_flag}  salloc ${slurm_account_flag} --nodes=1 --tasks=1 --cpus-per-task=${num_cpu} --mem=${total_mem} --time=${run_time} ${slurm_job_name_flag}"


if [ -n "$debug" ];then
    echo "$command"
else  
    echo                       >&2
    echo "${command}"          >&2
    echo                       >&2
    echo '-------------------' >&2
    echo
    eval "$command"
fi

