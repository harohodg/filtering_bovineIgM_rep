#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { GET_MATCH_LENGTHS as pre_and_post_CDR3_match_lengths } from '../modules/processes'


workflow calculate_CDR3_lengths {
    take:
        post_CDR3_sequences_duplicates_removed
        CDR3_lengths_offset
        
    main:
        pre_and_post_CDR3_match_lengths( post_CDR3_sequences_duplicates_removed, CDR3_lengths_offset, ['keep', 'CDR3_lengths.tsv'] )
}
