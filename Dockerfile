FROM ubuntu:22.04

# Install apt packages.
RUN apt-get update &&
    apt-get install -y \
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
        vim \
        git \
        tree

# Setting up container
RUN mkdir -p ./orange \
    && mkdir ./orange/RBP \
    && mkdir ./orange/envs

# Setting work environment
WORKDIR /orange

# Cloning git repo
RUN git clone https://github.com/dimiboeckaerts/PhageRBPdetection.git

# Setting up environments

COPY ./envs/rbp.yml ./envs
RUN conda create --name rbp python=3 \
    && conda init bash \
    && echo "conda activate rbp" >> ~/.bashrc

# Update path.
ENV PATH="/orange/software/${PATH}"

# Entry point or command on docker run usage
CMD [ "echo Welcome_to_orange" ]

