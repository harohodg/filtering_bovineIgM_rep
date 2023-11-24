#!/usr/bin/env nextflow

nextflow.enable.dsl=2


params.input_file  = ""
params.output_dir = ""

params.min_read_length = 700
params.max_read_length = 1200


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

include { FASTQC as fastqc_pre_fastp } from './processes'
include { FASTQC as fastqc_post_fastp } from './processes'

include { FASTP as fastp } from './processes'


include { RELABEL_SEQUENCES as simplify_read_labels } from './processes'
include { RELABEL_SEQUENCES as label_forward_primer_reads } from './processes'
include { RELABEL_SEQUENCES as label_reverse_primer_reads } from './processes'
include { RELABEL_SEQUENCES as label_reverse_complimented_reverse_primer_reads } from './processes'

include { RELABEL_SEQUENCES as label_IgM_motif1_reads } from './processes'
include { RELABEL_SEQUENCES as label_IgM_motif2_reads } from './processes'
include { RELABEL_SEQUENCES as label_both_IgM_motifs_reads } from './processes'

include { RELABEL_SEQUENCES as clean_up_extracted_pre_CDR3_motif_headers } from './processes'
include { RELABEL_SEQUENCES as clean_up_extracted_post_CDR3_motif_headers } from './processes'

include { RELABEL_SEQUENCES as label_pre_CDR3_sequences } from './processes'
include { RELABEL_SEQUENCES as label_post_CDR3_sequences } from './processes'

include { FILTER_SEQUENCES as get_forward_primer_reads } from './processes'
include { FILTER_SEQUENCES as get_reverse_primer_reads } from './processes'

include { FILTER_SEQUENCES as get_IgM_motif1_reads } from './processes'
include { FILTER_SEQUENCES as get_IgM_motif2_reads } from './processes'

include { FILTER_SEQUENCES as get_productive_sequences } from './processes'

include { REVERSE_COMPLEMENT_SEQUENCES as reverse_compliment_reverse_primer_reads } from './processes'

include { FIND_COMMON_SEQUENCES as get_reads_with_both_IgM_motifs } from './processes'
include { CONCAT_SEQUENCES as concat_IgM_motif_reads } from './processes'
include { CONCAT_SEQUENCES as merge_forward_reverse_primer_reads } from './processes'

include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_IgM_motif_reads } from './processes'
include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_pre_CDR3_sequences } from './processes'
include { REMOVE_DUPLICATE_SEQUENCES as remove_duplicate_post_CDR3_sequences } from './processes'

include { LOCATE_REGEX_MATCHES as get_pre_CDR3_locations } from './processes'
include { EXTRACT_MATCHES as extract_pre_CDR3_sequences } from './processes'

include { LOCATE_REGEX_MATCHES as get_post_CDR3_locations } from './processes'
include { EXTRACT_MATCHES as extract_post_CDR3_sequences } from './processes'

include { LOCATE_REGEX_MATCHES as convert_productive_sequences_to_bed_file } from './processes'

include { EXTRACT_LENGTHS_FROM_BED_FILE as pre_and_post_CDR3_match_lengths } from './processes'
include { EXTRACT_LENGTHS_FROM_BED_FILE as productive_sequence_lengths } from './processes'

include { TRANSLATE_TO_AA_SEQUENCE as translate_pre_and_post_CDR3_sequences } from './processes'

                         
workflow {
    def input_file_basename = params.input_file.split('/')[-1].split("\\.")[0]
    
    
    relabeled_sequences = simplify_read_labels(params.input_file, '(.*?)\s.*', '$1', 'dont_save.gz')

    reads_with_forward_primer = get_forward_primer_reads(relabeled_sequences, params.forward_primer, params.forward_primer_num_mismatches, false, 'dont_save.gz')
    reads_with_reverse_primer = get_reverse_primer_reads(relabeled_sequences, params.reverse_primer, params.reverse_primer_num_mismatches, false, 'dont_save.gz')
     
    labeled_reads_with_forward_primer = label_forward_primer_reads(reads_with_forward_primer, '(.*)', '$1\thas_forward_primer', "${input_file_basename}-reads_with_forward_primer.fastq.gz")
    labeled_reads_with_reverse_primer = label_reverse_primer_reads(reads_with_reverse_primer, '(.*)', '$1\thas_reverse_primer', "${input_file_basename}-reads_with_reverse_primer.fastq.gz")
    
    reverse_complimented_reverse_primer_reads              = reverse_compliment_reverse_primer_reads(reads_with_reverse_primer)
    labeled_reverse_complimented_reads_with_reverse_primer = label_reverse_complimented_reverse_primer_reads(reverse_complimented_reverse_primer_reads, '(.*)', '$1\thas_reverse_primer:reverse_complimented', 'dont_save.gz')
    
    reads_with_IgM_motif1 = get_IgM_motif1_reads(labeled_reads_with_forward_primer, params.IgM_motif1, params.IgM_motif1_num_mismatches, false, 'dont_save.gz')
    reads_with_IgM_motif2 = get_IgM_motif2_reads(labeled_reads_with_forward_primer, params.IgM_motif2, params.IgM_motif2_num_mismatches, false, 'dont_save.gz')
    
    labeled_reads_with_IgM_motif1 = label_IgM_motif1_reads(reads_with_IgM_motif1, '(.*)', '$1\thas_IgM_motif1', 'dont_save.gz')
    labeled_reads_with_IgM_motif2 = label_IgM_motif2_reads(reads_with_IgM_motif2, '(.*)', '$1\thas_IgM_motif2', 'dont_save.gz')
    
    
    reads_with_both_IgM_motifs         = get_reads_with_both_IgM_motifs(reads_with_IgM_motif1, reads_with_IgM_motif2, false)
    labeled_reads_with_both_IgM_motifs = label_both_IgM_motifs_reads(reads_with_both_IgM_motifs, '(.*?)\t.*', '$1\thas_forward_primer\thas_both_IgM_motifs', "${input_file_basename}-reads_with_an_IgM_motif.fastq.gz")
    
    
    all_IgM_motif_reads = concat_IgM_motif_reads( labeled_reads_with_both_IgM_motifs.collect() + labeled_reads_with_IgM_motif1.collect() + labeled_reads_with_IgM_motif2.collect() )
    cleaned_all_IgM_motif_reads = remove_duplicate_IgM_motif_reads( all_IgM_motif_reads, false, 'dont_save.gz' )
    
    
    merged_forward_reverse_primer_reads = merge_forward_reverse_primer_reads( cleaned_all_IgM_motif_reads.collect() + labeled_reverse_complimented_reads_with_reverse_primer.collect() )
    
    
    pre_CDR3_locations                           = get_pre_CDR3_locations(merged_forward_reverse_primer_reads, params.pre_CDR3_motifs)
    pre_CDR3_sequences                           = extract_pre_CDR3_sequences(merged_forward_reverse_primer_reads, pre_CDR3_locations, 'dont_save.gz')
    pre_CDR3_sequences_with_cleaned_header       = clean_up_extracted_pre_CDR3_motif_headers(pre_CDR3_sequences, '(.*?)_.*', '$1', 'dont_save.gz')
    
    pre_CDR3_sequnces_duplicates_removed         = remove_duplicate_pre_CDR3_sequences( pre_CDR3_sequences_with_cleaned_header, false, 'dont_save.gz' )
    labeled_pre_CDR3_sequnces_duplicates_removed = label_pre_CDR3_sequences(pre_CDR3_sequnces_duplicates_removed, '(.*?):.*', '$1\textracted_pre_CDR3_motif', "${input_file_basename}-pre_CDR3_motif_sequences.fastq.gz")


    post_CDR3_locations                           = get_post_CDR3_locations(pre_CDR3_sequnces_duplicates_removed, params.post_CDR3_motifs)
    post_CDR3_sequences                           = extract_post_CDR3_sequences(pre_CDR3_sequnces_duplicates_removed, post_CDR3_locations, 'dont_save.gz')
    post_CDR3_sequences_with_cleaned_header       = clean_up_extracted_post_CDR3_motif_headers(post_CDR3_sequences, '(.*?)_.*', '$1', 'dont_save.gz')
    post_CDR3_sequences_duplicates_removed        = remove_duplicate_post_CDR3_sequences( post_CDR3_sequences_with_cleaned_header, false, 'dont_save.gz' )
    labeled_post_CDR3_sequnces_duplicates_removed = label_post_CDR3_sequences(post_CDR3_sequences_duplicates_removed, '(.*?):.*', '$1\thas_pre_CDR3_motif\textracted_pre_and_post_CDR3_motif', "${input_file_basename}-pre_and_post_CDR3_motifs_sequences.fastq.gz")
    
    pre_and_post_CDR3_match_lengths( post_CDR3_locations, params.CDR3_lengths_offset, "${input_file_basename}-CDR3_lengths.tsv" )
    
    
    translated_sequences = translate_pre_and_post_CDR3_sequences(post_CDR3_sequences_duplicates_removed, params.translation_frame)
    productive_sequences = get_productive_sequences(translated_sequences, '*', 0, true, "${input_file_basename}-productive_sequences.faa.gz")

    productive_sequences_bed_file = convert_productive_sequences_to_bed_file(productive_sequences, ['.*'])
    productive_sequence_lengths(productive_sequences_bed_file, params.productive_sequences_offset, "${input_file_basename}-productive_sequences_lengths.tsv")
}




