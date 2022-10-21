FROM ubuntu:22.04

# Install apt packages.
RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    r-base \
    vim \
    unzip \
    tree

# Setting up container
RUN mkdir -p ./orange

WORKDIR /orange

RUN conda create --name GG python=3 \
    && conda init bash \
    && echo "conda activate GG" >> ~/.bashrc

# Update path.
ENV PATH="/orange/software/${PATH}"

# Entry point or command on docker run usage
CMD [ "echo Welcome_to_orange" ]

