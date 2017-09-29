############################################################
# Dockerfile to build container rnaseq pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:1.2

MAINTAINER Shaun Adkins <sadkins@som.umaryland.edu>

EXPOSE 80

# The project name
ARG PROJECT=rnaseq

#--------------------------------------------------------------------------------
# SOFTWARE

# Installed via apt-get 
#ARG BEDTOOLS_VERSION=2.17.0-1
#ARG BOWTIE_VERSION=1.0.0-5
#ARG CUMMERBUND_VERSION=2.4.1-1
#ARG EDGER_VERSION=3.4.2+dfsg-2
#ARG FASTQC_VERSION=0.10.1+dfsg-2
#ARG FASTX_TOOLKIT_VERSION=0.0.14-1
#ARG HTSEQ_VERSION=0.5.4p3-2
#ARG PYTHON_VERSION=2.7
#ARG SAMTOOLS_VERSION=0.1.19.1 - For Tophat
#ARG TOPHAT_VERSION=2.0.9-1ubuntu1

ARG CUFFLINKS_VERSION=2.0.2
ARG CUFFLINKS_DOWNLOAD_URL=http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-${CUFFLINKS_VERSION}.Linux_x86_64.tar.gz

# Installing via rpkg.sh
#ARG DESEQ_VERSION=1.10.1

ARG HTSLIB_VERSION=1.3.1
ARG HTSLIB_DOWNLOAD_URL=https://github.com/samtools/htslib/archive/${HTSLIB_VERSION}.tar.gz

#ARG IGV_VERSION=2.3.92
#ARG IGV_DOWNLOAD_URL=https://github.com/igvteam/igv.git

ARG SAMTOOLS_VERSION=1.3.1
ARG SAMTOOLS_DOWNLOAD_URL=https://github.com/samtools/samtools/archive/${SAMTOOLS_VERSION}.tar.gz

ARG UCSC_UTILS=git://github.com/ENCODE-DCC/kentUtils.git

# Giant RUN command
# 1) Lets install some packages
# 2) Create directories needed for installs (putting here to reduce layers created)

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends software-properties-common \
	&& add-apt-repository ppa:openjdk-r/ppa \
	&& apt-get -qq update && apt-get -qq install -y --no-install-recommends openjdk-8-jdk \
	ant \
	automake \
	autotools-dev \
	bedtools \
	bowtie \
	fastqc \
	fastx-toolkit \
	libmagic-dev \
	libmysqlclient-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libpng-dev \
	libssl-dev \
	libxml2 \
	mysql-client-5.5 \
	mysql-client-core-5.5 \
	openssl \
	python2.7 \
	python-htseq \
	r-bioc-edger \
	r-bioc-cummerbund \
	samtools \
	rsync \
	tophat \
	&& apt-get -qq clean autoclean \
	&& apt-get -qq autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /usr/src/cufflinks \
	/usr/src/htslib \
	/usr/src/samtools

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

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
# Cufflinks
WORKDIR /usr/src/cufflinks
RUN curl -SL $CUFFLINKS_DOWNLOAD_URL -o cufflinks.tar.gz \
	&& tar --strip-components=1 -xvzf cufflinks.tar.gz -C /usr/src/cufflinks \
	&& rm cufflinks.tar.gz \
	&& ln -s /usr/src/cufflinks /opt/packages/cufflinks \
	&& chmod 755 /opt/packages/cufflinks/*

#--------------------------------------------------------------------------------
# DESeq
COPY rpkg.sh /tmp/.
RUN /tmp/rpkg.sh

#--------------------------------------------------------------------------------
# IGV
#WORKDIR /usr/src
#RUN git clone $IGV_DOWNLOAD_URL \
#	&& cd igv \
#	&& git checkout tags/v${IGV_VERSION} \
#	&& ant \
#	&& ln -s /usr/src/igv/igv.jar /opt/packages/igv.jar

#--------------------------------------------------------------------------------
# USCS Utils

COPY .hg.conf /root/.
RUN git clone $UCSC_UTILS \
	&& cd kentUtils \
	&& make \
	&& sudo rsync -a -P ./bin/ /usr/local/bin/kentUtils/ \
	&& export PATH=/usr/local/bin/kentUtils:$PATH \
	&& chmod 600 /root/.hg.conf

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
	&& touch /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& chmod 0666 /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& cp /tmp/project.config /opt/projects/$PROJECT/workflow/.

# Making this as a volume in case we'd like to pass this data to another image
#VOLUME /opt/projects/$PROJECT/output_repository

# Run last bits as root
USER root
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

# Lastly change to root directory
WORKDIR /
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
