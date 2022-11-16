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
    unzip \
    vim 

# Setting up directories
RUN mkdir -p ./orange \
    && mkdir ./orange/IN \
    && mkdir ./orange/OUT \
    && mkdir ./orange/DATA \
    && mkdir ./orange/SCRIPTS \
    && mkdir ./orange/SOFTWARE \
    && mkdir ./orange/ENVIRONMENTS \
    && mkdir ./orange/MANUAL

# Set up python environments, install packages, and activate conda env.
#WORKDIR /orange/ENVIRONMENTS

#COPY ./build/*txt ./
#RUN conda create --name assemble --file package-list.txt \
#    && conda init bash \
#    && echo "conda activate assemble" >> ~/.bashrc

#RUN conda create --name annotate --file package-list2.txt \
#    && conda init bash

#RUN git clone https://github.com/dimiboeckaerts/PhageRBPdetection.git

# Setting up software
#WORKDIR /orange/software

#RUN wget https://sourceforge.net/projects/bbmap/files/BBMap_38.96.tar.gz/download -O BBMap_38.96.tar.gz \
#    && tar -xvzf BBMap_38.96.tar.gz \
#    && rm BBMap_38.96.tar.gz

#RUN wget http://cab.spbu.ru/files/release3.15.4/SPAdes-3.15.4-Linux.tar.gz \
#    && tar -xzf SPAdes-3.15.4-Linux.tar.gz \
#    && rm SPAdes-3.15.4-Linux.tar.gz

#RUN wget https://github.com/samtools/samtools/releases/download/1.15.1/samtools-1.15.1.tar.bz2 \
#    && tar -xvf samtools-1.15.1.tar.bz2 \
#    && rm samtools-1.15.1.tar.bz2 \
#    && cd samtools-1.15.1 \
#    && ./configure --without-curses --disable-bz2 --disable-lzma \
#    && make \
#    && make install

#RUN cpanm File::Copy::Link

# Update path.
#ENV PATH="/orange/SOFTWARE/bbmap:${PATH}"
#ENV PATH="/orange/SOFTWARE/SPAdes-3.15.4-Linux/bin:${PATH}"
#ENV PATH="/orange/SCRIPTS:${PATH}"

# Reset working directory.
#WORKDIR /orange/SCRIPTS

#COPY ./pipelines/* \
#    ./

#COPY ./support/* \
#    ./

# Reset working directory.
WORKDIR /orange

CMD [ "echo orange" ]

