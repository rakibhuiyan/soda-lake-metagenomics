#!/bin/bash
#SBATCH --job-name=metaspades_retry2
#SBATCH --output=/nobackup/%u/sodalake/logs/metaspades_retry2_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/metaspades_retry2_%A_%a.err
#SBATCH --cpus-per-task=12
#SBATCH --mem=120G
#SBATCH --time=72:00:00
#SBATCH --array=1-13%1
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
ASSEMBLY=$PROJECT/assemblies_retry2
SAMPLES=$PROJECT/remaining_assembly_samples.txt

mkdir -p "$ASSEMBLY" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

echo "Running retry2 metaSPAdes only-assembler for sample: $SAMPLE"
echo "Started at: $(date)"

metaspades.py \
  --only-assembler \
  -1 "$TRIMMED/${SAMPLE}_1.trim.fastq.gz" \
  -2 "$TRIMMED/${SAMPLE}_2.trim.fastq.gz" \
  -o "$ASSEMBLY/$SAMPLE" \
  -t "$SLURM_CPUS_PER_TASK" \
  -m 110 \
  --phred-offset 33

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
