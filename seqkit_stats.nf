#!/usr/bin/env nextflow

nextflow.enable.dsl=2


params.input_folder = ""
params.output_dir   = ""


include { SEQUENCE_STATS as sequence_stats } from './modules/processes'
                         
workflow {
    input_files = Channel.fromPath("${params.input_folder}/**.fastq.gz",type: 'file').take(-1)
    sequence_stats(input_files).collectFile(name: "${params.output_dir }/sequence_stats.tsv", newLine: false, keepHeader: true, sort: true)
}




