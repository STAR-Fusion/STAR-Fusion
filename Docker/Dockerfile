FROM ubuntu:16.04

MAINTAINER bhaas@broadinstitute.org

RUN apt-get update && apt-get install -y gcc g++ perl python automake make wget curl libdb-dev && \
    apt-get clean


RUN curl -L https://cpanmin.us | perl - App::cpanminus

## set up tool config and deployment area:

ENV SRC /usr/local/src
ENV BIN /usr/local/bin

ENV DATA /usr/local/data
RUN mkdir $DATA


## perl lib installations

RUN cpanm install Set::IntervalTree


######################
## Tool installations:
######################


##############
## STAR


RUN STAR_URL="https://github.com/alexdobin/STAR/archive/2.5.2a.tar.gz" &&\
    wget -P $SRC $STAR_URL &&\
    tar -xvf $SRC/2.5.2a.tar.gz -C $SRC && \
    mv $SRC/STAR-2.5.2a/bin/Linux_x86_64_static/STAR /usr/local/bin


###############
## STAR-Fusion:

RUN STAR_FUSION_URL="https://github.com/STAR-Fusion/STAR-Fusion/releases/download/v1.0.0/STAR-Fusion-v1.0.0.FULL.tar.gz" && \
    cd $SRC && \
    wget $STAR_FUSION_URL && \
    tar xvf STAR-Fusion-v1.0.0.FULL.tar.gz

ENV STAR_FUSION_HOME $SRC/STAR-Fusion-v1.0.0


###################
## FusionInspector

RUN FI_URL="https://github.com/FusionInspector/FusionInspector/releases/download/v1.0.0/FusionInspector-v1.0.0.FULL.tar.gz" && \
    cd $SRC && \
    wget $FI_URL && \
    tar -xvf FusionInspector-v1.0.0.FULL.tar.gz

ENV FUSION_INSPECTOR_HOME $SRC/FusionInspector-v1.0.0

RUN cpanm install DB_File

RUN cpanm install URI::Escape




