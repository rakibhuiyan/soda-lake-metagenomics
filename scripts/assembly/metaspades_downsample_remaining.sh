#!/bin/bash
#SBATCH --job-name=meta_ds10M
#SBATCH --output=/nobackup/%u/sodalake/logs/meta_ds10M_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/meta_ds10M_%A_%a.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --time=72:00:00
#SBATCH --array=1-13%2
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
SAMPLES=$PROJECT/remaining_assembly_samples.txt
DOWNSAMPLED=$PROJECT/downsampled_10M
ASSEMBLY=$PROJECT/assemblies_downsampled_10M
LOGS=$PROJECT/logs

mkdir -p "$DOWNSAMPLED" "$ASSEMBLY" "$LOGS"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

if [ -z "$SAMPLE" ]; then
  echo "No sample found for task ID $SLURM_ARRAY_TASK_ID"
  exit 1
fi

N=10000000

R1_IN="$TRIMMED/${SAMPLE}_1.trim.fastq.gz"
R2_IN="$TRIMMED/${SAMPLE}_2.trim.fastq.gz"

R1_DS="$DOWNSAMPLED/${SAMPLE}_1.ds10M.fastq.gz"
R2_DS="$DOWNSAMPLED/${SAMPLE}_2.ds10M.fastq.gz"

OUT="$ASSEMBLY/$SAMPLE"

echo "Sample: $SAMPLE"
echo "Started at: $(date)"
echo "Input R1: $R1_IN"
echo "Input R2: $R2_IN"

if [ ! -s "$R1_DS" ] || [ ! -s "$R2_DS" ]; then
  echo "Downsampling $SAMPLE to 10 million read pairs..."

  seqtk sample -s100 "$R1_IN" "$N" | gzip -c > "$R1_DS.tmp"
  seqtk sample -s100 "$R2_IN" "$N" | gzip -c > "$R2_DS.tmp"

  mv "$R1_DS.tmp" "$R1_DS"
  mv "$R2_DS.tmp" "$R2_DS"

  echo "Downsampling finished for $SAMPLE"
else
  echo "Downsampled files already exist for $SAMPLE, skipping downsampling."
fi

echo "Removing old failed output folder if present..."
rm -rf "$OUT"

echo "Running metaSPAdes on downsampled reads..."

metaspades.py \
  -1 "$R1_DS" \
  -2 "$R2_DS" \
  -o "$OUT" \
  -t "$SLURM_CPUS_PER_TASK" \
  -m 72 \
  --phred-offset 33

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
