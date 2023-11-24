### Nextflow workflows for characterizing bovine immunological nanopore sequencing data
This workflow has been tested on [Graham](https://docs.alliancecan.ca/wiki/Graham) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems. With a bit of editing these scripts should be able to run on any system with [Nextflow](https://www.nextflow.io/docs/latest/index.html) and [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [Fastp](https://github.com/OpenGene/fastp) and [Seqkit](https://bioinf.shenwei.m) installed. 

1. Check quality and trim sequences using Fastqc and Fastp
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
