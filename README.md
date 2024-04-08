### Nextflow workflows for characterizing bovine immunological nanopore sequencing data
This workflow has been tested on [Narval](https://docs.alliancecan.ca/wiki/Narval) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems. With a bit of editing these scripts should be able to run on any system with [Nextflow](https://www.nextflow.io/docs/latest/index.html), [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [Fastp](https://github.com/OpenGene/fastp), [Seqkit](https://bioinf.shenwei.m), and [Bioawk](https://github.com/lh3/bioawk) installed. 

### Running the pipeline with no changes.
`sbatch --output pipeline_run-%j.out path/to/run_pipeline.sh path/to/base/called/files/folder path/to/output/folder`
