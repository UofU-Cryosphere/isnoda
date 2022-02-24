#!/usr/bin/env bash

for ISNODA_PATH in "/path/to/TauDEM/binaries"; do
  export PATH="${PATH//\:$ISNODA_PATH}"
done
