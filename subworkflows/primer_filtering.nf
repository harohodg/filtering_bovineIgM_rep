#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { FILTER_SEQUENCES as get_forward_primer_reads }                             from '../modules/processes'
include { FILTER_SEQUENCES as get_reverse_primer_reads }                             from '../modules/processes'

include { FILTER_SEQUENCES as get_reads_without_forward_primer }                     from '../modules/processes'
include { FILTER_SEQUENCES as get_reads_without_reverse_primer }                     from '../modules/processes'


include { FIND_COMMON_SEQUENCES as get_reads_with_both_primers }                     from '../modules/processes'
include { FIND_COMMON_SEQUENCES as get_reads_without_either_primers }                from '../modules/processes'
    
include { RELABEL_SEQUENCES as label_forward_primer_reads }                          from '../modules/processes'
include { RELABEL_SEQUENCES as label_reverse_primer_reads }                          from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_without_forward_primer }                  from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_without_reverse_primer }                  from '../modules/processes'
include { RELABEL_SEQUENCES as label_both_primer_reads }                             from '../modules/processes'
include { RELABEL_SEQUENCES as label_with_no_primer_reads }                          from '../modules/processes'
include { RELABEL_SEQUENCES as label_forward_no_reverse_primer_reads }               from '../modules/processes'
include { RELABEL_SEQUENCES as label_reverse_no_forward_primer_reads }               from '../modules/processes'

include { REMOVE_OVERLAPPING_SEQUENCES as get_reads_with_forward_no_reverse_primer } from '../modules/processes'
include { REMOVE_OVERLAPPING_SEQUENCES as get_reads_with_reverse_no_forward_primer } from '../modules/processes'  

include { REVERSE_COMPLEMENT_SEQUENCES as reverse_compliment_reverse_primer_reads } from '../modules/processes'


workflow primer_filtering {
    take:
        reads_files
        forward_primer
        reverse_primer
        forward_primer_num_mismatches
        reverse_primer_num_mismatches
    emit:
        labeled_forward_primer_reads
        labeled_reverse_primer_reads
        labeled_forward_no_reverse_primer_reads
        labeled_reverse_no_forward_primer_reads
        
    main:
        def INVERT_MATCH          = true
        def DONT_INVERT_MATCH     = false
        def PATTERN_ISNT_A_REGEXP = false
        
        reads_with_forward_primer = get_forward_primer_reads(reads_files, forward_primer, forward_primer_num_mismatches, DONT_INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        reads_with_reverse_primer = get_reverse_primer_reads(reads_files, reverse_primer, reverse_primer_num_mismatches, DONT_INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] ) 
        labeled_forward_primer_reads = label_forward_primer_reads( reads_with_forward_primer, '(.*)', '$1\thas_forward_primer', ['keep', 'have_forward_primer.fastq.gz'] )
       
        reverse_complimented_reverse_primer_reads = reverse_compliment_reverse_primer_reads(reads_with_reverse_primer)
        labeled_reverse_primer_reads = label_reverse_primer_reads( reverse_complimented_reverse_primer_reads, '(.*)', '$1\thas_reverse_primer-reverse_complimented', ['keep', 'have_reverse_primer-reverse_complimented.fastq.gz'] )
        
        
        reads_without_forward_primer = get_reads_without_forward_primer(reads_files, forward_primer, forward_primer_num_mismatches, INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        reads_without_reverse_primer = get_reads_without_reverse_primer(reads_files, reverse_primer, reverse_primer_num_mismatches, INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['', 'dont_save.gz'] )
        labeled_reads_without_forward_primer = label_reads_without_forward_primer( reads_without_forward_primer, '(.*)', '$1\tno_forward_primer', ['discard', 'no_forward_primer.fastq.gz'] )
        labeled_reads_without_reverse_primer = label_reads_without_reverse_primer( reads_without_reverse_primer, '(.*)', '$1\tno_reverse_primer', ['discard', 'no_reverse_primer.fastq.gz'] )
        
          
        reads_with_both_primers      = get_reads_with_both_primers( reads_with_forward_primer.combine(reads_with_reverse_primer, by: 0) )
        reads_without_either_primer  = get_reads_without_either_primers( reads_without_forward_primer.combine(reads_without_reverse_primer, by: 0) )              
        labeled_reads_with_both_primers     = label_both_primer_reads(reads_with_both_primers, '(.*)', '$1\thas_both_primers', ['discard', 'have_both_primers.fastq.gz'] )
        labeled_reads_without_either_primer = label_with_no_primer_reads(reads_without_either_primer, '(.*)', '$1\thas_no_primers', ['discard', 'no_primers.fastq.gz'] )


        reads_with_forward_no_reverse_primer = get_reads_with_forward_no_reverse_primer( labeled_reads_with_both_primers.combine(reads_with_forward_primer, by: 0), '.*has_both_primers', true, ['', 'dont_save.gz']  )
        reads_with_reverse_no_forward_primer = get_reads_with_reverse_no_forward_primer( labeled_reads_with_both_primers.combine(reads_with_reverse_primer, by: 0), '.*has_both_primers', true, ['', 'dont_save.gz'] )
        
        
        labeled_forward_no_reverse_primer_reads = label_forward_no_reverse_primer_reads(reads_with_forward_no_reverse_primer, '(.*)', '$1\thas_forward_no_reverse_primer', ['discard', 'has_forward_no_reverse_primer.fastq.gz'] )
        labeled_reverse_no_forward_primer_reads = label_reverse_no_forward_primer_reads(reads_with_reverse_no_forward_primer, '(.*)', '$1\thas_reverse_no_forward_primer', ['discard', 'has_reverse_no_forward_primer.fastq.gz'] )
 
        
}
