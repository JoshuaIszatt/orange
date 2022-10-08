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

# Setting up environments
COPY ./build/*txt ./

RUN conda create --name curate --file package-list.txt \
    && conda init bash \
    && echo "conda activate curate" >> ~/.bashrc

RUN conda create --name rbp_detect --file package-list2.txt \
    && conda init bash

RUN conda create --name annotate --file package-list3.txt \
    && conda init bash

# Directory for software installation (these need to be added to bashrc below)
WORKDIR /orange/software

# Reset working directory.
WORKDIR /orange

# Copying pipeline scripts
COPY ./project_9/pipelines/* \
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

# Entry point or command on docker run usage
CMD [ "echo You are using orange:0.0.1" ]

