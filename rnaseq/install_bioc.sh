#!/bin/bash

Rver="R-3.0.2"

echo "install.packages(repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" | R --save --restore

echo "source(\"http://bioconductor.org/biocLite.R\"); 
biocLite(c(\"cummeRbund\", \"DESeq\", \"edgeR\"), ask=FALSE)" | R --save --restore

# done
