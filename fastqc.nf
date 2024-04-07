#!/usr/bin/env nextflow

nextflow.enable.dsl=2


params.input_folder = ""
params.output_dir   = ""


include { FASTQC as fastqc } from './modules/processes'
                         
workflow {
    input_files = Channel.fromPath("${params.input_folder}/**.fastq.gz",type: 'file').map{ tuple(it, it.getBaseName(2).split("-")[0], it.getBaseName(2)) }.take(-1)
    fastqc(input_files)
}




