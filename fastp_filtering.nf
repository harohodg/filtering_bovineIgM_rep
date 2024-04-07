#!/usr/bin/env nextflow

nextflow.enable.dsl=2


params.input_folder = ""
params.output_dir   = ""

params.min_read_length = 700
params.max_read_length = 1200

params.deduplicate_reads = ''

include { FASTP as fastp } from './modules/processes'
                         
workflow {
    input_files = Channel.fromPath("${params.input_folder}/bc*.fastq.gz",type: 'file').map{ tuple(it, it.getBaseName(2).split('-')[0]) }
    fastp(input_files, params.min_read_length, params.max_read_length, params.deduplicate_reads != '' ? true : false)
}




