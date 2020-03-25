#!/usr/bin/env bash

for repository in $(find . -maxdepth 1 ! -path . -type d); do
  pushd ${repository}
  git pull
  popd
done
