#!/usr/bin/env bash

for repository in $(find . -maxdepth 1 ! -path . -type d); do
  pushd ${repository}
  if [ -f .git/config ]; then
    git pull
  fi
  popd
done
