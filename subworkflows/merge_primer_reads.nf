#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { CONCAT_SEQUENCES as merge_forward_reverse_primer_reads }                      from '../modules/processes'
include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_merged_forward_reverse_reads } from '../modules/processes'


workflow merge_primer_reads {
    take:
        labeled_IgM_motifs_reads
        labeled_reverse_primer_reads
    emit:
        merged_forward_reverse_primer_reads_duplicates_removed
        
    main:
        with_IgM_motif_or_reverse_primer_reads = labeled_IgM_motifs_reads.combine( labeled_reverse_primer_reads, by: 0).map{ tuple(it[0], tuple(it[1], it[2]) ) }
        
         merged_forward_reverse_primer_reads                    = merge_forward_reverse_primer_reads(with_IgM_motif_or_reverse_primer_reads) 
         merged_forward_reverse_primer_reads_duplicates_removed = remove_duplicate_merged_forward_reverse_reads(merged_forward_reverse_primer_reads, false, ['keep', 'reads_with_an_IgM_motif_or_reverse_complimented_reverse_primer.fastq.gz'])  
}
