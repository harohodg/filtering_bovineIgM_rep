#!/usr/bin/env nextflow

nextflow.enable.dsl=2


params.input_file = ""
params.output_dir = ""
params.filter     = "fastp_filtered"


params.forward_primer                = "AGATGAACCCACTGTGGACC"
params.reverse_primer                = "TGTTTGGGGCTGAAGTCC"
params.forward_primer_num_mismatches = 4
params.reverse_primer_num_mismatches = 4

params.IgM_motif1 = 'ACAGCCTCTCT'
params.IgM_motif2 = 'AATCACACCCGAGAGTCTTC'
params.IgM_motif1_num_mismatches = 2
params.IgM_motif2_num_mismatches = 4

params.pre_CDR3_motifs = ['GA[AG]GA[TC][ATG][GC][ATGC]GC[GCTA][ATC][CGT][ATCG].*',
                          '[ATG]C[GA]GCC[AG][CT][AG][TC]A[CT].*'
                         ]

params.post_CDR3_motifs = ['[ATG][GC][ATGC]GC.*?TGGGG[GC]C[GCA][AG]',
                           '[ATG][GC][ATGC]GC.*?TGGGCCAA',
                           '[ATG][GC][ATGC]GC.*?CCGGGCCAA',
                           '[ATG][GC][ATGC]GC.*?TGCGGCCGA',
                           '[ATG][GC][ATGC]GC.*?TGGGGTC[AG]G',
                           '[ATG][GC][ATGC]GC.*?TGTGGCCAG',
                           '[ATG][GC][ATGC]GC.*?TGGGGCTCA',
                           '[ATG][GC][ATGC]GC.*?AGGGGCCAA',
                           '[ATG][GC][ATGC]GC.*?TGGAGCCAG'
                          ] 
                         

params.CDR3_lengths_offset = 27
params.productive_sequences_offset = 9
params.translation_frame = [1]


include { RELABEL_SEQUENCES as simplify_read_labels }              from './modules/processes'


include { primer_filtering }            from './subworkflows/primer_filtering'
include { IgM_motifs_filtering }        from './subworkflows/IgM_motifs_filtering'
include { merge_primer_reads }          from './subworkflows/merge_primer_reads'
include { extract_pre_CDR3_sequences }  from './subworkflows/extract_pre_CDR3_sequences'
include { extract_post_CDR3_sequences } from './subworkflows/extract_post_CDR3_sequences'
include { calculate_CDR3_lengths }      from './subworkflows/calculate_CDR3_lengths'
include { productive_sequences }        from './subworkflows/productive_sequences'
                         
workflow {
    input_files = Channel.fromPath("${params.input_folder}/**/bc*-${params.filter}.fastq.gz",type: 'file').map{ tuple("${it.getBaseName(2).split('-')[0]}-${params.filter}", it)  }

    relabeled_sequences = simplify_read_labels(input_files, '(.*?)\s.*', '$1', ['', 'dont_save.gz'] )
    primer_filtering( relabeled_sequences, params.forward_primer, params.reverse_primer, params.forward_primer_num_mismatches, params.reverse_primer_num_mismatches )
    IgM_motifs_filtering( primer_filtering.out.labeled_forward_primer_reads, params.IgM_motif1, params.IgM_motif2, params.IgM_motif1_num_mismatches, params.IgM_motif2_num_mismatches )
    
    merge_primer_reads(IgM_motifs_filtering.out, primer_filtering.out.labeled_reverse_primer_reads )
    
    extract_pre_CDR3_sequences( merge_primer_reads.out, params.pre_CDR3_motifs )
    extract_post_CDR3_sequences( extract_pre_CDR3_sequences.out, params.post_CDR3_motifs )
    
    calculate_CDR3_lengths( extract_post_CDR3_sequences.out, params.CDR3_lengths_offset )
    productive_sequences( extract_post_CDR3_sequences.out, params.translation_frame, params.productive_sequences_offset ) 
}




