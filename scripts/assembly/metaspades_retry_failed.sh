#!/bin/bash
#SBATCH --job-name=metaspades_retry
#SBATCH --output=/nobackup/%u/sodalake/logs/metaspades_retry_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/metaspades_retry_%A_%a.err
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=72:00:00
#SBATCH --array=1-17%1
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
ASSEMBLY=$PROJECT/assemblies_retry
SAMPLES=$PROJECT/failed_metaspades_samples.txt

mkdir -p "$ASSEMBLY" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

echo "Retrying metaSPAdes for sample: $SAMPLE"
echo "Started at: $(date)"
echo "R1: $TRIMMED/${SAMPLE}_1.trim.fastq.gz"
echo "R2: $TRIMMED/${SAMPLE}_2.trim.fastq.gz"

metaspades.py \
  -1 "$TRIMMED/${SAMPLE}_1.trim.fastq.gz" \
  -2 "$TRIMMED/${SAMPLE}_2.trim.fastq.gz" \
  -o "$ASSEMBLY/$SAMPLE" \
  -t "$SLURM_CPUS_PER_TASK" \
  -m 110 \
  --phred-offset 33

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
