#!/bin/bash

Rver="R-3.0.2"

echo "source(\"http://bioconductor.org/biocLite.R\"); 
biocLite(c(\"cummeRbund\", \"DESeq\", \"edgeR\"), ask=FALSE)" | R --save --restore

# done
