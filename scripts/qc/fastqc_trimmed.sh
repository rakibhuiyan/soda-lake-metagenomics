#!/bin/bash
#SBATCH --job-name=fastqc_trimmed
#SBATCH --output=/nobackup/%u/sodalake/logs/fastqc_trimmed_%j.out
#SBATCH --error=/nobackup/%u/sodalake/logs/fastqc_trimmed_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=06:00:00

set -eo pipefail

PROJECT=/nobackup/$USER/sodalake
TRIMMED=$PROJECT/trimmed
OUT=$PROJECT/fastqc_trimmed

mkdir -p "$OUT" "$PROJECT/logs"

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate fastp

fastqc -t 8 "$TRIMMED"/*.trim.fastq.gz -o "$OUT"
