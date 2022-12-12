#!/bin/bash
TAG=$RANDOM
echo 'running from docker image'
echo $1
echo "$TAG"

# Orange
. ~/.bashrc
INPUT=/orange/IN
OUTPUT=/orange/OUT
TEMP=/orange/temp
RUN=/orange/SCRIPTS
mkdir -p ${TEMP}
DB=/orange/DATA
DATE=$(date +%d-%m-%Y)
IMAGE="orange v0.0.1"
PAPH=/opt/conda/envs/annotate/db/hmm
chmod -R 777 ./*

# Creating output directory and reference file
FIN=${OUTPUT}/ANALYSIS-${TAG}
mkdir -p ${FIN}
touch ${FIN}/reference.txt
echo ${IMAGE} >>${FIN}/reference.txt
echo ${DATE} >>${FIN}/reference.txt
echo ${TAG} >>${FIN}/reference.txt
echo $1 >>${FIN}/reference.txt

annotate() {

    #   Checking for databases
#    if [[ ! -d ${DB}/checkv-db-v1.6 ]]; then
#        echo "Cannot find checkv database directory"
#        checkv download_database ${DB}/
#        echo "Made checkv database"
#    fi

    for A in ${INPUT}/*.fasta; do
        file="$(basename ${A})"
        base="$(cut -d'.' -f1 <<<${file})"
        OUT=${FIN}/${base}
        mkdir -p ${OUT}
        
     ##Bakta Annotation
        if ! bakta \
            --db ${DB} \
            --prefix ${base} \
            --output ${OUT}/bakta \
            #--genus 
            #--species 
            --translation-table 11 \
            #--gram 
            --keep-contig-headers \
            --compliant \
            -t 8 \
            ${A}; then
            echo "Failed to Bakta annotate ${base}" >>>${OUT}/error.txt
        fi    

        if ! defense-finder \
            run -o ${OUT}/defense \
            ${OUT}/bakta/${base}.faa
            echo "Failed to defense finder annotate ${base}" >>>${OUT}/error.txt
        fi

        #   Prokka annotation with PHROGs
        #if ! prokka \
            #${A} \
            #--outdir ${OUT}/prokka \
            #--locustag ${base} \
            #--addgenes \
            #--notrna \
            #--kingdom Bacteria \
            #--gcode 11 \
            #--compliant; then
            #echo "Failed to annotate ${base}" >>${OUT}/error.txt
        #fi
        #conda deactivate
        #conda activate crispr
       
        #CRISPRcas Finder#
        #CRISPRCasFinder.pl -cas -gscf -gcode 11 \
        #-in ${A} \
        #-faa ${OUT}/prokka/${base}.faa \
        #-gff ${OUT}/prokka/${base}.gff \
        #-out ${OUT}/

        #CRISPR Detect
        


        #PADLOC (PRokaryotic Antiviral Defence LOCator)
        #conda deactivate
        #conda activate padloc

        #padloc --faa ${OUT}/prokka/${base}.faa \
        #--gff ${OUT}/prokka/${base}.gff \
        #--fna ${A} \
        #--crispr 
        #--outdir ${OUT}/padloc/

        ##Might have to move until after other annotation programs##
        #   Data wrangling for BRIG
        mkdir ${OUT}/BRIG-file
        python /orange/SCRIPTS/gbk2tsv.py --gbk ${OUT}/prokka_phrogs/*.gbk \
            --outdir ${OUT}/BRIG-file
        mv ${OUT}/BRIG-file/PROKKA* ${TEMP}/prokka.tsv
        R -f ${RUN}/brig.r
        mv ${TEMP}/* ${OUT}/BRIG-file/

        #   Running subsidiary analyses
        echo 'Running CheckV'
        export CHECKVDB=${DB}/checkv-db-v1.6
        if ! checkv end_to_end ${A} ${OUT}/checkv; then
            echo "Failed to perform CheckV for ${base}" >>${OUT}/error.txt
        fi

        abricate \
            --db argannot \
            ${A} \
            >${OUT}/argannot.txt

        abricate \
            --db card \
            ${A} \
            >${OUT}/card.txt

        abricate \
            --db ncbi \
            ${A} \
            >${OUT}/ncbi.txt

        abricate \
            --db plasmidfinder \
            ${A} \
            >${OUT}/plasmidfinder.txt

        abricate \
            --db resfinder \
            ${A} \
            >${OUT}/resfinder.txt

        abricate \
            --db vfdb \
            ${A} \
            >${OUT}/vfdb.txt

        abricate \
            --db megares \
            ${A} \
            >${OUT}/megares.txt

    done

}

network() {

    echo "You have chosen to produce a reticulate network using these sequences"
    conda deactivate
    conda activate annotate

    if [[ -f "/opt/conda/envs/annotate/db/hmm/all_phrogs.hmm" ]]; then
        echo 'Pressing PHROGs database'
        hmmpress ${PAPH}/all_phrogs.hmm
    fi

    # Annotation
    for A in ${INPUT}/*.fasta; do
        file="$(basename ${A})"
        base="$(cut -d'.' -f1 <<<${file})"
        echo ${base}

        #   Assigning work files
        OUT=${FIN}/${base}

        #   Prokka annotation with PHROGs
        prokka \
            ${A} \
            --locustag ${base} \
            --hmms ${PAPH}/all_phrogs.hmm \
            --outdir ${OUT} \
            --kingdom viruses

        #   Moving files
        mv ${OUT}/*.faa ${TEMP}/prokka.faa
        mv ${OUT}/*.tsv ${TEMP}/prokka.tsv
        rm ${OUT}/*
        R -f ${RUN}/network.r
        sed '/^>/ s/ .*//' ${TEMP}/prokka.faa >${TEMP}/network.faa
        rm ${TEMP}/prokka.tsv
        rm ${TEMP}/prokka.faa
        mv ${TEMP}/network.csv ${OUT}/${base}.csv
        mv ${TEMP}/network.faa ${OUT}/${base}.faa

    done

    for A in ${INPUT}/*.fasta; do
        file="$(basename ${A})"
        base="$(cut -d'.' -f1 <<<${file})"

        #   Assigning work files
        OUT=${FIN}/${base}
        mkdir -p ${OUT}

        #   Copying files to make combined network
        cp ${OUT}/${base}.faa ${TEMP}/
        cp ${OUT}/${base}.csv ${TEMP}/

    done

    #   Combining csv and fasta files
    mkdir ${FIN}/results
    cat ${TEMP}/*.faa >${TEMP}/combined.faa
    mv ${TEMP}/combined.faa ${FIN}/
    rm ${TEMP}/*.faa
    R -f ${RUN}/combine-networks.r
    mv ${TEMP}/combined.csv ${FIN}/
    rm ${TEMP}/*.csv

    #   Producing network
    echo 'Producing vcontact network'
    conda deactivate
    conda activate vcontact2

    vcontact2 \
        --raw-proteins ${FIN}/combined.faa \
        --proteins-fp ${FIN}/combined.csv \
        --db 'ProkaryoticViralRefSeq211-Merged' \
        --output-dir ${FIN}/results
}

reorder() {

    echo "You have chosen to reorder these genomes"

}

$1

chmod -R 777 ./*
