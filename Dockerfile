FROM iszatt/phanatic:1.0.1

# Setting up directories
RUN mkdir -p ./orange \
    && mkdir ./orange/IN \
    && mkdir ./orange/OUT \
    && mkdir ./orange/DATA \
    && mkdir ./orange/SCRIPTS \
    && mkdir ./orange/SOFTWARE \
    && mkdir ./orange/ENVIRONMENTS \
    && mkdir ./orange/MANUAL

RUN mv /phanatic/SOFTWARE/* ./orange/SOFTWARE \
    && rm -rf ./phanatic

COPY ./build/*txt ./

RUN conda create --name PADLOC --file PADLOC-list.txt

RUN conda create --name crispr --file crisprdetect-list.txt \
    && conda init bash

##RUN wget https://github.com/dcouvin/CRISPRCasFinder/archive/refs/heads/master.zip \
    #&& unzip master.zip \
    #&& rm master.zip \
    #&& cd ./CRISPRCasFinder-master \
    #&& bash installer_UBUNTU.sh 
    #&& source ~/.profile

#RUN wget http://search.cpan.org/CPAN/authors/id/Y/YA/YANICK/Parallel-ForkManager-1.19.tar.gz \
#&& tar xvzf Parallel-ForkManager-1.19.tar.gz \
#&& cd Parallel-ForkManager-1.19 \
#&& perl Makefile.PL && make test #&& make install

# Update path.
ENV PATH="/orange/SOFTWARE/bbmap:${PATH}"
ENV PATH="/orange/SOFTWARE/SPAdes-3.15.4-Linux/bin:${PATH}"
ENV PATH="/orange/SCRIPTS:${PATH}"
#ENV PATH="/orange/software/CRISPRCasFinder.pl:${PATH}"
# Reset working directory.

WORKDIR /orange/SCRIPTS

COPY ./scripts/* \
    ./

COPY ./pipelines/* \
    ./

# Reset working directory.
WORKDIR /orange

CMD [ "echo orange" ]

