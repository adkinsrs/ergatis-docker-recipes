#!/bin/bash

Rver="R-3.3.1"

# The "Matrix" package dependency will fail if these aren't symlinked
ln -s /usr/lib/liblapack.so.3 /usr/lib/liblapack.so
ln -s /usr/lib/libblas.so.3 /usr/lib/libblas.so

echo "install.packages(c(\"survival\"), repos=\"https://lib.stat.cmu.edu/R/CRAN/\")" | R --save --restore
echo "source(\"http://bioconductor.org/biocLite.R\");
biocLite(c(\"DESeq\"), ask=FALSE)" | R --save --restore

# done
