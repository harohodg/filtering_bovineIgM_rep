### Some scripts for characterizing bovine immunological nanopore sequencing data
These scripts have been tested on [Graham](https://docs.alliancecan.ca/wiki/Graham) but should work on any of the other [Digital Research Alliance of Canada](https://alliancecan.ca/en) systems or on any system with the following programs installed which use [Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod).

- [Seqkit](https://bioinf.shenwei.me/seqkit/)


## General steps
The following examples assume the scripts are in your path, if not you will need to execute them via an absolute or relative path.

1. Screen fasta/fastq files which have a specific subsequence.

For example the forward primer `AGATGAACCCACTGTGGACC` with zero mismatches
`seqkit_filter_sequences.sh -p '.*(read=\d+)\s+(ch=\d+).*' -P 'forwardPrimer_0mismatches:$1:$2' ../../DATA/originaldata_Oct2022/amplicon.fastq 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_0mismatches.fastq.gz`
```
seqkit_filter_sequences.sh version 1.0.0
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1  && seqkit grep --threads 1  --use-regexp  --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern 'AGATGAACCCACTGTGGACC'  ../../DATA/originaldata_Oct2022/amplicon.fastq  | seqkit replace --threads 1 --pattern '.*(read=\d+)\s+(ch=\d+).*' --replacement 'forwardPrimer_0mismatches:$1:$2' --line-width 0 
DONE running seqkit
```

`seqkit_filter_sequences.sh -p '.*(read=\d+)\s+(ch=\d+).*' -P 'forwardPrimer_1mismatches:$1:$2' -m 1 ../../DATA/originaldata_Oct2022/amplicon.fastq 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_1mismatches.fastq.gz`
```
seqkit_filter_sequences.sh version 1.0.0
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1  && seqkit grep --threads 1   --max-mismatch 1 --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern 'AGATGAACCCACTGTGGACC'  ../../DATA/originaldata_Oct2022/amplicon.fastq  | seqkit replace --threads 1 --pattern '.*(read=\d+)\s+(ch=\d+).*' --replacement 'forwardPrimer_1mismatches:$1:$2' --line-width 0 
DONE running seqkit
```

`seqkit_filter_sequences.sh -p '.*(read=\d+)\s+(ch=\d+).*' -P 'forwardPrimer_2mismatches:$1:$2' -m 2 ../../DATA/originaldata_Oct2022/amplicon.fastq 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_2mismatches.fastq.gz`
```
seqkit_filter_sequences.sh version 1.0.0
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1  && seqkit grep --threads 1   --max-mismatch 2 --by-seq --only-positive-strand  --immediate-output --line-width 0 --pattern 'AGATGAACCCACTGTGGACC'  ../../DATA/originaldata_Oct2022/amplicon.fastq  | seqkit replace --threads 1 --pattern '.*(read=\d+)\s+(ch=\d+).*' --replacement 'forwardPrimer_2mismatches:$1:$2' --line-width 0
DONE running seqkit
```

Now lets look at how many sequences we found
`module load StdEnv/2020 seqkit/2.3.1 && seqkit stats *.gz`
```
file                                            format  type  num_seqs      sum_len  min_len  avg_len  max_len
../../DATA/originaldata_Oct2022/amplicon.fastq  FASTQ   DNA    392,540  368,817,914      135    939.6   10,179
forwardPrimer_0mismatches.fastq.gz              FASTQ   DNA    240,909  229,075,500      138    950.9    4,968
forwardPrimer_1mismatches.fastq.gz              FASTQ   DNA    250,470  238,072,077      138    950.5    4,968
forwardPrimer_2mismatches.fastq.gz              FASTQ   DNA    263,692  250,381,576      135    949.5    4,968
```

2. Extract the actual matches so we can see how variable the matches are. Not using the greedy flag so it should stop after the first match in any sequence.
However, when we allow mismatches then we then seqkit ignores the non-greedy flag.

`seqkit_extract_sequences.sh -s ',' forwardPrimer_0mismatches.fastq.gz 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_0mismatches_matches.csv.gz`
```
seqkit_extract_sequences.sh version 1.0.0
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1 && seqkit locate --threads 1 --immediate-output --non-greedy --use-regexp  --only-positive-strand --pattern AGATGAACCCACTGTGGACC forwardPrimer_0mismatches.fastq.gz | awk -v OFS=',' '{ if (NR == 1) { {print $1,$2,$3,$4,$5,$6,"length",$7} } else {print $1,$2,$3,$4,$5,$6,$6-$5+1,$7} }' 
DONE running seqkit
```

`seqkit_extract_sequences.sh -m 1 -s ',' forwardPrimer_1mismatches.fastq.gz 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_1mismatches_matches.csv.gz`
```
seqkit_extract_sequences.sh version 1.0.0
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1 && seqkit locate --threads 1 --immediate-output --non-greedy  --max-mismatch 1 --only-positive-strand --pattern AGATGAACCCACTGTGGACC forwardPrimer_1mismatches.fastq.gz | awk -v OFS=',' '{ if (NR == 1) { {print $1,$2,$3,$4,$5,$6,"length",$7} } else {print $1,$2,$3,$4,$5,$6,$6-$5+1,$7} }' 
[INFO] flag -G (--non-greedy) ignored when giving flag -m (--max-mismatch)
DONE running seqkit
```

`seqkit_extract_sequences.sh -m 2 -s ',' forwardPrimer_2mismatches.fastq.gz 'AGATGAACCCACTGTGGACC' | gzip --best --stdout > forwardPrimer_2mismatches_matches.csv.gz`
```
Running seqkit/2.3.1 with
module load StdEnv/2020 seqkit/2.3.1 && seqkit locate --threads 1 --immediate-output --non-greedy  --max-mismatch 2 --only-positive-strand --pattern AGATGAACCCACTGTGGACC forwardPrimer_2mismatches.fastq.gz | awk -v OFS=',' '{ if (NR == 1) { {print $1,$2,$3,$4,$5,$6,"length",$7} } else {print $1,$2,$3,$4,$5,$6,$6-$5+1,$7} }' 
[INFO] flag -G (--non-greedy) ignored when giving flag -m (--max-mismatch)
DONE running seqkit
```

And now we check how many matches there were, and how different they were.
`find . -name '*.csv.gz' -printf '%P\n' | parallel 'echo {} $(expr $(zcat {} | wc -l) - 1)' | sort`
```
forwardPrimer_0mismatches_matches.csv.gz 245124
forwardPrimer_1mismatches_matches.csv.gz 255153
forwardPrimer_2mismatches_matches.csv.gz 268880
```

Interesting. It looks like even with the non-greedy flag the 0 mismatches file still has more results then the corresponding filtered file.
`zcat forwardPrimer_0mismatches_matches.csv.gz | tail -n+2 | cut -f8 -d',' | sort | uniq -c`
```
245124 AGATGAACCCACTGTGGACC
```

`zcat forwardPrimer_1mismatches_matches.csv.gz | tail -n+2 | cut -f8 -d',' | sort | uniq -c | sort --numeric-sort`
```
      1 AGATGAACCCACGGTGGACC
      1 AGATGAACCCACTGGGGACC
      1 AGATGAACCCACTGTGCACC
      1 AGATGAACCCACTGTGTACC
.....
    916 AGATGAGCCCACTGTGGACC
   2738 TGATGAACCCACTGTGGACC
 245125 AGATGAACCCACTGTGGACC
```

`zcat forwardPrimer_2mismatches_matches.csv.gz | tail -n+2 | cut -f8 -d',' | sort | uniq -c | sort --numeric-sort`
```
      1 AAAGGAACCCACTGTGGACC
      1 AAATGAACCCACCGTGGACC
      1 AAATGAACCCACTATGGACC
      1 AAATGAACCCACTGTGGAAC
      1 AAATGAACCCACTGTGGAGC
.....
   2099 AGATGAACCCACCTTGGACC
   2738 TGATGAACCCACTGTGGACC
   2832 GAATGAACCCACTGTGGACC
 245125 AGATGAACCCACTGTGGACC
```

So are there sequences showing up multiple times?
`zcat forwardPrimer_0mismatches_matches.csv.gz | tail -n+2 | cut -f1 -d',' | sort | uniq | wc -l`
```
235666
```
Yes, yes there are. I suspect these are some of the dimer/trimer/etc sequences

`zcat forwardPrimer_0mismatches_matches.csv.gz | tail -n+2 | cut -f1 -d',' | sort | uniq -c | sort --numeric-sort --reverse | head`
```
      4 forwardPrimer_0mismatches:read=815:ch=305
      4 forwardPrimer_0mismatches:read=730:ch=72
      4 forwardPrimer_0mismatches:read=718:ch=70
      4 forwardPrimer_0mismatches:read=47:ch=402
      4 forwardPrimer_0mismatches:read=401:ch=43
      4 forwardPrimer_0mismatches:read=3867:ch=442
      4 forwardPrimer_0mismatches:read=365:ch=454
      4 forwardPrimer_0mismatches:read=352:ch=195
      4 forwardPrimer_0mismatches:read=341:ch=237
      4 forwardPrimer_0mismatches:read=314:ch=125
```

`seqkit grep --by-name --pattern 'forwardPrimer_0mismatches:read=815:ch=305' forwardPrimer_0mismatches.fastq.gz  | grep 'AGATGAACCCACTGTGGACC'`
Yep, the forward primer is showing up in 4 places. Ah, but that read label also shows up twice. Hmm.

We might be able to get around that with a different regex (although that won't work for mismatches >= 1) or just filtering by min/max sequence length.

