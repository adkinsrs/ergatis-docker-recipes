#!/bin/bash

Rver="R-3.3.1"

# Installs to get R working
#apt-get --force-yes -y update
#apt-get --force-yes -y install gfortran libbz2-dev libpcre3 libpcre3-dev libcurl4-openssl-dev

# Install and build R (Using 'apt-get install' on Ubuntu Trusty installs version 3.0.2 of R)
#curl https://cran.r-project.org/src/base/R-3/${Rver}.tar.gz | tar -C /opt -zx
#cd /opt/${Rver}
#/opt/${Rver}/configure --with-readline=no --with-x=no || exit 1
#make || exit 1
#make install || exit 1

#apt-get --force-yes -y install r-base-dev

echo "source(\"http://bioconductor.org/biocLite.R\"); 
biocLite(c(\"DESeq\"), ask=FALSE)" | R --save --restore

# done
