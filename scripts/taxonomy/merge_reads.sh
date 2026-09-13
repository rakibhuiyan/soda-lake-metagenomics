#!/bin/bash
#SBATCH --job-name=merge
#SBATCH --output=/nobackup/%u/sodalake/logs/merge_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/merge_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --array=1-28%4
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL
set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
SAMPLES=$PROJECT/prodigal_samples.txt
TRIM=$PROJECT/trimmed
OUT=$PROJECT/merged
mkdir -p "$OUT" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate fastp       # fastp lives here (adjust if it's in a different env)

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")
R1="$TRIM/${SAMPLE}_1.trimmed.fastq.gz"
R2="$TRIM/${SAMPLE}_2.trimmed.fastq.gz"

echo "Merging $SAMPLE"
[[ -f "$R1" && -f "$R2" ]] || { echo "MISSING READS"; exit 1; }

fastp -i "$R1" -I "$R2" \
  --merge \
  --merged_out "$OUT/${SAMPLE}_merged.fastq.gz" \
  --disable_adapter_trimming \
  --disable_quality_filtering \
  --disable_length_filtering \
  -w "$SLURM_CPUS_PER_TASK" \
  -j "$OUT/${SAMPLE}_merge.json" -h "$OUT/${SAMPLE}_merge.html"

echo "Done $SAMPLE"
