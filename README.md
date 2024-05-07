# Nextflow workflows for characterizing bovine immunological nanopore sequencing data
This workflow has been tested on [Narval](https://docs.alliancecan.ca/wiki/Narval) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems. With a bit of editing these scripts should be able to run on any system with [Nextflow](https://www.nextflow.io/docs/latest/index.html), [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [Fastp](https://github.com/OpenGene/fastp), [Seqkit](https://bioinf.shenwei.m), and [Bioawk](https://github.com/lh3/bioawk) installed. 

### Running the pipeline with default parameters.
`sbatch --output pipeline_run-%j.out path/to/run_pipeline.sh path/to/base/called/files/folder path/to/output/folder`

This will run fastp with deduplication enabled and the default read length filters on ever bc*.fastq.gz file
in `path/to/base/called/files/folder` followed by IgM filtering for every `fastp-filtered` file in `path/to/output/folder/fastp-filtered` 

Then fastqc, and seqkit stats is run on every *.fastq.gz file under path/to/output/folder and the results put in 
`path/to/output/folder/fastqc_data` and `path/to/output/folder/sequence_stats` respectively.



### Manually running each step
These steps should be run in an interactive job.
The nextflow workflows take an input folder and an output folder. All samples are automatically
placed in a subfolder under the output folder.


1. Fastp filtering
#### Default length filters, deduplication enabled
`fastp_filtering.sh -D base_called_files_folder results/fastp-filtered_folder`

#### Default length filters, no deduplication
`fastp_filtering.sh base_called_files_folder results/fastp-filtered_folder`

#### default minimum read length filter, no max length filter, no deduplication
`fastp_filtering.sh -M 0 base_called_files_folder results/fastp-filtered_folder`

#### default maximum read length filter, no min length filter, no deduplication
`fastp_filtering.sh -m 0 base_called_files_folder results/fastp-filtered_folder`

#### no min or max read length filter, no deduplication
`fastp_filtering.sh -m 0 -M 0 base_called_files_folder fastp-filtered_folder`


2. IgM filtering
The IgM filtering script takes an input folder and an output folder. It then 
runs all `bc*-<filter>.fastq.gz` through the pipeline and puts them in `ouput_folder/bc*-<filter>`

#### Reads that passed fastp filtering step
`IgM_filtering.sh fastp-filtered_folder path/to/output/folder/IgM-filtered`

#### Reads that failed fastp filtering step
`IgM_filtering.sh -f "fastp_failed" fastp-filtered_folder path/to/output/folder/IgM-filtered`

To run a single file file through the IgM filtering
`IgM_filtering.sh fastp-filtered_folder/bc## path/to/output/folder/IgM-filtered`


3. Run fastqc on all fastq.gz files in the output folder
`fastqc.sh path/to/output/folder path/to/output/folder/fastqc_data`


4. Run seqkit stats on all fastq.gz files in the output folder
`seqkit_stats.sh path/to/output/folder path/to/output/folder/sequence_stats`

