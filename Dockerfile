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

# Set up python environments, install packages, and activate conda env.
COPY ./build/*txt ./
RUN conda create --name curate --file package-list.txt \
    && conda init bash \
    && echo "conda activate curate" >> ~/.bashrc

RUN conda create --name rbp_detect --file package-list2.txt \
    && conda init bash

# Directory for software installation.
WORKDIR /orange/software

# Install perl modules.
RUN cpanm File::Copy::Link

# Reset working directory.
WORKDIR /orange

# Copying pipeline scripts
COPY ./project_5/pipelines/* \
    ./

# Copying support scripts
COPY ./project_9/support/* \
    ./

# Copying build files into container
COPY ./build/*.txt \
    ./

# Copying Dockerfile into text for reference files
COPY ./Dockerfile \
    ./docker.txt

# Update path.
ENV PATH="/orange/software/${PATH}"

CMD [ "echo You are using orange:0.0.1" ]
