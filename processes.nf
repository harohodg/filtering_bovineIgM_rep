process FASTQC {
    memory '2 GB'
    cpus 2
    module 'StdEnv/2020:fastqc/0.11.9'
    publishDir "${params.output_dir}/fastqc/${task.process}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.html"
    publishDir "${params.output_dir}/fastqc/${task.process}", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.zip"
    
    input:
        path input_file
    output:
        path "*.html"
        path "*.zip"
    
    script:
        """
        fastqc --threads ${task.cpus} --outdir . ${input_file}
        """   
}



process FASTP {
    cpus 2
    memory {4.GB * task.cpus}
    module 'StdEnv/2020:fastp/0.23.1'
    publishDir "${params.output_dir}/${ output_file_suffix }/${ output_file_suffix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq.gz"
    publishDir "${params.output_dir}/${ output_file_suffix }/${ output_file_suffix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.json"
    publishDir "${params.output_dir}/${ output_file_suffix }/${ output_file_suffix }-fastp", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.html"
    
    input:
        tuple path(input_file), val(output_file_suffix)
        val min_length
        val max_length
        val dedup
        
        
    output:
        tuple val(output_file_suffix), path("${ output_file_suffix }-fastp_filtered.fastq.gz"), path("${ output_file_suffix }-fastp_failed.fastq.gz")
       
    script:
        def dedup_flag      = dedup != false ? "--dedup" : ''
        def min_length_flag = min_length > 0 ? "--length_required ${min_length}" : ''
        def max_length_flag = max_length > 0 ? "--length_limit ${max_length}"    : ''
        """
            fastp --thread ${task.cpus} ${dedup_flag} --disable_adapter_trimming ${min_length_flag} ${max_length_flag} --json ${output_file_suffix}-fastp_report.json --html ${output_file_suffix}-fastp-report.html  --in1 ${input_file} --failed_out ${output_file_suffix}-fastp_failed.fastq.gz -o ${output_file_suffix}-fastp_filtered.fastq.gz
        """   
    
    stub:
        """
        cp ${input_file} ${output_file_suffix}-fastp_filtered.fastq.gz
        cp ${input_file} ${output_file_suffix}-fastp_failed.fastq.gz
        """       
}


process RELABEL_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val header_match
        val header_replacement
        val output_file_prefix
    
    output:
        tuple val(output_file_suffix), path("${output_file_suffix}-${output_file_prefix}")
    
    script:
        def output_file = "${output_file_suffix}-${output_file_prefix}"
        """
        seqkit replace --threads ${task.cpus} --pattern '${header_match}' --replacement '${header_replacement}' --line-width 0 ${input_file} --out-file ${output_file}
        """
}


process FILTER_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq.gz"
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.faa.gz"
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val search_pattern
        val num_mismatches
        val invert_match
        val output_file_prefix
        
    output:
        tuple val(output_file_suffix), path("${output_file_suffix}-${output_file_prefix}")
    
    script:
        def output_file = "${output_file_suffix}-${output_file_prefix}"
        def invert_flag = invert_match != false ? "--invert-match" : ''
        """
        seqkit grep --threads ${task.cpus} --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern '${search_pattern}' --max-mismatch ${num_mismatches} ${invert_flag} ${input_file} --out-file ${output_file}
        """
}


process REVERSE_COMPLEMENT_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')

    output:
        tuple val(output_file_suffix), path("reverse_complimented_file.fastq.gz")
        
        
    script:
        """
        seqkit seq --threads ${task.cpus} --reverse --complement --seq-type DNA --line-width 0 ${input_file} --out-file reverse_complimented_file.fastq.gz
        """
    
}




process FIND_COMMON_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_suffix), path(input_file1, stageAs: 'input_file1.fastq.gz'), path(input_file2, stageAs: 'input_file2.fastq.gz')
        val by_sequence
        
    output:
        tuple val(output_file_suffix), path("common_sequences.fastq.gz")
    
    script:
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : '' 
        """
        seqkit common --threads ${task.cpus} ${input_file1} ${input_file2} ${by_seq_flag} --line-width 0  -o common_sequences.fastq.gz
        """
}

process CONCAT_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    input:
        tuple val(output_file_suffix), path(input_files)
        
    output:
        tuple val(output_file_suffix), path("merged_sequences.fastq.gz")
        
    script:
        """
            seqkit seq --threads ${task.cpus} ${input_files.join(' ')} --out-file merged_sequences.fastq.gz
        """
}

process REMOVE_DUPLICATE_SEQUENCES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val by_sequence
        val output_file_prefix
        
    output:
         tuple val(output_file_suffix), path("${output_file_suffix}-${output_file_prefix}")
    
    script:
        def output_file = "${output_file_suffix}-${output_file_prefix}"
        def by_seq_flag = by_sequence != false ? "--only-positive-strand --by-seq" : ''
        """
        seqkit rmdup --threads ${task.cpus} ${by_seq_flag} ${input_file} --out-file ${output_file}
        """
}


process LOCATE_REGEX_MATCHES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val patterns
    output:
        path('matches.bed')
    
    script:
        """
        seqkit locate --threads ${task.cpus} --bed --only-positive-strand --use-regexp --pattern '${patterns.join("|")}' ${input_file} > matches.bed
        """
    
}

process EXTRACT_MATCHES {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.fastq.gz"
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        path bed_file
        val output_file_prefix
        
    output:
        tuple val(output_file_suffix), path("${output_file_suffix}-${output_file_prefix}")
    
    script:
        def output_file = "${output_file_suffix}-${output_file_prefix}"
        """
        seqkit subseq --threads ${task.cpus} --bed ${bed_file} ${input_file} --out-file ${output_file}
        """


}

process GET_MATCH_LENGTHS {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:bioawk/1.0'
    publishDir "${params.output_dir}/${ output_file_suffix }/filtering/${ output_file_prefix.contains('NO') ? 'discard' : 'keep' }", enabled: params.output_dir as boolean, mode: 'copy', overwrite: false, pattern: "*.tsv"
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val offset
        val output_file_prefix
    output:
        tuple val(output_file_suffix), path("${output_file_suffix}-${output_file_prefix}")
    
    script:
        def output_file = "${output_file_suffix}-${output_file_prefix}"
        """
        bioawk -c fastx 'BEGIN {OFS="\t";print "read","match_length","match_length-${offset}","sequence"} {print \$name,length(\$seq), length(\$seq)-${offset},\$seq }' ${input_file} > ${output_file}
        """
}

process TRANSLATE_TO_AA_SEQUENCE {
    memory '4 GB'
    cpus 4
    module 'StdEnv/2020:seqkit/2.3.1'
    
    input:
        tuple val(output_file_suffix), path(input_file, stageAs: 'input_file.fastq.gz')
        val frames
    output:
        tuple val(output_file_suffix), path('translated_sequences.faa.gz')
    
    script:
        """
        seqkit translate --threads ${task.cpus} --append-frame --frame ${frames.join(',')} ${input_file} --out-file 'translated_sequences.faa.gz'
        """    
}




