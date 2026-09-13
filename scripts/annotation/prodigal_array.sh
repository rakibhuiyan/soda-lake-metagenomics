#!/bin/bash
#SBATCH --job-name=prodigal
#SBATCH --output=/nobackup/%u/sodalake/logs/prodigal_%A_%a.out
#SBATCH --error=/nobackup/%u/sodalake/logs/prodigal_%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=06:00:00
#SBATCH --array=1-28%4
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --mail-type=END,FAIL

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
SAMPLES=$PROJECT/prodigal_samples.txt
CONTIGS=$PROJECT/contigs_ge1000
OUTDIR=$PROJECT/prodigal

mkdir -p "$OUTDIR/proteins" "$OUTDIR/gff" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate spades

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

IN="$CONTIGS/${SAMPLE}.contigs_ge1000.fasta"
FAA="$OUTDIR/proteins/${SAMPLE}.faa"
GFF="$OUTDIR/gff/${SAMPLE}.gff"

echo "Running Prodigal for sample: $SAMPLE"
echo "Input: $IN"
echo "Protein output: $FAA"
echo "GFF output: $GFF"
echo "Started at: $(date)"

if [ ! -s "$IN" ]; then
  echo "ERROR: input file missing or empty: $IN"
  exit 1
fi

prodigal \
  -i "$IN" \
  -a "$FAA" \
  -o "$GFF" \
  -f gff \
  -p meta \
  -q

echo "Finished Prodigal for sample: $SAMPLE"
echo "Finished at: $(date)"
