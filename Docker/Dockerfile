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


##############
## STAR

ENV STAR_VERSION=2.5.3a

RUN STAR_URL="https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.tar.gz" &&\
    wget -P $SRC $STAR_URL &&\
    tar -xvf $SRC/${STAR_VERSION}.tar.gz -C $SRC && \
    mv $SRC/STAR-${STAR_VERSION}/bin/Linux_x86_64_static/STAR /usr/local/bin


###############
## STAR-Fusion:

ENV STAR_FUSION_VERSION=1.2.0

RUN STAR_FUSION_URL="https://github.com/STAR-Fusion/STAR-Fusion/releases/download/STAR-Fusion-v1.2.0/STAR-Fusion-v1.2.0.FULL.tar.gz" && \
    cd $SRC && \
    wget $STAR_FUSION_URL && \
    tar xvf STAR-Fusion-v1.2.0.FULL.tar.gz && \
    cd STAR-Fusion-v1.2.0 && make

ENV STAR_FUSION_HOME $SRC/STAR-Fusion-v1.2.0

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

ENV TRINITY_VERSION=2.5.1

RUN TRINITY_URL="https://github.com/trinityrnaseq/trinityrnaseq/archive/Trinity-v${TRINITY_VERSION}.tar.gz" && \
   cd $SRC && \
   wget $TRINITY_URL && \
   tar xvf Trinity-v${TRINITY_VERSION}.tar.gz && \
   cd trinityrnaseq-Trinity-v${TRINITY_VERSION} && make


ENV TRINITY_HOME /usr/local/src/trinityrnaseq-Trinity-v${TRINITY_VERSION}


