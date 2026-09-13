#!/bin/bash
#SBATCH --job-name=spades_fd
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --time=1-00:00:00
#SBATCH --array=1-13
#SBATCH --output=/nobackup/$USER/sodalake/logs/fd_%A_%a.out
#SBATCH --error=/nobackup/$USER/sodalake/logs/fd_%A_%a.err

set -euo pipefail

TRIM=/nobackup/$USER/sodalake/trimmed
OUT=/nobackup/$USER/sodalake/assemblies_fulldepth
LIST=/nobackup/$USER/sodalake/redo_samples.txt
mkdir -p "$OUT" /nobackup/$USER/sodalake/logs

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$LIST")
R1="$TRIM/${SAMPLE}_1.trimmed.fastq.gz"
R2="$TRIM/${SAMPLE}_2.trimmed.fastq.gz"

echo "=== $SAMPLE on $(hostname) ==="
[[ -f "$R1" && -f "$R2" ]] || { echo "MISSING READS: $R1 / $R2"; exit 1; }

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades
which metaspades.py || { echo "metaspades not on PATH"; exit 127; }

TMP=/nobackup/$USER/sodalake/spades_tmp/${SAMPLE}
mkdir -p "$TMP"

metaspades.py \
    -1 "$R1" -2 "$R2" \
    -o "$OUT/$SAMPLE" \
    -t "$SLURM_CPUS_PER_TASK" \
    -m 120 \
    --tmp-dir "$TMP"

rm -rf "$TMP"
echo "=== DONE $SAMPLE ==="
