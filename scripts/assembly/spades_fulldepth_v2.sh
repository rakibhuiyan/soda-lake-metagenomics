#!/bin/bash
#SBATCH --job-name=spades_fd2
#SBATCH --partition=bigmem
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --time=2-00:00:00
#SBATCH --array=1-13
#SBATCH --output=/nobackup/$USER/sodalake/
#SBATCH --error=/nobackup/$USER/sodalake/

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

# activate conda properly on the compute node (fixes exit 127)
export PATH=/home/$USER/miniconda3/bin:$PATH
source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades
which metaspades.py || { echo "metaspades STILL not found"; exit 127; }

# fresh output dir so no half-written state blocks the rerun
rm -rf "$OUT/$SAMPLE"
TMP=/nobackup/$USER/sodalake/spades_tmp/${SAMPLE}
rm -rf "$TMP"; mkdir -p "$TMP"

metaspades.py \
    -1 "$R1" -2 "$R2" \
    -o "$OUT/$SAMPLE" \
    -t "$SLURM_CPUS_PER_TASK" \
    -m 250 \
    --only-assembler \
    --tmp-dir "$TMP"

rm -rf "$TMP"
echo "=== DONE $SAMPLE ==="
