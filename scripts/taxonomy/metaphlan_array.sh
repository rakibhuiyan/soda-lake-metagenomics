#!/bin/bash
#SBATCH --job-name=metaphlan
#SBATCH --output=/nobackup/%u/sodalake/logs/mpa_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/mpa_%A_%a.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --array=1-28%4
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL
set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
SAMPLES=$PROJECT/prodigal_samples.txt
TRIM=$PROJECT/trimmed
OUTDIR=$PROJECT/metaphlan
DB=$PROJECT/metaphlan_db
mkdir -p "$OUTDIR/profiles" "$OUTDIR/bowtie2" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate metaphlan

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")
R1="$TRIM/${SAMPLE}_1.trimmed.fastq.gz"
R2="$TRIM/${SAMPLE}_2.trimmed.fastq.gz"

echo "MetaPhlAn for $SAMPLE"
[[ -f "$R1" && -f "$R2" ]] || { echo "MISSING READS: $R1 / $R2"; exit 1; }

metaphlan "$R1,$R2" \
  --input_type fastq \
  --nproc "$SLURM_CPUS_PER_TASK" \
  --db_dir "$DB" \
  --index mpa_vJan26_CHOCOPhlAnSGB_202605 \
  --mapout "$OUTDIR/bowtie2/${SAMPLE}.bowtie2.bz2" \
  -o "$OUTDIR/profiles/${SAMPLE}_profile.txt"

echo "Done $SAMPLE"
