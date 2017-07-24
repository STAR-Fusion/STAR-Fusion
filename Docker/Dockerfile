FROM ubuntu:16.04

MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python automake make \
                                       wget curl libdb-dev \
				       bzip2 zlibc zlib1g zlib1g-dev  default-jre \
				       unzip && \
    apt-get clean

RUN curl -L https://cpanmin.us | perl - App::cpanminus

## set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin

ENV DATA /usr/local/data
RUN mkdir $DATA


## perl lib installations

RUN cpanm install Set::IntervalTree  # now included w/ STAR-Fusion
RUN cpanm install DB_File
RUN cpanm install URI::Escape
RUN cpanm install Carp::Assert
RUN cpanm install JSON::XS.pm

######################
## Tool installations:
######################



########
# GMAP

RUN GMAP_URL="http://research-pub.gene.com/gmap/src/gmap-gsnap-2017-01-14.tar.gz" && \
    cd $SRC && \
    wget $GMAP_URL && \
    tar xvf gmap-gsnap-2017-01-14.tar.gz && \
    cd gmap-2017-01-14 && ./configure && make && make install


ENV PERL5LIB ${STAR_FUSION_HOME}/PerlLib






## Bowtie2
WORKDIR $SRC
RUN wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.2/bowtie2-2.3.2-linux-x86_64.zip/download -O bowtie2-2.3.2-linux-x86_64.zip && \
    unzip bowtie2-2.3.2-linux-x86_64.zip && \
    mv bowtie2-2.3.2/bowtie2* $BIN && \
    rm *.zip && \
    rm -r bowtie2-2.3.2


##############
## STAR

ENV STAR_VERSION=2.5.3a

RUN STAR_URL="https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.tar.gz" &&\
    wget -P $SRC $STAR_URL &&\
    tar -xvf $SRC/${STAR_VERSION}.tar.gz -C $SRC && \
    mv $SRC/STAR-${STAR_VERSION}/bin/Linux_x86_64_static/STAR /usr/local/bin


###############
## STAR-Fusion:

ENV STAR_FUSION_VERSION=1.1.0

RUN STAR_FUSION_URL="https://github.com/STAR-Fusion/STAR-Fusion/releases/download/v${STAR_FUSION_VERSION}/STAR-Fusion_v${STAR_FUSION_VERSION}.tar.gz" && \
    cd $SRC && \
    wget $STAR_FUSION_URL && \
    tar xvf STAR-Fusion_v${STAR_FUSION_VERSION}.tar.gz && \
    cd STAR-Fusion_v${STAR_FUSION_VERSION} && make

ENV STAR_FUSION_HOME $SRC/STAR-Fusion_v${STAR_FUSION_VERSION}

## FusionInspector now included with STAR-Fusion


########
# Samtools

RUN SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2" && \
   cd $SRC && \
   wget $SAMTOOLS_URL && \
   tar xvf samtools-1.3.1.tar.bz2 && \
   cd samtools-1.3.1/htslib-1.3.1 && ./configure && make && make install && \
   cd ../ && ./configure --without-curses && make && make install


########
# Trinity

ENV TRINITY_VERSION=2.4.0

RUN TRINITY_URL="https://github.com/trinityrnaseq/trinityrnaseq/archive/Trinity-v${TRINITY_VERSION}.tar.gz" && \
   cd $SRC && \
   wget $TRINITY_URL && \
   tar xvf Trinity-v${TRINITY_VERSION}.tar.gz && \
   cd trinityrnaseq-Trinity-v${TRINITY_VERSION} && make


ENV TRINITY_HOME /usr/local/src/trinityrnaseq-Trinity-v${TRINITY_VERSION}


## slight hack to Trinity v2.4.0 to avoid failing on few reads in genome-guided mode:
COPY ensure_coord_sorted_sam.pl ${TRINITY_HOME}/util/support_scripts/ensure_coord_sorted_sam.pl


