#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { FILTER_SEQUENCES as get_reads_with_IgM_motif1 }         from '../modules/processes'
include { FILTER_SEQUENCES as get_reads_with_IgM_motif2 }         from '../modules/processes'

include { FILTER_SEQUENCES as get_reads_without_IgM_motif1 } from '../modules/processes'
include { FILTER_SEQUENCES as get_reads_without_IgM_motif2 } from '../modules/processes'


include { FIND_COMMON_SEQUENCES as get_reads_with_both_motifs }     from '../modules/processes'
include { FIND_COMMON_SEQUENCES as get_reads_without_either_motif } from '../modules/processes'
    
include { RELABEL_SEQUENCES as label_reads_with_IgM_motif1 }       from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_with_IgM_motif2 }       from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_without_IgM_motif1 }    from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_without_IgM_motif2 }    from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_with_both_IgM_motifs }  from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_with_no_IgM_motif }     from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_with_motif1_no_motif2 } from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_with_motif2_no_motif1 } from '../modules/processes'


include { REMOVE_OVERLAPPING_SEQUENCES as get_reads_with_motif1_no_motif2 } from '../modules/processes'
include { REMOVE_OVERLAPPING_SEQUENCES as get_reads_with_motif2_no_motif1 } from '../modules/processes'  

include { CONCAT_SEQUENCES as concat_IgM_motif_reads }                      from '../modules/processes'
include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_IgM_motif_reads }  from '../modules/processes'


workflow IgM_motifs_filtering {
    take:
        forward_primer_reads
        IgM_motif1
        IgM_motif2
        IgM_motif1_num_mismatches
        IgM_motif2_num_mismatches
    emit:
        labeled_IgM_motifs_reads
        
    main:
        def INVERT_MATCH          = true
        def DONT_INVERT_MATCH     = false
        def PATTERN_ISNT_A_REGEXP = false
        
        reads_with_IgM_motif1         = get_reads_with_IgM_motif1(forward_primer_reads, IgM_motif1, IgM_motif1_num_mismatches, DONT_INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        reads_with_IgM_motif2         = get_reads_with_IgM_motif2(forward_primer_reads, IgM_motif2, IgM_motif2_num_mismatches, DONT_INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        labeled_reads_with_IgM_motif1 = label_reads_with_IgM_motif1(reads_with_IgM_motif1, '(.*)', '$1\thas_IgM_motif1', ['discard','have_IgM_motif1.fastq.gz'] )
        labeled_reads_with_IgM_motif2 = label_reads_with_IgM_motif2(reads_with_IgM_motif2, '(.*)', '$1\thas_IgM_motif2', ['discard','have_IgM_motif2.fastq.gz'] )
        

        reads_without_IgM_motif1         = get_reads_without_IgM_motif1(forward_primer_reads, IgM_motif1, IgM_motif1_num_mismatches, INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        reads_without_IgM_motif2         = get_reads_without_IgM_motif2(forward_primer_reads, IgM_motif2, IgM_motif2_num_mismatches, INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        labeled_reads_without_IgM_motif1 = label_reads_without_IgM_motif1(reads_without_IgM_motif1, '(.*)', '$1\tno_IgM_motif1', ['discard','no_IgM_motif1.fastq.gz'] )
        labeled_reads_without_IgM_motif2 = label_reads_without_IgM_motif2(reads_without_IgM_motif2, '(.*)', '$1\tno_IgM_motif2', ['discard','no_IgM_motif2.fastq.gz'] )
        
          
        reads_with_both_motifs         = get_reads_with_both_motifs( reads_with_IgM_motif1.combine(reads_with_IgM_motif2, by: 0) )
        reads_with_no_motif            = get_reads_without_either_motif( reads_without_IgM_motif1.combine(reads_without_IgM_motif2, by: 0) )              
        labeled_reads_with_both_motifs = label_reads_with_both_IgM_motifs(reads_with_both_motifs, '(.*)', '$1\thas_both_IgM_motifs', ['discard', 'have_both_IgM_motifs.fastq.gz'] )
        labeled_reads_with_no_motif    = label_reads_with_no_IgM_motif(reads_with_no_motif, '(.*)', '$1\thas_no_IgM_motif', ['discard', 'no_IgM_motifs.fastq.gz'] )

        all_IgM_motif_reads = labeled_reads_with_both_motifs.combine( labeled_reads_with_IgM_motif1, by: 0).combine( labeled_reads_with_IgM_motif2, by: 0).map{ tuple( it[0], tuple(it[1], it[2], it[3]) ) }
        
        filtered_IgM_motif_reads = concat_IgM_motif_reads( all_IgM_motif_reads )
        labeled_IgM_motifs_reads = remove_duplicate_IgM_motif_reads( filtered_IgM_motif_reads, false, ['keep','have_one_or_more_IgM_motifs.fastq.gz'] )        
}
