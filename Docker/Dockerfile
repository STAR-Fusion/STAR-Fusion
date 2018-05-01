FROM ubuntu:16.04

MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python automake make \
                                       wget curl libdb-dev \
				       bzip2 zlibc zlib1g zlib1g-dev  default-jre \
                       python-setuptools python-dev build-essential \
				       unzip libbz2-dev  liblzma-dev && \
    apt-get clean


RUN easy_install pip

RUN pip install numpy


RUN curl -L https://cpanmin.us | perl - App::cpanminus

## set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin

ENV DATA /usr/local/data
RUN mkdir $DATA


## perl lib installations

RUN cpanm install PerlIO::gzip
RUN cpanm install Set::IntervalTree  # now included w/ STAR-Fusion
RUN cpanm install DB_File
RUN cpanm install URI::Escape
RUN cpanm install Carp::Assert
RUN cpanm install JSON::XS.pm


######################
## Tool installations:
######################


# blast
WORKDIR $SRC
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.5.0/ncbi-blast-2.5.0+-x64-linux.tar.gz && \
    tar xvf ncbi-blast-2.5.0+-x64-linux.tar.gz && \
        cp ncbi-blast-2.5.0+/bin/* $BIN && \
            rm -r ncbi-blast-2.5.0+
            


## install hmmer for custom ctat genome lib construction
WORKDIR $SRC
RUN wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
      tar zxvf hmmer-3.1b2-linux-intel-x86_64.tar.gz  && \
      cd hmmer-3.1b2-linux-intel-x86_64 && \
      cp binaries/* /usr/local/bin/





########
# Samtools


 
ENV SAMTOOLS_VERSION=1.7

RUN SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2" && \
   cd $SRC && \
   wget $SAMTOOLS_URL && \
   tar xvf samtools-${SAMTOOLS_VERSION}.tar.bz2 && \
   cd samtools-${SAMTOOLS_VERSION}/htslib-${SAMTOOLS_VERSION} && ./configure && make && make install && \
   cd ../ && ./configure --without-curses && make && make install


########
# Trinity

ENV TRINITY_VERSION=2.6.6

RUN TRINITY_URL="https://github.com/trinityrnaseq/trinityrnaseq/archive/Trinity-v${TRINITY_VERSION}.tar.gz" && \
   cd $SRC && \
   wget $TRINITY_URL && \
   tar xvf Trinity-v${TRINITY_VERSION}.tar.gz && \
   cd trinityrnaseq-Trinity-v${TRINITY_VERSION} && make


ENV TRINITY_HOME /usr/local/src/trinityrnaseq-Trinity-v${TRINITY_VERSION}


## Bowtie2
WORKDIR $SRC
RUN wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.3.1/bowtie2-2.3.3.1-linux-x86_64.zip/download -O bowtie2-2.3.3.1-linux-x86_64.zip && \
    unzip bowtie2-2.3.3.1-linux-x86_64.zip && \
    mv bowtie2-2.3.3.1-linux-x86_64/bowtie2* $BIN && \
    rm *.zip && \
    rm -r bowtie2-2.3.3.1-linux-x86_64

## Jellyfish
WORKDIR $SRC
RUN wget https://github.com/gmarcais/Jellyfish/releases/download/v2.2.7/jellyfish-2.2.7.tar.gz && \
    tar xvf jellyfish-2.2.7.tar.gz && \
    cd jellyfish-2.2.7/ && \
    ./configure && make && make install
            
## Salmon
WORKDIR $SRC
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v0.9.1/Salmon-0.9.1_linux_x86_64.tar.gz && \
    tar xvf Salmon-0.9.1_linux_x86_64.tar.gz && \
    ln -s $SRC/Salmon-latest_linux_x86_64/bin/salmon $BIN/.



###############
## STAR-Fusion:
WORKDIR $SRC
ENV STAR_FUSION_VERSION=1.4.0
ENV STARF_CHECKOUT=f08b71f

RUN apt-get install -y git

RUN git clone --recursive https://github.com/STAR-Fusion/STAR-Fusion.git && \
     cd STAR-Fusion && \
     git checkout $STARF_CHECKOUT && \
     make

ENV STAR_FUSION_HOME $SRC/STAR-Fusion

## FusionInspector and FusionAnnotator are bundled with STAR-Fusion


##############
## STAR

ENV STAR_VERSION=2.6.0a
# https://github.com/alexdobin/STAR/archive/2.6.0a.tar.gz
RUN STAR_URL="https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.tar.gz" &&\
    wget -P $SRC $STAR_URL &&\
    tar -xvf $SRC/${STAR_VERSION}.tar.gz -C $SRC && \
    mv $SRC/STAR-${STAR_VERSION}/bin/Linux_x86_64_static/STAR /usr/local/bin


########
# GMAP  (compile this last because this version unfortunately disrupts some headers in DL_LIBRARY_PATH)

ENV GMAP_VERSION=2017-11-15
WORKDIR $SRC
RUN GMAP_URL="http://research-pub.gene.com/gmap/src/gmap-gsnap-$GMAP_VERSION.tar.gz" && \
    wget $GMAP_URL && \
    tar xvf gmap-gsnap-$GMAP_VERSION.tar.gz && \
    cd gmap-$GMAP_VERSION && ./configure && make && make install


