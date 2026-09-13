#!/bin/bash
#SBATCH --job-name=dbcan
#SBATCH --output=/nobackup/%u/sodalake/logs/dbcan_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/dbcan_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=24:00:00
#SBATCH --array=1-28%2
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
SAMPLES=$PROJECT/dbcan_samples.txt
PROTEINS=$PROJECT/prodigal/proteins
DB=$PROJECT/dbcan_db
OUTDIR=$PROJECT/dbcan_results

mkdir -p "$OUTDIR" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate dbcan

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

FAA="$PROTEINS/${SAMPLE}.faa"
OUT="$OUTDIR/$SAMPLE"

echo "Running dbCAN for sample: $SAMPLE"
echo "Input protein file: $FAA"
echo "Output folder: $OUT"
echo "Started at: $(date)"

if [ ! -s "$FAA" ]; then
  echo "ERROR: missing protein file: $FAA"
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

run_dbcan CAZyme_annotation \
  --mode protein \
  --input_raw_data "$FAA" \
  --output_dir "$OUT" \
  --db_dir "$DB" \
  --methods diamond,hmm,dbCANsub \
  --threads "$SLURM_CPUS_PER_TASK" \
  --large

echo "Finished dbCAN for sample: $SAMPLE"
echo "Finished at: $(date)"
