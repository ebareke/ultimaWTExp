# Citing ultimaWTExp

If you use **ultimaWTExp** in work that leads to a publication, please cite the
workflow **and** the underlying tools for the stages you actually ran. The tools
do the science; the workflow orchestrates them reproducibly.

A machine-readable version of the workflow citation is in
[`CITATION.cff`](CITATION.cff) (GitHub renders a "Cite this repository" button
from it).

---

## 1. Cite the workflow

> Bareke E, Ethan M., Conrad B. *ultimaWTExp: a reproducible Nextflow RNA-seq
> workflow from FASTQ to biological interpretation.* Version 1.0.0. 2026.
> https://github.com/ebareke/ultimaWTExp

BibTeX:

```bibtex
@software{ultimaWTExp_2026,
  author  = {Bareke, Eric and Ethan, M. and Conrad, B.},
  title   = {{ultimaWTExp}: a reproducible Nextflow RNA-seq workflow
             from FASTQ to biological interpretation},
  version = {1.0.0},
  year    = {2026},
  url     = {https://github.com/ebareke/ultimaWTExp},
  license = {MIT}
}
```

## 2. Cite the workflow manager

- **Nextflow** — Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C.
  *Nextflow enables reproducible computational workflows.* Nat Biotechnol. 2017;
  35(4):316–319. doi:[10.1038/nbt.3820](https://doi.org/10.1038/nbt.3820)

## 3. Cite the tools you used

Cite only the stages your run actually exercised (the run's
`pipeline_info/software_versions.yml` records the exact versions used).

### Read QC & trimming
- **FastQC** — Andrews S. *FastQC: a quality control tool for high throughput
  sequence data.* Babraham Bioinformatics, 2010. https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- **fastp** — Chen S, Zhou Y, Chen Y, Gu J. *fastp: an ultra-fast all-in-one
  FASTQ preprocessor.* Bioinformatics. 2018;34(17):i884–i890.
  doi:[10.1093/bioinformatics/bty560](https://doi.org/10.1093/bioinformatics/bty560)
- **Trim Galore** — Krueger F. *Trim Galore.* Babraham Bioinformatics.
  https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/
- **Cutadapt** — Martin M. *Cutadapt removes adapter sequences from
  high-throughput sequencing reads.* EMBnet.journal. 2011;17(1):10–12.
  doi:[10.14806/ej.17.1.200](https://doi.org/10.14806/ej.17.1.200)
- **FastQ Screen** — Wingett SW, Andrews S. *FastQ Screen: A tool for multi-genome
  mapping and quality control.* F1000Res. 2018;7:1338.
  doi:[10.12688/f1000research.15931.2](https://doi.org/10.12688/f1000research.15931.2)

### Alignment & quantification
- **STAR** — Dobin A, Davis CA, Schlesinger F, et al. *STAR: ultrafast universal
  RNA-seq aligner.* Bioinformatics. 2013;29(1):15–21.
  doi:[10.1093/bioinformatics/bts635](https://doi.org/10.1093/bioinformatics/bts635)
- **HISAT2** — Kim D, Paggi JM, Park C, Bennett C, Salzberg SL. *Graph-based
  genome alignment and genotyping with HISAT2 and HISAT-genotype.* Nat Biotechnol.
  2019;37(8):907–915. doi:[10.1038/s41587-019-0201-4](https://doi.org/10.1038/s41587-019-0201-4)
- **Salmon** — Patro R, Duggal G, Love MI, Irizarry RA, Kingsford C. *Salmon
  provides fast and bias-aware quantification of transcript expression.*
  Nat Methods. 2017;14(4):417–419. doi:[10.1038/nmeth.4197](https://doi.org/10.1038/nmeth.4197)
- **SAMtools** — Danecek P, Bonfield JK, Liddle J, et al. *Twelve years of
  SAMtools and BCFtools.* GigaScience. 2021;10(2):giab008.
  doi:[10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008)
- **featureCounts (Subread)** — Liao Y, Smyth GK, Shi W. *featureCounts: an
  efficient general purpose program for assigning sequence reads to genomic
  features.* Bioinformatics. 2014;30(7):923–930.
  doi:[10.1093/bioinformatics/btt656](https://doi.org/10.1093/bioinformatics/btt656)
- **HTSeq** — Putri GH, Anders S, Pyl PT, Pimanda JE, Zanini F. *Analysing
  high-throughput sequencing data in Python with HTSeq 2.0.* Bioinformatics.
  2022;38(10):2943–2945. doi:[10.1093/bioinformatics/btac166](https://doi.org/10.1093/bioinformatics/btac166)

### Post-alignment QC
- **Picard** — Broad Institute. *Picard Toolkit.* http://broadinstitute.github.io/picard/
- **Qualimap 2** — Okonechnikov K, Conesa A, García-Alcalde F. *Qualimap 2:
  advanced multi-sample quality control for high-throughput sequencing data.*
  Bioinformatics. 2016;32(2):292–294. doi:[10.1093/bioinformatics/btv566](https://doi.org/10.1093/bioinformatics/btv566)
- **RSeQC** — Wang L, Wang S, Li W. *RSeQC: quality control of RNA-seq
  experiments.* Bioinformatics. 2012;28(16):2184–2185.
  doi:[10.1093/bioinformatics/bts356](https://doi.org/10.1093/bioinformatics/bts356)
- **preseq** — Daley T, Smith AD. *Predicting the molecular complexity of
  sequencing libraries.* Nat Methods. 2013;10(4):325–327.
  doi:[10.1038/nmeth.2375](https://doi.org/10.1038/nmeth.2375)
- **dupRadar** — Sayols S, Scherzinger D, Klein H. *dupRadar: a Bioconductor
  package for the assessment of PCR artifacts in RNA-Seq data.* BMC
  Bioinformatics. 2016;17:428. doi:[10.1186/s12859-016-1276-2](https://doi.org/10.1186/s12859-016-1276-2)

### Fusion & splicing
- **STAR-Fusion** — Haas BJ, Dobin A, Li B, et al. *Accuracy assessment of fusion
  transcript detection via read-mapping and de novo fusion transcript
  assembly-based methods.* Genome Biol. 2019;20(1):213.
  doi:[10.1186/s13059-019-1842-9](https://doi.org/10.1186/s13059-019-1842-9)
- **rMATS** — Shen S, Park JW, Lu ZX, et al. *rMATS: robust and flexible
  detection of differential alternative splicing from replicate RNA-Seq data.*
  PNAS. 2014;111(51):E5593–E5601. doi:[10.1073/pnas.1419161111](https://doi.org/10.1073/pnas.1419161111)

### Differential expression & interpretation
- **DESeq2** — Love MI, Huber W, Anders S. *Moderated estimation of fold change
  and dispersion for RNA-seq data with DESeq2.* Genome Biol. 2014;15(12):550.
  doi:[10.1186/s13059-014-0550-8](https://doi.org/10.1186/s13059-014-0550-8)
- **edgeR** — Robinson MD, McCarthy DJ, Smyth GK. *edgeR: a Bioconductor package
  for differential expression analysis of digital gene expression data.*
  Bioinformatics. 2010;26(1):139–140. doi:[10.1093/bioinformatics/btp616](https://doi.org/10.1093/bioinformatics/btp616)
- **tximport** — Soneson C, Love MI, Robinson MD. *Differential analyses for
  RNA-seq: transcript-level estimates improve gene-level inferences.* F1000Res.
  2015;4:1521. doi:[10.12688/f1000research.7563.2](https://doi.org/10.12688/f1000research.7563.2)
- **clusterProfiler** — Wu T, Hu E, Xu S, et al. *clusterProfiler 4.0: A
  universal enrichment tool for interpreting omics data.* Innovation (Camb).
  2021;2(3):100141. doi:[10.1016/j.xinn.2021.100141](https://doi.org/10.1016/j.xinn.2021.100141)
- **ReactomePA** — Yu G, He QY. *ReactomePA: an R/Bioconductor package for
  Reactome pathway analysis and visualization.* Mol BioSyst. 2016;12(2):477–479.
  doi:[10.1039/C5MB00663E](https://doi.org/10.1039/C5MB00663E)
- **MSigDB** (for GSEA gene sets) — Liberzon A, Birger C, Thorvaldsdóttir H, et al.
  *The Molecular Signatures Database (MSigDB) hallmark gene set collection.*
  Cell Syst. 2015;1(6):417–425. doi:[10.1016/j.cels.2015.12.004](https://doi.org/10.1016/j.cels.2015.12.004)

### Reporting
- **MultiQC** — Ewels P, Magnusson M, Lundin S, Käller M. *MultiQC: summarize
  analysis results for multiple tools and samples in a single report.*
  Bioinformatics. 2016;32(19):3047–3048. doi:[10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)
- **Quarto** — Allaire JJ, Teague C, Scheidegger C, Xie Y, Dervieux C. *Quarto.*
  https://quarto.org

---

*Versions of every tool used in a given run are recorded automatically in
`<outdir>/pipeline_info/software_versions.yml`.*
