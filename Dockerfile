############################################################
# Dockerfile to build container lgtseek pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:1.3

MAINTAINER Shaun Adkins <sadkins@som.umaryland.edu>

EXPOSE 80

# The project name
ARG PROJECT=lgtseek

#--------------------------------------------------------------------------------
# SOFTWARE

ARG BWA_VERSION=0.7.17
ARG BWA_DOWNLOAD_URL=https://github.com/lh3/bwa/archive/v${BWA_VERSION}.tar.gz

ARG NCBI_BLAST_VERSION=2.6.0
ARG NCBI_BLAST_DOWNLOAD_URL=ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/${NCBI_BLAST_VERSION}/ncbi-blast-${NCBI_BLAST_VERSION}+-x64-linux.tar.gz

ARG HTSLIB_VERSION=1.3.1
ARG HTSLIB_DOWNLOAD_URL=https://github.com/samtools/htslib/archive/${HTSLIB_VERSION}.tar.gz

ARG PICARD_VERSION=2.18.25
ARG PICARD_DOWNLOAD_URL=https://github.com/broadinstitute/picard/releases/download/${PICARD_VERSION}/picard.jar

ARG PRINSEQ_VERSION=0.20.4
ARG PRINSEQ_DOWNLOAD_URL=https://sourceforge.net/projects/prinseq/files/standalone/prinseq-lite-${PRINSEQ_VERSION}.tar.gz

ARG SAMTOOLS_VERSION=1.9
ARG SAMTOOLS_DOWNLOAD_URL=https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2

ARG SRA_VERSION=2.9.2
ARG SRA_DOWNLOAD_URL=http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${SRA_VERSION}/sratoolkit.${SRA_VERSION}-ubuntu64.tar.gz

# Giant RUN command to reduce layers created
# 1) Install the scripts required for "add-apt-repository"
# 2) Setup the openjdk 8 repo
### NOTE: OpenJDK-8-JDK is natively not available for Ubuntu 14.04 so we need a workaround here
# 3) Install java8
# 4) Lets install the other stuff now
# 5) Install CPAN modules
# 6) Create directories needed for installs

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends software-properties-common \
	automake \
	autotools-dev \
	libxml2 \
	&& apt-get -qq clean autoclean \
	&& apt-get -qq autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/bin/python3 /usr/bin/python \
	&& cpanm --force \
	MongoDB \
	Bio::Perl \
	Bio::DB::EUtilities \
	Try::Tiny \
	&& mkdir -p /usr/src/bwa \
	/usr/src/samtools \
	/usr/src/prinseq \
	/usr/src/ncbi/sratoolkit \
	/opt/packages/picard \
	/opt/packages/sra-tools \
	/usr/src/ncbi/blast

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

#--------------------------------------------------------------------------------
# BWA -- install in /opt/packages/bwa

WORKDIR /usr/src/bwa

RUN curl -SL $BWA_DOWNLOAD_URL -o bwa.tar.gz \
	&& tar --strip-components=1 -xvzf bwa.tar.gz -C /usr/src/bwa \
	&& rm bwa.tar.gz \
	&& make bwa \
	&& ln -s /usr/src/bwa /opt/packages/bwa \
	&& chmod 755 /opt/packages/bwa/*

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
# PICARD -- install in /opt/packages/picard

WORKDIR /opt/packages/picard
RUN curl -SL $PICARD_DOWNLOAD_URL -o picard.jar

#--------------------------------------------------------------------------------
# PRINSEQ -- install in /opt/packages/prinseq

WORKDIR /usr/src/prinseq

RUN curl -SL $PRINSEQ_DOWNLOAD_URL -o prinseq.tar.gz \
	&& tar --strip-components=1 -xvzf prinseq.tar.gz -C /usr/src/prinseq \
	&& rm prinseq.tar.gz \
	&& ln -s /usr/src/prinseq /opt/packages/prinseq

#--------------------------------------------------------------------------------
# SRA_TOOKKIT -- install in /opt/packages/sra-tools

WORKDIR /usr/src/ncbi/sratoolkit

RUN curl -SL $SRA_DOWNLOAD_URL -o sra.tar.gz \
	&& tar --strip-components=1 -xvzf sra.tar.gz -C /opt/packages/sra-tools \
	&& rm sra.tar.gz

#--------------------------------------------------------------------------------
# NCBI_BLAST+ -- Installed via apt-getExecs in /usr/bin/

WORKDIR /usr/src/ncbi/blast
RUN curl -SL $NCBI_BLAST_DOWNLOAD_URL -o blast.tar.gz \
	&& tar --strip-components=1 -xvzf blast.tar.gz -C /usr/src/ncbi/blast \
	&& rm blast.tar.gz \
	&& ln -s /usr/src/ncbi/blast/bin/* /usr/bin/

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
# PIPELINE_CHANGES - Files that need to deviate from the installed lgtseek pipeline in order to function in Docker

COPY taxdump /local/db/
COPY lgtseek_extras/accession_lists_dir /local/db/accession_lists_dir/
COPY changed_pipeline_files/blast2lca.lgt_d.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast2lca.lgt_d.config
COPY changed_pipeline_files/blast2lca.lgt_r.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast2lca.lgt_r.config
COPY changed_pipeline_files/blast_lgt_finder.lgt_d.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast_lgt_finder.lgt_d.config
COPY changed_pipeline_files/blast_lgt_finder.lgt_r.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/blast_lgt_finder.lgt_r.config
COPY changed_pipeline_files/sam2lca.lgt.config /opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/sam2lca.lgt.config
COPY changed_pipeline_files/sam2lca.xml /opt/ergatis/docs/sam2lca.xml
COPY changed_pipeline_files/determine_final_lgt.xml /opt/ergatis/docs/determine_final_lgt.xml

# Set number of parallel runs for changed files
RUN num_cores=$(grep -c ^processor /proc/cpuinfo) \
	&& find /opt/ergatis/pipeline_templates -type f -exec /usr/bin/perl -pi -e 's/\$;NODISTRIB\$;\s?=\s?0/\$;NODISTRIB\$;='$num_cores'/g' {} \;

#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run

WORKDIR /

ENTRYPOINT ["apache2"]
CMD ["-D", "FOREGROUND"]
