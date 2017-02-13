############################################################
# Dockerfile to build container lgtseek pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:latest

MAINTAINER Shaun Adkins <sadkins@som.umaryland.edu>

EXPOSE 80

# The project name
ARG PROJECT=lgtseek

#--------------------------------------------------------------------------------
# SOFTWARE

ARG BWA_VERSION=0.7.15
ARG BWA_DOWNLOAD_URL=https://github.com/lh3/bwa/archive/v${BWA_VERSION}.tar.gz

ARG NCBI_BLAST_VERSION=2.2.9
ARG NCBI_BLAST_DOWNLOAD_URL=ftp://ftp.ncbi.nlm.nih.gov/blast/executables/legacy/${NCBI_BLAST_VERSION}/blast-${NCBI_BLAST_VERSION}-amd64-linux.tar.gz

ARG HTSLIB_VERSION=1.3.1
ARG HTSLIB_DOWNLOAD_URL=https://github.com/samtools/htslib/archive/${HTSLIB_VERSION}.tar.gz

#ARG HTSJDK_VERSION=2.7.0
#ARG HTSJDK_DOWNLOAD_URL=https://github.com/samtools/htsjdk/archive/${HTSJDK_VERSION}.tar.gz

#ARG PICARD_VERSION=2.5.0
#ARG PICARD_DOWNLOAD_URL=https://github.com/broadinstitute/picard/archive/${PICARD_VERSION}.tar.gz

ARG PRINSEQ_VERSION=0.20.4
ARG PRINSEQ_DOWNLOAD_URL=http://mirror.ufs.ac.za/applications/prinseq/standalone/prinseq-lite-${PRINSEQ_VERSION}.tar.gz
#ARG PRINSEQ_DOWNLOAD_URL=https://sourceforge.net/projects/prinseq/files/standalone/prinseq-lite-${PRINSEQ_VERSION}.tar.gz

ARG SAMTOOLS_VERSION=1.3.1
ARG SAMTOOLS_DOWNLOAD_URL=https://github.com/samtools/samtools/archive/${SAMTOOLS_VERSION}.tar.gz

ARG SRA_VERSION=2.7.0
ARG SRA_DOWNLOAD_URL=https://github.com/ncbi/sra-tools/archive/${SRA_VERSION}.tar.gz

# 1) Install the python script required for "add-apt-repository"
# 2) Setup the openjdk 8 repo
### NOTE: OpenJDK-8-JDK is natively not available for Ubuntu 14.04 so we need a workaround here
# 3) Install java8
# 4) Lets install the other stuff now

RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common \
	&& add-apt-repository ppa:openjdk-r/ppa \
	&& apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk \
	ant \
	automake \
	autotools-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libmagic-dev \
	libxml2 \
	ncbi-blast+ \
	&& apt-get clean autoclean \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# CPAN modules
RUN cpanm --force \
	MongoDB \
	Bio::Perl \
	Bio::DB::EUtilities
#	Mouse

# For some reason BioPerl was not installing so here are two backups to try
#RUN cpanm --force CJFIELDS/BioPerl-1.6.924.tar.gz
#RUN cpanm --mirror-only --mirror https://stratopan.com/MeNoSeeGood/Manatee/master BioPerl

# Create directories needed for installs (putting here to reduce layers created)
RUN mkdir -p /usr/src/bwa \
	&& mkdir -p /usr/src/htslib \
	&& mkdir -p /usr/src/samtools \
	&& mkdir -p /usr/src/prinseq \
	&& mkdir -p /usr/src/ncbi/sratoolkit \
	&& mkdir -p /opt/packages/sra-tools \
	&& mkdir -p /usr/src/ncbi


#--------------------------------------------------------------------------------
# BWA -- install in /opt/packages/bwa

WORKDIR /usr/src/bwa

RUN curl -SL $BWA_DOWNLOAD_URL -o bwa.tar.gz \
	&& tar --strip-components=1 -xvzf bwa.tar.gz -C /usr/src/bwa \
	&& rm bwa.tar.gz \
	&& make all \
	&& ln -s /usr/src/bwa /opt/packages/bwa \
	&& chmod 755 /opt/packages/bwa/*

#--------------------------------------------------------------------------------
# HTSLIB -- install in /opt/packages/htslib (required for Samtools)

WORKDIR /usr/src/htslib

RUN curl -SL $HTSLIB_DOWNLOAD_URL -o htslib.tar.gz \
	&& tar --strip-components=1 -xvzf htslib.tar.gz -C /usr/src/htslib \
	&& rm htslib.tar.gz \
	&& autoconf

#--------------------------------------------------------------------------------
# SAMTOOLS -- install in /opt/packages/samtools
# Had to consult this to get it to build https://github.com/samtools/samtools/issues/500

WORKDIR /usr/src/samtools

RUN curl -SL $SAMTOOLS_DOWNLOAD_URL -o samtools.tar.gz \
	&& tar --strip-components=1 -xvzf samtools.tar.gz -C /usr/src/samtools \
	&& rm samtools.tar.gz \
	&& mkdir autoconf \
	&& wget -O autoconf/ax_with_htslib.m4 https://raw.githubusercontent.com/samtools/samtools/develop/m4/ax_with_htslib.m4 \
	&& wget -O autoconf/ax_with_curses.m4 https://raw.githubusercontent.com/samtools/samtools/develop/m4/ax_with_curses.m4 \
	#&& wget -O ./configure.ac https://raw.githubusercontent.com/samtools/samtools/develop/configure.ac \
	&& aclocal -I./autoconf \
	&& autoconf \
	&& ./configure --prefix=/opt/packages/samtools \
	&& make \
	&& make install

#--------------------------------------------------------------------------------
# PICARD -- install in /opt/packages/picard
# This downloads the latest version of Picard-tools

WORKDIR /usr/src

# 1) Update certificates (so gradlew doesn't break)
# 2) Clone latest version of PicardTools from GitHub and install
RUN update-ca-certificates -f \
	&& git config --global http.sslVerify false \
	&& git clone https://github.com/broadinstitute/picard.git
WORKDIR /usr/src/picard
RUN ./gradlew shadowJar -Djavax.net.ssl.trustAnchors=/etc/ssl/certs/java/cacerts \
	&& ln -s /usr/src/picard /opt/packages/picard

#--------------------------------------------------------------------------------
# PRINSEQ -- install in /opt/packages/prinseq

WORKDIR /usr/src/prinseq

RUN curl -SL $PRINSEQ_DOWNLOAD_URL -o prinseq.tar.gz \
	&& tar --strip-components=1 -xvzf prinseq.tar.gz -C /usr/src/prinseq \
	&& rm prinseq.tar.gz \
	&& ln -s /usr/src/prinseq /opt/packages/prinseq

#--------------------------------------------------------------------------------
# SRA_TOOKKIT -- install in /opt/packages/sra-tools

WORKDIR /usr/src/ncbi

# First install some dependenciea
# Clone the Git repos first
RUN git clone https://github.com/ncbi/ncbi-vdb.git \
	&& git clone https://github.com/ncbi/ngs.git

# Install NCBI-vdb
WORKDIR /usr/src/ncbi/ncbi-vdb
RUN ./configure \
	&& make \
	&& make install

# Install NGS
WORKDIR /usr/src/ncbi/ngs
RUN ./configure \
	&& make -C ngs-sdk \
	&& make -C ngs-java \
	&& make -C ngs-python \
	&& make -C ngs-sdk install \
	&& make -C ngs-java install \
	&& make -C ngs-python install

# Now install SRA toolkit
WORKDIR /usr/src/ncbi/sratoolkit
RUN curl -SL $SRA_DOWNLOAD_URL -o sra.tar.gz \
	&& tar --strip-components=1 -xvzf sra.tar.gz -C /usr/src/ncbi/sratoolkit \
	&& rm sra.tar.gz \
	&& ./configure --prefix=/opt/packages/sra-tools \
	&& make \
	&& make install

#--------------------------------------------------------------------------------
# NCBI_BLAST+ -- Installed via apt-getExecs in /usr/bin/

#--------------------------------------------------------------------------------
# PROJECT REPOSITORY SETUP

# Have ergatis.ini point to new project so we can quickly access it
RUN sed -i.bak "s/CUSTOM/$PROJECT/g" /var/www/html/ergatis/cgi/ergatis.ini

USER www-data

COPY project.config /tmp/.
RUN mkdir -p /opt/projects/$PROJECT \
	&& mkdir /opt/projects/$PROJECT/output_repository \
	&& mkdir /opt/projects/$PROJECT/workflow \
	&& mkdir /opt/projects/$PROJECT/workflow/lock_files \
	&& mkdir /opt/projects/$PROJECT/workflow/project_id_repository \
	&& mkdir /opt/projects/$PROJECT/workflow/runtime \
	&& mkdir /opt/projects/$PROJECT/workflow/runtime/pipeline \
	&& touch /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& cp /tmp/project.config /opt/projects/$PROJECT/workflow/.

# Making this as a volume in case we'd like to pass this data to another image
VOLUME /opt/projects/$PROJECT/output_repository

#--------------------------------------------------------------------------------
# PIPELINE_CHANGES - Files that need to deviate from the installed lgtseek pipeline in order to function in Docker

COPY changed_pipeline_files/blast2lca.lgt.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast2lca.lgt.config
COPY changed_pipeline_files/blast_lgt_finder.lgt.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast_lgt_finder.lgt.config
COPY changed_pipeline_files/sam2lca.lgt.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/sam2lca.lgt.config
COPY changed_pipeline_files/sam2lca.mb.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/sam2lca.mb.config
COPY changed_pipeline_files/sam2lca.xml /opt/ergatis/docs/sam2lca.xml

#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run

# These are just scripts I am using to create and run the pipeline without using the UI
# For testing purposes
#COPY configure_pipeline.sh /opt/scripts/configure_pipeline.sh
#COPY run_pipeline.sh /opt/scripts/run_pipeline.sh

# Lastly change to root directory
#CMD ["/bin/bash"]
WORKDIR /
# ... and start apache as root
USER root
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
