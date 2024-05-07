#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { LOCATE_REGEX_MATCHES as get_post_CDR3_locations } from '../modules/processes'
include { EXTRACT_MATCHES as extract_sequences }  from '../modules/processes'

include { FILTER_SEQUENCES as get_reads_without_match } from '../modules/processes'

include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_post_CDR3_sequences } from '../modules/processes'

include { RELABEL_SEQUENCES as clean_up_extracted_post_CDR3_motif_headers } from '../modules/processes'
include { RELABEL_SEQUENCES as label_post_CDR3_sequences }                  from '../modules/processes'
include { RELABEL_SEQUENCES as label_reads_without_match }                 from '../modules/processes'


workflow extract_post_CDR3_sequences {
    take:
        pre_CDR3_sequnces_duplicates_removed
        post_CDR3_motifs
    emit:
        labeled_post_CDR3_sequnces_duplicates_removed
        
    main:
        def INVERT_MATCH        = true
        def PATTERN_IS_A_REGEXP = true 
        
        post_CDR3_locations = get_post_CDR3_locations(pre_CDR3_sequnces_duplicates_removed, post_CDR3_motifs)

        post_CDR3_sequences = extract_sequences(post_CDR3_locations, ['discard', 'have_post_CDR3_motif.fastq.gz'] )
        post_CDR3_sequences_with_cleaned_header = clean_up_extracted_post_CDR3_motif_headers(post_CDR3_sequences, '(.*?)_.*', '$1', ['', 'dont_save.gz'])
   
        post_CDR3_sequnces_duplicates_removed         = remove_duplicate_post_CDR3_sequences( post_CDR3_sequences_with_cleaned_header, false, ['', 'dont_save.gz'] )
        labeled_post_CDR3_sequnces_duplicates_removed = label_post_CDR3_sequences(post_CDR3_sequnces_duplicates_removed, '(.*?):.*', '$1\textracted_post_CDR3_motif', ['keep', 'post_CDR3_motif_sequences.fastq.gz'] ) 
        
        search_pattern = "${post_CDR3_motifs.join('|')}"
        reads_without_match = get_reads_without_match( pre_CDR3_sequnces_duplicates_removed, search_pattern, 0, INVERT_MATCH, PATTERN_IS_A_REGEXP, ['', 'dont_save.gz'] )
        label_reads_without_match( reads_without_match, '(.*)', '$1\thas_no_post_CDR3', ['discard', 'no_post_CDR3.fastq.gz'] )   
}
