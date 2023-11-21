process RELABEL_SEQUENCES {
    publishDir "${params.output_dir}/", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq"
    
    input:
        path input_file, stageAs: 'input_file.fastq'
        val  header_match
        val  header_replacement
        val  output_file
    output:
        path "${output_file}"
    
    script:
        """
        seqkit replace --pattern '${header_match}' --replacement '${header_replacement}' --line-width 0 ${input_file} > ${output_file}
        """
}


process FILTER_SEQUENCES {
    publishDir "${params.output_dir}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq"
    input:
        path input_file, stageAs: 'input_file.fastq'
        
        val search_pattern
        val num_mismatches
        val invert_match
        val output_file
        
    output:
        path "${output_file}"
    
    script:
        def invert_flag = invert_match != false ? "--invert-match" : ''
        """
        seqkit grep --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern '${search_pattern}' --max-mismatch ${num_mismatches} ${invert_flag} ${input_file} > ${output_file}
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
    publishDir "${params.output_dir}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq"
    input:
        path input_file, stageAs: 'input_file.fastq'
        val by_sequence
        val output_file
        
    output:
        path "${output_file}"
    
    script:
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : ''
        """
        seqkit rmdup ${by_seq_flag} ${input_file} > ${output_file}
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
    publishDir "${params.output_dir}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq"
    input:
        path input_file, stageAs: 'input_file.fastq'
        path bed_file
        val output_file
        
    output:
        path "${output_file}"
        
    script:
        """
        seqkit subseq --bed ${bed_file} ${input_file} > ${output_file}
        """


}

process EXTRACT_LENGTHS_FROM_BED_FILE {
    publishDir "${params.output_dir}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.tsv"
    
    input:
        path bed_file
        val offset
        val output_file
    output:
        path "${output_file}"
    
    shell:
        '''
            awk 'BEGIN {OFS="\t";print "read","match_length","match_length-!{offset}"} {print $1,$3-$2+1, $3-$2+1-!{offset} }' !{bed_file} > !{output_file}
        '''
}
