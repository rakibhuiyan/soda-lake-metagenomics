#!/bin/bash
#SBATCH --job-name=meta_ds5M
#SBATCH --output=/nobackup/%u/sodalake/logs/meta_ds5M_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/meta_ds5M_%A_%a.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --time=72:00:00
#SBATCH --array=1-13%1
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
SAMPLES=$PROJECT/remaining_assembly_samples.txt
ASSEMBLY=$PROJECT/assemblies_downsampled_5M
LOGS=$PROJECT/logs

mkdir -p "$ASSEMBLY" "$LOGS"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

if [ -z "$SAMPLE" ]; then
  echo "No sample found for task ID $SLURM_ARRAY_TASK_ID"
  exit 1
fi

N=5000000

R1_IN="$TRIMMED/${SAMPLE}_1.trim.fastq.gz"
R2_IN="$TRIMMED/${SAMPLE}_2.trim.fastq.gz"

TMPBASE="${TMPDIR:-/tmp/$USER}/sodalake_ds_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMPBASE"

trap 'rm -rf "$TMPBASE"' EXIT

R1_DS="$TMPBASE/${SAMPLE}_1.ds5M.fastq.gz"
R2_DS="$TMPBASE/${SAMPLE}_2.ds5M.fastq.gz"

OUT="$ASSEMBLY/$SAMPLE"

echo "Sample: $SAMPLE"
echo "Started at: $(date)"
echo "Temporary folder: $TMPBASE"
echo "Input R1: $R1_IN"
echo "Input R2: $R2_IN"

if [ -s "$OUT/contigs.fasta" ]; then
  echo "Assembly already exists for $SAMPLE, skipping."
  exit 0
fi

echo "Checking disk space..."
df -h "$TMPBASE" "$PROJECT"

echo "Downsampling $SAMPLE to 5 million read pairs..."

seqtk sample -s100 "$R1_IN" "$N" | gzip -c > "$R1_DS"
seqtk sample -s100 "$R2_IN" "$N" | gzip -c > "$R2_DS"

echo "Downsampled files:"
ls -lh "$R1_DS" "$R2_DS"

echo "Removing old output folder if present..."
rm -rf "$OUT"

echo "Running metaSPAdes only-assembler on downsampled reads..."

metaspades.py \
  --only-assembler \
  -1 "$R1_DS" \
  -2 "$R2_DS" \
  -o "$OUT" \
  -t "$SLURM_CPUS_PER_TASK" \
  -m 72 \
  --phred-offset 33

if [ -s "$OUT/contigs.fasta" ]; then
  echo "Assembly completed for $SAMPLE"
  echo "Cleaning large intermediate SPAdes folders..."
  rm -rf "$OUT/tmp" "$OUT/K21" "$OUT/K33" "$OUT/K55"
else
  echo "ERROR: contigs.fasta was not created for $SAMPLE"
  exit 1
fi

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
