FROM continuumio/anaconda3:2021.11

# Install apt packages.
RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    cpanminus \
    dirmngr \
    gnupg \
    libfreetype6-dev \
    libpng-dev \
    make \
    openjdk-17-jdk \
    openjdk-17-jre \
    pkg-config \
    python3-matplotlib \
    software-properties-common \
    r-base \
    unzip \
    vim 

# Setting up container
RUN mkdir -p ./orange \
    && mkdir ./orange/RBP \
    && mkdir ./orange/envs \
    && mkdir ./orange/software

# Setting work environment
WORKDIR /orange

COPY ./envs/* ./

RUN conda create --name assemble --file package-list.txt \
    && conda init bash \
    && echo "conda activate assemble" >> ~/.bashrc

RUN conda create --name annotate --file package-list2.txt \
    && conda init bash

#RUN git clone https://github.com/dimiboeckaerts/PhageRBPdetection.git

# Setting up software
WORKDIR /orange/software

RUN wget https://sourceforge.net/projects/bbmap/files/BBMap_38.96.tar.gz/download -O BBMap_38.96.tar.gz \
    && tar -xvzf BBMap_38.96.tar.gz \
    && rm BBMap_38.96.tar.gz

RUN wget http://cab.spbu.ru/files/release3.15.4/SPAdes-3.15.4-Linux.tar.gz \
    && tar -xzf SPAdes-3.15.4-Linux.tar.gz \
    && rm SPAdes-3.15.4-Linux.tar.gz

RUN wget https://github.com/samtools/samtools/releases/download/1.15.1/samtools-1.15.1.tar.bz2 \
    && tar -xvf samtools-1.15.1.tar.bz2 \
    && rm samtools-1.15.1.tar.bz2 \
    && cd samtools-1.15.1 \
    && ./configure --without-curses --disable-bz2 --disable-lzma \
    && make \
    && make install

# Update path.
ENV PATH="/phanatic/SOFTWARE/bbmap:${PATH}"
ENV PATH="/phanatic/SOFTWARE/SPAdes-3.15.4-Linux/bin:${PATH}"

# Entry point or command on docker run usage
CMD [ "echo Welcome_to_orange" ]

