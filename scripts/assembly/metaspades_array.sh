#!/bin/bash
#SBATCH --job-name=metaspades
#SBATCH --output=/nobackup/%u/sodalake/logs/metaspades_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/metaspades_%A_%a.err
#SBATCH --cpus-per-task=24
#SBATCH --mem=60G
#SBATCH --time=48:00:00
#SBATCH --array=1-28%4

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
ASSEMBLY=$PROJECT/assemblies
SAMPLES=$PROJECT/samples_paired.txt

mkdir -p "$ASSEMBLY" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

echo "Running metaSPAdes for sample: $SAMPLE"
echo "Started at: $(date)"

metaspades.py \
  -1 "$TRIMMED/${SAMPLE}_1.trim.fastq.gz" \
  -2 "$TRIMMED/${SAMPLE}_2.trim.fastq.gz" \
  -o "$ASSEMBLY/$SAMPLE" \
  -t "$SLURM_CPUS_PER_TASK" \
  -m 60

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
