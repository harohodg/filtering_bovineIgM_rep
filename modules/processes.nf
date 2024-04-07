process FASTQC {
    cpus 2
    memory {1.GB * task.cpus}
    module 'StdEnv/2020:fastqc/0.11.9'
    publishDir "${params.output_dir}/${sub_folder}-fastqc/${output_file_prefix}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.html"
    publishDir "${params.output_dir}/${sub_folder}-fastqc/${output_file_prefix}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.zip"
    
    input:
        tuple path(input_file), val(sub_folder), val(output_file_prefix)
    output:
        path "*.html"
        path "*.zip"
    
    script:
        """
        fastqc --threads ${task.cpus} --outdir . ${input_file}
        """   
}



process FASTP {
    cpus 4
    memory {2.GB * task.cpus}
    module 'StdEnv/2020:fastp/0.23.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_file_prefix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_file_prefix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.json"
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_file_prefix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.html"
    
    input:
        tuple path(input_file), val(output_file_prefix)
        val min_length
        val max_length
        val dedup
        
        
    output:
        tuple val(output_file_prefix), path("${ output_file_prefix }-fastp_filtered.fastq.gz"), path("${ output_file_prefix }-fastp_failed.fastq.gz"), emit: results
        path "*.html", emit: html_file
        path "*.json", emit: json_file
       
    script:
        def dedup_flag      = dedup != false ? "--dedup" : ''
        def min_length_flag = min_length > 0 ? "--length_required ${min_length}" : ''
        def max_length_flag = max_length > 0 ? "--length_limit ${max_length}"    : ''
        """
            fastp --thread ${task.cpus} ${dedup_flag} --disable_adapter_trimming ${min_length_flag} ${max_length_flag} --json ${output_file_prefix}-fastp_report.json --html ${output_file_prefix}-fastp-report.html  --in1 ${input_file} --failed_out ${output_file_prefix}-fastp_failed.fastq.gz -o ${output_file_prefix}-fastp_filtered.fastq.gz
        """   
    
    stub:
        """
        cp ${input_file} ${output_file_prefix}-fastp_filtered.fastq.gz
        cp ${input_file} ${output_file_prefix}-fastp_failed.fastq.gz
        """       
}


process RELABEL_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${output_sub_folder}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val header_match
        val header_replacement
        tuple val(output_sub_folder), val(output_file_suffix)
    
    output:
        tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        """
        seqkit replace --threads ${task.cpus} --pattern '${header_match}' --replacement '${header_replacement}' --line-width 0 ${input_file} --out-file ${output_file}
        """
}


process FILTER_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${output_sub_folder}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    publishDir "${params.output_dir}/${ output_file_prefix }/${output_sub_folder}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.faa.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val search_pattern
        val num_mismatches
        val invert_match
        val pattern_is_regex
        tuple val(output_sub_folder), val(output_file_suffix)
        
    output:
        tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        def invert_flag = invert_match != false ? "--invert-match" : ''
        def regex_flag  = pattern_is_regex != false ? '--use-regexp' : ''
        """
        seqkit grep --threads ${task.cpus} --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern '${search_pattern}' ${regex_flag} --max-mismatch ${num_mismatches} ${invert_flag} ${input_file} --out-file ${output_file}
        """
}


process REVERSE_COMPLEMENT_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')

    output:
        tuple val(output_file_prefix), path("reverse_complimented_file.fastq.gz")
        
        
    script:
        """
        seqkit seq --threads ${task.cpus} --reverse --complement --seq-type DNA --line-width 0 ${input_file} --out-file reverse_complimented_file.fastq.gz
        """
    
}


process FIND_COMMON_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_prefix), path(input_file1, stageAs: 'input_file1.fastq.gz'), path(input_file2, stageAs: 'input_file2.fastq.gz')
        
    output:
        tuple val(output_file_prefix), path("common_sequences.fastq.gz")
    
    script:
        """
        seqkit common --threads ${task.cpus} ${input_file1} ${input_file2} --line-width 0  -o common_sequences.fastq.gz
        """
}


process REMOVE_OVERLAPPING_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_sub_folder }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file1, stageAs: 'input_file1.fastq.gz'), path(input_file2, stageAs: 'input_file2.fastq.gz')
        val header_pattern
        val invert_match
        tuple val(output_sub_folder), val(output_file_suffix)
        
    output:
         tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        def invert_flag = invert_match != false ? "--invert-match" : ''
        """
        seqkit rmdup --threads ${task.cpus/2} --out-file ${output_file} ${input_file1} ${input_file2} | seqkit grep --threads ${task.cpus/2} --by-name --use-regexp --pattern '${header_pattern}' --line-width 0 ${invert_flag} --out-file ${output_file}
        """    
}


process CONCAT_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    input:
        tuple val(output_file_prefix), path(input_files)
        
    output:
        tuple val(output_file_prefix), path("merged_sequences.fastq.gz")
        
    script:
        """
            seqkit seq --threads ${task.cpus} ${input_files.join(' ')} --out-file merged_sequences.fastq.gz
        """
}

process REMOVE_DUPLICATE_SEQUENCES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_sub_folder }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val by_sequence
        tuple val(output_sub_folder), val(output_file_suffix)
        
    output:
         tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : ''
        """
        seqkit rmdup --threads ${task.cpus} ${by_seq_flag} ${input_file} --out-file ${output_file}
        """
}


process LOCATE_REGEX_MATCHES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val patterns
    output:
        tuple val(output_file_prefix), path('input_file.fastq.gz'), path('matches.bed')
    
    script:
        """
        seqkit locate --threads ${task.cpus} --bed --only-positive-strand --use-regexp --pattern '${patterns.join("|")}' ${input_file} > matches.bed
        """
    
}


process EXTRACT_MATCHES {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_sub_folder }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz'), path(bed_file, stageAs: 'bed_file.bed')
        tuple val(output_sub_folder), val(output_file_suffix)
        
    output:
        tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        """
        seqkit subseq --threads ${task.cpus} --bed ${bed_file} ${input_file} --out-file ${output_file}
        """
}


process GET_MATCH_LENGTHS {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:bioawk/1.0'
    publishDir "${params.output_dir}/${ output_file_prefix }/${ output_sub_folder }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: true, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val offset
        tuple val(output_sub_folder), val(output_file_suffix)
         
    output:
        tuple val(output_file_prefix), path("${output_file_prefix}-${output_file_suffix}")
    
    script:
        def output_file = "${output_file_prefix}-${output_file_suffix}"
        """
        bioawk -c fastx 'BEGIN {OFS="\t";print "read","match_length","match_length-${offset}","sequence"} {print \$name,length(\$seq), length(\$seq)-${offset},\$seq }' ${input_file} > ${output_file}
        """
}

process TRANSLATE_TO_AA_SEQUENCE {
    cpus 4
    memory {2.GB * task.cpus}
    
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_prefix), path(input_file, stageAs: 'input_file.fastq.gz')
        val frames
    output:
        tuple val(output_file_prefix), path('translated_sequences.faa.gz')
    
    script:
        """
        seqkit translate --threads ${task.cpus} --append-frame --frame ${frames.join(',')} ${input_file} --out-file 'translated_sequences.faa.gz'
        """    
}




