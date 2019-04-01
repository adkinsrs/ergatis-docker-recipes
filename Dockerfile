############################################################
# Dockerfile to build container rnaseq pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:1.3

LABEL maintainer="Shaun Adkins <sadkins@som.umaryland.edu>"

EXPOSE 80

# The project name
ARG PROJECT=rnaseq

#--------------------------------------------------------------------------------
# SOFTWARE

# Installed via apt-get
#ARG BOWTIE_VERSION=1.0.0-5
#ARG FASTX_TOOLKIT_VERSION=0.0.14-1
#ARG HTSEQ_VERSION=0.5.4p3-2
#ARG PYTHON_VERSION=2.7
#ARG SAMTOOLS_VERSION=0.1.19c	# For Tophat use
#ARG TOPHAT_VERSION=2.0.9-1ubuntu1

# Installing via install_bioc.sh
#ARG DESEQ_VERSION=1.10.1
#ARG CUMMERBUND_VERSION=2.4.1-1
#ARG EDGER_VERSION=3.4.2+dfsg-2

# Using Bedtools master branch on Github, which is v2.26.0 with some bugfixes
#ARG BEDTOOLS_VERSION=2.26.0
#ARG BEDTOOLS_DOWNLOAD_URL=https://github.com/arq5x/bedtools2/releases/download/v${BEDTOOLS_VERSION}/bedtools-${BEDTOOLS_VERSION}.tar.gz
ARG BEDTOOLS_DOWNLOAD_URL=https://github.com/arq5x/bedtools2.git

ARG CUFFLINKS_VERSION=2.2.1
ARG CUFFLINKS_DOWNLOAD_URL=http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-${CUFFLINKS_VERSION}.Linux_x86_64.tar.gz

ARG FASTQC_VERSION=0.11.8
ARG FASTQC_DOWNLOAD_URL=https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v${FASTQC_VERSION}.zip

ARG HISAT2_VERSION=2.1.0
ARG HISAT2_DOWNLOAD_URL=ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-${HISAT2_VERSION}-Linux_x86_64.zip

ARG SAMTOOLS_VERSION=1.9
ARG SAMTOOLS_DOWNLOAD_URL=https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2

ARG UCSC_UTILS=rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/

# Giant RUN command
# 1) Lets install some packages
# 2) Create directories needed for installs (putting here to reduce layers created)

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends software-properties-common \
	&& add-apt-repository ppa:openjdk-r/ppa \
	&& apt-get -qq update && apt-get -qq install -y --no-install-recommends \
	automake \
	autotools-dev \
	bowtie \
	fastx-toolkit \
	libxml2 \
	openssl \
	python2.7 \
	python2.7-dev \
	python-htseq \
	python-numpy \
	python-pip \
	rsync \
	samtools \
	tophat \
	unzip \
	# For R install
	gfortran \
    libbz2-dev \
	libcurl4-openssl-dev \
	liblzma-dev \
	libpcre3 \
	libpcre3-dev \
	# Other things
	&& cpanm --force \
	Spreadsheet::WriteExcel \
	&& pip install --upgrade pip numpy awscli \
	&& apt-get -qq clean autoclean \
	&& apt-get -qq autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /usr/src/cufflinks \
	/usr/src/samtools

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

#--------------------------------------------------------------------------------
# HISAT2 - install in /opt/packages/hisat2

WORKDIR /usr/src

RUN wget $HISAT2_DOWNLOAD_URL -O hisat2.zip \
	&& unzip hisat2.zip \
	&& ln -s /usr/src/hisat2-${HISAT2_VERSION} /opt/packages/hisat2 \
	&& chmod 755 /opt/packages/hisat2/*

#--------------------------------------------------------------------------------
# BEDTOOLS - install in /opt/packages/bedtools


RUN git clone $BEDTOOLS_DOWNLOAD_URL \
	&& cd bedtools2 \
	&& make \
	&& ln -s /usr/src/bedtools2 /opt/packages/bedtools \
	&& chmod 755 /opt/packages/bedtools/*

#---------------------------------------------------------------------------------
# FASTQC -- install in /opt/packages/fastqc
WORKDIR /usr/src

RUN curl -SL $FASTQC_DOWNLOAD_URL -o fastqc.zip \
	&& unzip fastqc.zip \
	&& rm fastqc.zip \
	&& ln -s /usr/src/FastQC /opt/packages/fastqc \
	&& chmod 755 /opt/packages/fastqc/*

#--------------------------------------------------------------------------------
# SAMTOOLS -- install in /opt/packages/samtools

WORKDIR /usr/src/samtools

RUN curl -SL $SAMTOOLS_DOWNLOAD_URL -o samtools.tar.bz2 \
	&& tar --strip-components=1 -xvjf samtools.tar.bz2 -C /usr/src/samtools \
	&& rm samtools.tar.bz2 \
	&& ./configure --prefix=/opt/packages/samtools --without-curses --disable-bz2 --disable-lzma \
	&& make \
	&& make install

#--------------------------------------------------------------------------------
# Cufflinks
WORKDIR /usr/src/cufflinks
RUN curl -SL $CUFFLINKS_DOWNLOAD_URL -o cufflinks.tar.gz \
	&& tar --strip-components=1 -xvzf cufflinks.tar.gz -C /usr/src/cufflinks \
	&& rm cufflinks.tar.gz \
	&& ln -s /usr/src/cufflinks /opt/packages/cufflinks \
	&& chmod 755 /opt/packages/cufflinks/*

#--------------------------------------------------------------------------------
# USCS Utils

COPY .hg.conf /root/.
RUN rsync -azvP ${UCSC_UTILS} /usr/local/bin/kentUtils \
 	&& export PATH=/usr/local/bin/kentUtils:$PATH \
 	&& chmod 600 /root/.hg.conf

#--------------------------------------------------------------------------------
# DESeq2, EdgeR, and CummeRbund
COPY install_bioc.sh /tmp/.
RUN /tmp/install_bioc.sh

#--------------------------------------------------------------------------------
# PROJECT REPOSITORY SETUP

# Change to root for last bits
USER root
RUN mkdir -m 0777 /mnt/input_data

#--------------------------------------------------------------------------------
# INSTALL PIPELINE
COPY build_$PROJECT.pl /tmp/.
RUN /usr/bin/perl /tmp/build_$PROJECT.pl /opt/ergatis \
	&& ln -s /opt/ergatis/pipeline_builder /var/www/html/pipeline_builder

#--------------------------------------------------------------------------------
# PIPELINE_CHANGES - Files that need to deviate from the installed rnaseq pipeline in order to function in Docker

# Set number of parallel runs for changed files
RUN num_cores=$(grep -c ^processor /proc/cpuinfo) \
	&& find /opt/ergatis/pipeline_templates -type f -exec /usr/bin/perl -pi -e 's/\$;NODISTRIB\$;\s?=\s?0/\$;NODISTRIB\$;='$num_cores'/g' {} \;

#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run
COPY execute_pipeline.sh /opt/scripts/execute_pipeline.sh
RUN chmod 755 /opt/scripts/execute_pipeline.sh

# Lastly change to root directory
WORKDIR /
#CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
ENTRYPOINT ["sh", "/opt/scripts/execute_pipeline.sh"]