FROM trinityctat/fusioninspector:2.9.0

MAINTAINER bhaas@broadinstitute.org


RUN apt-get clean && apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8


###############################################
## Tools needed for building a CTAT Genome lib.

# blast
WORKDIR $SRC
ENV BLAST_VERSION=2.9.0
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/${BLAST_VERSION}/ncbi-blast-${BLAST_VERSION}+-x64-linux.tar.gz && \
    tar xvf ncbi-blast-${BLAST_VERSION}+-x64-linux.tar.gz && \
        cp ncbi-blast-${BLAST_VERSION}+/bin/* /usr/local/bin/


# hmmer3:
WORKDIR $SRC
RUN wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
    tar xvf hmmer-3.1b2-linux-intel-x86_64.tar.gz && \
        cp hmmer-3.1b2-linux-intel-x86_64/binaries/* /usr/local/bin/
        



## Dfam scan
WORKDIR $SRC
RUN wget https://dfam.org/releases/Dfam_3.1/infrastructure/dfamscan.pl.gz && \
     gunzip dfamscan.pl.gz && \
     chmod 755 dfamscan.pl && \
     mv dfamscan.pl $BIN/


## add Picard tools
## Picard
WORKDIR $SRC

RUN wget https://github.com/broadinstitute/picard/releases/download/2.20.3/picard.jar

ENV PICARD_HOME $SRC


###############
## STAR-Fusion:
WORKDIR $SRC

ENV STAR_FUSION_VERSION=1.13.0
ENV STARF_CHECKOUT=1e12a4e154bd2ba8cf9aed1d063cf7b6bc8ac931


RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/STAR-Fusion/STAR-Fusion.git && \
     cd STAR-Fusion && \
     git checkout $STARF_CHECKOUT && \
     git submodule init && git submodule update && \
     cd FusionInspector && \
     git submodule init && git submodule update && make

ENV STAR_FUSION_HOME $SRC/STAR-Fusion


ENV PATH="$SRC/STAR-Fusion:$SRC/STAR-Fusion/FusionInspector:${PATH}"



