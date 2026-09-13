#!/bin/bash
#SBATCH --job-name=fastp_trim
#SBATCH --output=/nobackup/%u/sodalake/logs/fastp_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/fastp_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --array=1-28%4

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
RAW=$PROJECT/raw_data
TRIMMED=$PROJECT/trimmed
REPORTS=$TRIMMED/reports
SAMPLES=$PROJECT/samples_paired.txt

mkdir -p "$TRIMMED" "$REPORTS" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate fastp

set -u

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

echo "Running fastp for sample: $SAMPLE"
echo "Started at: $(date)"
echo "R1: $RAW/${SAMPLE}_1.fastq.gz"
echo "R2: $RAW/${SAMPLE}_2.fastq.gz"

fastp \
  -i "$RAW/${SAMPLE}_1.fastq.gz" \
  -I "$RAW/${SAMPLE}_2.fastq.gz" \
  -o "$TRIMMED/${SAMPLE}_1.trim.fastq.gz" \
  -O "$TRIMMED/${SAMPLE}_2.trim.fastq.gz" \
  --detect_adapter_for_pe \
  --cut_right \
  --cut_right_window_size 4 \
  --cut_right_mean_quality 20 \
  --qualified_quality_phred 20 \
  --length_required 50 \
  --trim_poly_g \
  --thread "$SLURM_CPUS_PER_TASK" \
  --html "$REPORTS/${SAMPLE}.fastp.html" \
  --json "$REPORTS/${SAMPLE}.fastp.json"

echo "Finished sample: $SAMPLE"
echo "Finished at: $(date)"
