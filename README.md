### Nextflow workflows for characterizing bovine immunological nanopore sequencing data
This workflow has been tested on [Narval](https://docs.alliancecan.ca/wiki/Narval) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems. With a bit of editing these scripts should be able to run on any system with [Nextflow](https://www.nextflow.io/docs/latest/index.html), [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [Fastp](https://github.com/OpenGene/fastp), [Seqkit](https://bioinf.shenwei.m), and [Bioawk](https://github.com/lh3/bioawk) installed. 

### Running the pipeline with no changes.


#### Running the pipeline steps individually
Assuming you have launched an interactive job with 8cpu cores and 4G of RAM per cpu

1. Run fastp
- To run with standard length parameters and no deduplication
`bash fastp_filtering.sh <path/to/folder/with/bc*.fastq.gz/files> <output_folder>`

- To run with standard length parameters and deduplication
`bash fastp_filtering.sh -D <path/to/folder/with/bc*.fastq.gz/files> <output_folder>`

This will create `<output_folder>/bc*/bc*-fastp` which contains 
```
bc*-fastp_failed.fastq.gz
bc*-fastp_filtered.fastq.gz
bc01-fastp-report.html
bc01-fastp_report.json
```


This will create a folder called `something or other` in the current folder and launch a set of [meta-farm](https://docs.alliancecan.ca/wiki/META-Farm) jobs. When finished  

When done there will be a collection of folders inside `path/to/output/folder` (one per sample) with the following sub-folder structure.

Check quality and trim sequences using Fastqc and Fastp
Assuming you've put the basecalled files in `~/projects/${SLURM_ACCOUNT}/bovine_nanopore_data` and that you are currently in a folder that you want all the results in.
```
export SCRIPTS_DIR="somewhere"

module load meta-farm/1.0.2

farm_init.run fastqc_fastp-farm

find ~/projects/${SLURM_ACCOUNT}/bovine_nanopore_data -name '*.fastq.gz' | parallel --dry-run 'NXF_WORK=$SLURM_TMPDIR/work nextflow run '${SCRIPTS_DIR}'/fastqc_and_fastp.nf --input_file {}  --output_dir '$(pwd)/'$(echo "{/.}" | sed "s/.fastq//")_results' > fastqc_fastp-farm/table.dat

eval cp ${SCRIPTS_DIR}/fastqc_and_fastp-job_script.sh fastqc_fastp-farm/job_script.sh
eval cp ${SCRIPTS_DIR}/single_case.sh fastqc_fastp-farm/single_case.sh

cd fastqc_fastp-farm && submit.run 4
```



2. Run filtering pipeline on each fastp trimmed file.
Same assumptions as before.
```
cd ..
farm_init.run IgM_filtering-farm

find bc*/fastp -name 'bc*trimmed.fastq.gz' | parallel --dry-run 'NXF_WORK=$SLURM_TMPDIR/work nextflow run '${SCRIPTS_DIR}'/IgM_filtering.nf --input_file '$(pwd)'/{}  --output_dir '$(pwd)/'$(echo "{/.}" | sed "s/-trimmed.fastq//")_results' > IgM_filtering-farm/table.dat

eval cp ${SCRIPTS_DIR}/IgM_filtering-job_script.sh IgM_filtering-farm/job_script.sh
eval cp ${SCRIPTS_DIR}/single_case.sh IgM_filtering-farm/single_case.sh

cd IgM_filtering-farm && submit.run 4 
```


Use query.run inside fastqc_fastp-farm to check on overall jobs status
If you have a choice of which def-account_name to use when you submit jobs you can over ride the default one for the meta-farms by submitting with `submit.run 4 '--account def-other_account'`
