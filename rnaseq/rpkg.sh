#!/bin/bash

Rver="R-3.1.1"

# base code
#apt-get --force-yes -y update

# Install and build R (cannot use 'deb' because Ubuntu version Lucid is not supported anymore)
#curl https://cran.r-project.org/src/base/R-3/${Rver}.tar.gz | tar -C /opt -zx
#cd /opt/${Rver}
#/opt/${Rver}/configure --with-x=no; make; make install

#apt-get --force-yes -y install r-base
#apt-get --force-yes -y install r-base-dev

# Need to install DESeq
echo "install.packages(c(repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" | R --save --restore

echo "source(\"http://bioconductor.org/biocLite.R\");
biocLite(\"DESeq\")" | R --save --restore

# done
