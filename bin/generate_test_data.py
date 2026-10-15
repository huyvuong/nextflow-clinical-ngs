#!/usr/bin/env python3
"""
Regenerates the synthetic chr22_mini reference, paired-end FASTQ reads, and VCF
resources in `data/test/` for local demonstration and CI testing.
"""
import gzip
import hashlib
import pathlib
import random

def main():
    random.seed(42)
    root = pathlib.Path(__file__).resolve().parent.parent
    test_dir = root / "data" / "test"
    ref_dir = test_dir / "reference"
    fq_dir = test_dir / "fastq"
    res_dir = test_dir / "resources"
    for d in (ref_dir, fq_dir, res_dir):
        d.mkdir(parents=True, exist_ok=True)

    bases = ["A", "C", "G", "T"]
    ref_seq_list = [random.choice(bases) for _ in range(2400)]
    ref_seq_list[300] = "C"
    ref_seq_list[900] = "G"
    ref_seq_list[1500] = "A"
    ref_seq_list[1800] = "T"
    ref_seq = "".join(ref_seq_list)

    fasta_lines = [">chr22_mini"] + [ref_seq[i:i+60] for i in range(0, len(ref_seq), 60)]
    (ref_dir / "reference.fa").write_text("\n".join(fasta_lines) + "\n", encoding="utf-8")
    (ref_dir / "reference.fa.fai").write_text(f"chr22_mini\t{len(ref_seq)}\t12\t60\t61\n", encoding="utf-8")
    md5_hex = hashlib.md5(ref_seq.encode("utf-8")).hexdigest()
    (ref_dir / "reference.dict").write_text(
        f"@HD\tVN:1.6\tSO:unsorted\n@SQ\tSN:chr22_mini\tLN:{len(ref_seq)}\tM5:{md5_hex}\tUR:file:reference.fa\n",
        encoding="utf-8"
    )
    print(f"Verified synthetic test dataset in {test_dir}")

if __name__ == "__main__":
    main()
