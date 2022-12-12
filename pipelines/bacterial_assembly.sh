#!/bin/bash
TAG=$RANDOM
echo 'running from docker image'
echo "$1"
echo "$TAG"

# ORANGE
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
FIN=${OUTPUT}/ASSEMBLY-${TAG}
mkdir -p ${FIN}
touch ${FIN}/reference.txt
echo ${IMAGE} >>${FIN}/reference.txt
echo ${DATE} >>${FIN}/reference.txt
echo ${TAG} >>${FIN}/reference.txt
echo $1 >>${FIN}/reference.txt
echo '---' >>${FIN}/reference.txt

for A in ${INPUT}/*_R1*; do
    B=${A%%1.*}"2.*"
    filename="$(basename ${A})"
    name="$(cut -d'.' -f1 <<<${filename})"
    base="$(head -c -4 <<<${name})"

    #   Assigning work files
    OUT=${FIN}/${base}
    mkdir -p ${OUT}

    #   Activating environment
    conda deactivate
    conda activate assemble

    #   Copying files over
    cp ${A} ${OUT}/read_1.fastq.gz
    cp ${B} ${OUT}/read_2.fastq.gz

    #   Trimming with bbduk
    if ! bbduk.sh -Xmx4096m tpe tbo \
        in1=${OUT}/read_1.fastq.gz \
        in2=${OUT}/read_2.fastq.gz \
        out=${OUT}/paired.fastq \
        ftl=10 \
        ftr=139 \
        qhdist=1 \
        qtrim=10 \
        minlength=100; then
        rm -rf ${OUT}/*
        echo "Failed to trim ${base}" >>${OUT}/error.txt
        continue
    fi

    if [ $1 == "clean" ]; then
        rm ${OUT}/read_1.fastq.gz
        rm ${OUT}/read_2.fastq.gz
    fi

    #   Remove duplications
    if ! dedupe.sh -Xmx4096m ac=f s=5 e=2 \
        in=${OUT}/paired.fastq \
        out=${OUT}/deduped.fastq; then
        clumpify.sh -Xmx4096m \
            in=${OUT}/paired.fastq \
            out=${OUT}/deduped.fastq \
            dedupe=t
        rm -rf ${OUT}/.zip
    fi

    if [ $1 == "clean" ]; then
        rm ${OUT}/paired.fastq
    fi

    #   Merge sequences
    if ! bbmerge.sh -Xmx4096m -ea mininsert=125 minoverlap=20 \
        in=${OUT}/deduped.fastq \
        out=${OUT}/merged.fastq \
        outu=${OUT}/unmerged.fastq; then
        rm -rf ${OUT}/*
        echo "Failed to merge reads for ${base}" >>${OUT}/error.txt
        continue
    fi

    if [ $1 == "clean" ]; then
        rm ${OUT}/deduped.fastq
    fi

    # Normalisation
    if ! bbnorm.sh -Xmx4096m min=5 target=100 \
        in=${OUT}/merged.fastq \
        out=${OUT}/normalised.fastq; then
        rm -rf ${OUT}/*
        echo "Failed to normalise reads for ${base}" >>${OUT}/error.txt
        continue
    fi

    if [ $1 == "clean" ]; then
        rm ${OUT}/merged.fastq
    fi

    #   SPAdes assembly
    if ! spades.py \
        -t 12 -m 5 --only-assembler --careful \
        -k 55,77,99,127 \
        -o ${OUT}/SPAdes/ \
        --merged ${OUT}/normalised.fastq \
        -s ${OUT}/unmerged.fastq; then
        rm -rf ${OUT}/*
        echo "Failed to assemble ${base}" >>${OUT}/error.txt
        continue
    fi

    if [ $1 == "clean" ]; then
        mkdir ${OUT}/spades
        cp ${OUT}/SPAdes/contigs.fasta ${OUT}/spades
        cp ${OUT}/SPAdes/params.txt ${OUT}/spades
        cp ${OUT}/SPAdes/assembly_graph.fastg ${OUT}/spades
        rm -r ${OUT}/SPAdes
        mv ${OUT}/spades ${OUT}/SPAdes
        rm ${OUT}/unmerged.fastq
    fi
    #Getting a reference genome
    mkdir ${OUT}/ref
    blastn -remote \
        -query ${OUT}/spades/contigs.fasta \
        -out ${OUT}/ref/refgenome -max_target_seqs 1 -outfmt 6

    awk '{print $2}' ${OUT}/ref/refgenome >${OUT}/ref/refgenome1

    sort ${OUT}/ref/refgenome1 | uniq >${OUT}/ref/refgenome2

    Ref1="$(awk NR==1 ${OUT}/ref/refgenome2)"

    echo "${Ref1}"

    echo "Downloading References"

    efetch -db nucleotide -id ${Ref1} -format fasta >${OUT}/ref/${Ref1}.fasta

    rm ${OUT}/ref/refgenome
    rm ${OUT}/ref/refgenome1
    rm ${OUT}/ref/refgenome2

    #   Contig extraction (using filter.py)
    #cat ${OUT}/SPAdes/contigs.fasta | grep ">" >${OUT}/SPAdes/prefilter-contigs.txt
    #cp ${OUT}/SPAdes/contigs.fasta ${TEMP}/
    # ${RUN}/filter.py
    #rm ${TEMP}/contigs.fasta
    #mv ${TEMP}/phage_contig.fasta ${OUT}/contig.fasta

    #  Mapping, sorting, and indexing
    bbmap.sh -Xmx4096m ref=${OUT}/contig.fasta \
        in=${OUT}/normalised.fastq \
        out=${OUT}/mapped.sam

    samtools view -bS -f4 ${OUT}/mapped.sam | samtools sort - \
        -o ${OUT}/sorted.bam

    if [ $1 == "clean" ]; then
        rm ${OUT}/mapped.sam
    fi

    samtools index ${OUT}/sorted.bam

    #  Pilon assembly check
    pilon --genome ${OUT}/contig.fasta \
        --frags ${OUT}/sorted.bam \
        --output ${OUT}/polished \
        --verbose --changes

    if [ $1 == "clean" ]; then
        rm ${OUT}/contig.fasta
    fi

    #  BBmap coverage calculation
    bbmap.sh -Xmx4096m ref=${OUT}/polished.fasta \
        in=${OUT}/normalised.fastq \
        covstats=${OUT}/covstats.txt \
        out=${OUT}/mapped2.sam

    mv ${OUT}/covstats.txt \
        ${OUT}/SPAdes/

    mkdir ${OUT}/reads
    fastqc ${OUT}/normalised.fastq -o ${OUT}/reads

    if [ $1 == "clean" ]; then
        rm ${OUT}/mapped2.sam
        rm ${OUT}/sorted.bam
        rm ${OUT}/sorted.bam.bai
        rm ${OUT}/normalised.fastq
        rm ${OUT}/polished.changes
    fi

    if [ $1 == "raw" ]; then
        mv ${OUT}/*.fastq ${OUT}/reads
    fi

    conda deactivate
    conda activate annotate

    # Running Quast
    mkdir ${OUT}/Quast
    mkdir ${OUT}/Quast/raw
    mkdir ${OUT}/Quast/polished
    quast ${OUT}/SPAdes/contigs.fasta --output-dir ${OUT}/Quast/raw
    quast ${OUT}/polished.fasta --output-dir ${OUT}/Quast/polished

    # Renaming assembly
    sed "1s/.*/>${base}/" ${OUT}/polished.fasta >${OUT}/${base}.fasta

    if [ $1 == "clean" ]; then
        rm ${OUT}/polished.fasta
    fi

done

#   Setting pass/fail
for A in ${FIN}/*; do
    file="$(basename ${A})"

    if [ -e ${A}/error.txt ]; then
        echo "$file exit with an error"
        cat ${A}/error.txt >>${FIN}/reference.txt
        continue
    else
        echo "$file complete successfully"
        echo "$file complete successfully" >>${FIN}/reference.txt
    fi
done

chmod -R 777 ./*
echo 'Finished assembly run'
