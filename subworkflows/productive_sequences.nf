#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { TRANSLATE_TO_AA_SEQUENCE as translate_pre_and_post_CDR3_sequences } from '../modules/processes'
include { FILTER_SEQUENCES as get_productive_sequences }                      from '../modules/processes'
include { GET_MATCH_LENGTHS as productive_sequence_lengths }                  from '../modules/processes'


workflow productive_sequences {
    take:
        post_CDR3_sequences_duplicates_removed
        translation_frame
        productive_sequences_offset

        
    main:
        def INVERT_MATCH          = true
        def PATTERN_ISNT_A_REGEXP = false
        
        translated_sequences = translate_pre_and_post_CDR3_sequences(post_CDR3_sequences_duplicates_removed, translation_frame)
        productive_sequences = get_productive_sequences(translated_sequences, '*', 0, INVERT_MATCH, PATTERN_ISNT_A_REGEXP, ['keep', 'productive_sequences.faa.gz'] )
        productive_sequence_lengths(productive_sequences, productive_sequences_offset, ['keep', 'productive_sequences_lengths.tsv'] )   
}
