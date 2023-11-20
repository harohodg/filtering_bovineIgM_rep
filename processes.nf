process RELABEL_SEQUENCES {
    input:
        path input_file, stageAs: 'input_file.fastq'
        val  header_match
        val  header_replacement
        
    output:
        path 'relabeled_sequences.fastq'
    
    script:
        """
        seqkit replace --pattern '${header_match}' --replacement '${header_replacement}' --line-width 0 ${input_file} > relabeled_sequences.fastq
        """
}


process FILTER_SEQUENCES {
    input:
        path input_file, stageAs: 'input_file.fastq'
        
        val search_pattern
        val num_mismatches
        val invert_match
        
    output:
        path 'filtered_sequences.fastq'
    
    script:
        def invert_flag = invert_match != false ? "--invert-match" : ''
        """
        seqkit grep --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern '${search_pattern}' --max-mismatch ${num_mismatches} ${invert_flag} ${input_file} > filtered_sequences.fastq
        """
}


process REVERSE_COMPLEMENT_SEQUENCES {
    input:
        path input_file

    output:
        path 'reverse_complimented_file.fastq'
        
    script:
        """
        seqkit seq --reverse --complement --seq-type DNA --line-width 0 ${input_file} > reverse_complimented_file.fastq
        """
    
}




process FIND_COMMON_SEQUENCES {
    input:
        path input_file1, stageAs: 'input_file1.fastq'
        path input_file2, stageAs: 'input_file2.fastq'
        val by_sequence
        
    output:
        path 'common_sequences.fastq'
    
    script:
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : '' 
        """
        seqkit common ${input_file1} ${input_file2} ${by_seq_flag} --line-width 0  -o common_sequences.fastq
        """
}

process CONCAT_SEQUENCES {
    input:
        val input_files
        
    output:
        path 'merged_sequences.fastq'
        
    script:
        """
            cat  ${input_files.join(' ')} > merged_sequences.fastq
        """
}

process REMOVE_DUPLICATE_SEQUENCES {
    input:
        path input_file, stageAs: 'input_file.fastq'
        val by_sequence
        
    output:
        path 'duplicates_removed.fastq'
    
    script:
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : ''
        """
        seqkit rmdup ${by_seq_flag} ${input_file} > duplicates_removed.fastq
        """
}


process LOCATE_REGEX_MATCHES {
    input:
        path input_file, stageAs: 'input_file.fastq'
        val patterns
        val positive_strand_only
    output:
        path 'matches.bed'
    
    script:
        def positive_strand_only_flag = positive_strand_only != false ? '--only-positive-strand' : ''
        """
        seqkit locate --hide-matched --bed ${positive_strand_only_flag} --use-regexp --pattern '${patterns.join('|')}' ${input_file} > matches.bed
        """
    
}

process EXTRACT_MATCHES {
    input:
        path input_file, stageAs: 'input_file.fastq'
        path bed_file
        
    output:
        path 'sequence_matches.fastq'
        
    script:
        """
        seqkit subseq --bed ${bed_file} ${input_file} > sequence_matches.fastq
        """


}

process EXTRACT_LENGTHS_FROM_BED_FILE {
    input:
        path bed_file
        val offset
    output:
        path 'results.tsv'
    
    shell:
        '''
            awk 'BEGIN {OFS="\t";print "read","match_length","match_length-!{offset}"} {print $1,$3-$2+1, $3-$2+1-!{offset} }' !{bed_file} > 'results.tsv'
        '''
}
