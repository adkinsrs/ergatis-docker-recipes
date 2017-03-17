############################################################
# Dockerfile to build container rnaseq pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:devel

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
#ARG SAMTOOLS_VERSION=0.1.19-1
#ARG TOPHAT_VERSION=2.0.9-1ubuntu1

# Keeping internal used version for reference
#ARG BOWTIE_VERSION=0.12.19

ARG CUFFLINKS_VERSION=2.0.2

ARG DESEQ_VERSION=1.10.1

# Keeping internal used version for reference
#ARG EDGER_VERSION=2.4.6

ARG IGV_VERSION=2.3.32

ARG R_VERSION_NEW=2.15.2
ARG R_VERSION_OLD=2.14.1

ARG UCSC_UTILS=git://github.com/ENCODE-DCC/kentUtils.git

# Lets install some packages

RUN apt-get -q update && apt-get -q install -y --no-install-recommends software-properties-common \
	bedtools \
	bowtie \
	fastqc \
	fastx-toolkit \
	libmagic-dev \
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
	tophat \
	&& apt-get -q clean autoclean \
	&& apt-get -q autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

# Create directories needed for installs (putting here to reduce layers created)
#RUN mkdir -p /usr/src/bowtie \
#	&& mkdir -p /usr/src/samtools

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
VOLUME /opt/projects/$PROJECT/output_repository

# Run last bits as root
USER root
#--------------------------------------------------------------------------------
# INSTALL PIPELINE
COPY build_$PROJECT.pl /tmp/.
RUN /usr/bin/perl /tmp/build_$PROJECT.pl /opt/ergatis \ 
	&& ln -s /opt/ergatis/pipeline_builder /var/www/html/pipeline_builder

#--------------------------------------------------------------------------------
# PIPELINE_CHANGES - Files that need to deviate from the installed lgtseek pipeline in order to function in Docker

# Set number of parallel runs for changed files
RUN num_cores=$(grep -c ^processor /proc/cpuinfo) \
	&& find /opt/ergatis/pipeline_templates -type f -exec /usr/bin/perl -pi -e 's/\$;NODISTRIB\$;\s?=\s?0/\$;NODISTRIB\$;='$num_cores'/g' {} \;
#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run

# Lastly change to root directory
WORKDIR /
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
