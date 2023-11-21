### A nextflow workflow for characterizing bovine immunological nanopore sequencing data
This workflow has been tested on [Graham](https://docs.alliancecan.ca/wiki/Graham) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems or any system with [Nextflow](https://www.nextflow.io/docs/latest/index.html) and [Seqkit](https://bioinf.shenwei.me/seqkit/) installed. 



## For a single data-set
```
#Assuming this is an interactive job and have set INPUT_FILE AND OUTPUT_DIR
module load StdEnv/2020 nextflow/23.04.3 seqkit/2.3.1

NXF_WORK=$SLURM_TMPDIR/work nextflow run ~/projects/def-dhodgins/SCRIPTS/IgM_filtering.nf --input_file $INPUT_FILE  --output_dir $OUTPUT_DIR
#If you want the temporary results in the current folder remove the NXF_WORK=$SLURM_TMPDIR/work
```

