############################################################
# Dockerfile to build container lgtseek pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:1.2

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

ARG PICARD_VERSION=2.9.0
ARG PICARD_DOWNLOAD_URL=https://github.com/broadinstitute/picard.git

ARG PRINSEQ_VERSION=0.20.4
ARG PRINSEQ_DOWNLOAD_URL=https://sourceforge.net/projects/prinseq/files/standalone/prinseq-lite-${PRINSEQ_VERSION}.tar.gz

ARG SAMTOOLS_VERSION=1.3.1
ARG SAMTOOLS_DOWNLOAD_URL=https://github.com/samtools/samtools/archive/${SAMTOOLS_VERSION}.tar.gz

ARG SRA_VERSION=2.9.1
ARG SRA_DOWNLOAD_URL=https://github.com/ncbi/sra-tools/archive/${SRA_VERSION}.tar.gz

# Giant RUN command to reduce layers created
# 1) Install the scripts required for "add-apt-repository"
# 2) Setup the openjdk 8 repo
### NOTE: OpenJDK-8-JDK is natively not available for Ubuntu 14.04 so we need a workaround here
# 3) Install java8
# 4) Lets install the other stuff now
# 5) Install CPAN modules
# 6) Create directories needed for installs

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends software-properties-common \
	&& add-apt-repository ppa:openjdk-r/ppa \
	&& apt-get -qq update && apt-get -qq install -y --no-install-recommends openjdk-8-jdk \
	ant \
	automake \
	autotools-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libmagic-dev \
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
	/usr/src/htslib \
	/usr/src/samtools \
	/usr/src/prinseq \
	/usr/src/ncbi/sratoolkit \
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
	&& make samtools \
	&& make install

#--------------------------------------------------------------------------------
# PICARD -- install in /opt/packages/picard
# This downloads the latest version of Picard-tools

WORKDIR /usr/src

# 1) Update certificates (so gradlew doesn't break)
# 2) Clone latest version of PicardTools from GitHub and install
RUN update-ca-certificates -f \
	&& git config --global http.sslVerify false \
	&& git clone ${PICARD_DOWNLOAD_URL} \
	&& cd /usr/src/picard \
	&& git checkout tags/$PICARD_VERSION \
	&& ./gradlew shadowJar -Djavax.net.ssl.trustAnchors=/etc/ssl/certs/java/cacerts \
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

WORKDIR /usr/src/ncbi/blast
RUN curl -SL $NCBI_BLAST_DOWNLOAD_URL -o blast.tar.gz \
	&& tar --strip-components=1 -xvzf blast.tar.gz -C /usr/src/ncbi/blast \
	&& rm blast.tar.gz \
	&& ln -s /usr/src/ncbi/blast/bin/* /usr/bin/

#--------------------------------------------------------------------------------
# PROJECT REPOSITORY SETUP

# Have ergatis.ini point to new project so we can quickly access it
RUN sed -i.bak "s/CUSTOM/$PROJECT/g" /var/www/html/ergatis/cgi/ergatis.ini

USER www-data

COPY project.config /tmp/.
RUN mkdir -p /opt/projects/$PROJECT \
	&& mkdir -m 0777 /opt/projects/$PROJECT/output_repository \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/lock_files \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/project_id_repository \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/runtime \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/runtime/pipeline \
    #&& mkdir -m 0777 /opt/projects/$PROJECT/output_repository/gather_lgtseek_files \
	&& touch /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& chmod 0666 /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& cp /tmp/project.config /opt/projects/$PROJECT/workflow/.

# Making this as a volume in case we'd like to pass this data to another image
VOLUME /opt/projects/$PROJECT/output_repository/gather_lgtseek_files/

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
COPY accession_lists_dir /local/db/
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

CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
