#!/bin/bash

Rver="R-3.3.1"

# The "Matrix" package dependency will fail if these aren't symlinked
ln -s /usr/lib/liblapack.so.3 /usr/lib/liblapack.so
ln -s /usr/lib/libblas.so.3 /usr/lib/libblas.so

# Install and build R (Using 'apt-get install' on Ubuntu Trusty installs version 3.0.2 of R)
curl https://cran.r-project.org/src/base/R-3/${Rver}.tar.gz | tar -C /opt -zx
cd /opt/${Rver}
/opt/${Rver}/configure --with-readline=no --with-x=no || exit 1
make || exit 1
make install || exit 1

apt-get -qq install -y --no-install-recommends r-base-dev

# Install Bioconductor programs we need
echo "install.packages(c(\"devtools\", \"gplots\", \"survival\"), repos=\"http://lib.stat.cmu.edu/R/CRAN/\")" | R --save --restore
echo "source(\"http://bioconductor.org/biocLite.R\");
biocLite(c(\"cummeRbund\", \"DESeq\", \"edgeR\"), ask=FALSE)" | R --save --restore

# TODO - Eventually install  \"DESeq2\" as well

# RSQLite must be no higher than version 1.1.2, since cummeRbund is not compatible with later versions
echo "require(devtools); install_version(\"RSQLite\", version = \"1.1-2\", repos = \"http://cran.us.r-project.org\")" | R --save --restore


# done
