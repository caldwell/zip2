#!/bin/bash
rm -r "fuzz/corpus/fuzz_$1_old"
MAX_ITERS_WITHOUT_IMPROVEMENT=3
iters_without_improvement=0
while [[ $iters_without_improvement -lt $MAX_ITERS_WITHOUT_IMPROVEMENT ]]; do
  cp -r "fuzz/corpus/fuzz_$1" "fuzz/corpus/fuzz_$1_old"
  cargo fuzz run --all-features "fuzz_$1" "fuzz/corpus/fuzz_$1" -- \
    -dict=fuzz/fuzz.dict -max_len="$2" -rss_limit_mb=8192 \
    -fork="$(nproc || getconf NPROCESSORS_ONLN)" -runs=15000000 \
    -max_total_time=900
  ./recursive-fuzz-cmin.sh "$1" "$2"
  if diff "fuzz/corpus/fuzz_$1" "fuzz/corpus/fuzz_$1_old"; then
    iters_without_improvement=$(( iters_without_improvement + 1 ))
    echo "$iters_without_improvement iterations without improvement"
  else
    iters_without_improvement=0
  fi
  rm -r "fuzz/corpus/fuzz_$1_old"
done
