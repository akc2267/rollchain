#!/usr/bin/env bash

set -e

echo "Generating gogo proto code"
cd proto
proto_dirs=$(find . -path -prune -o -name '*.proto' -print0 | xargs -0 -n1 dirname | sort | uniq)
for dir in $proto_dirs; do
  for file in $(find "${dir}" -maxdepth 1 -name '*.proto'); do
    # this regex checks if a proto file has its go_package set to github.com/strangelove-ventures/poa/...
    # gogo proto files SHOULD ONLY be generated if this is false
    # we don't want gogo proto to run for proto files which are natively built for google.golang.org/protobuf
    if grep -q "option go_package" "$file" && grep -H -o -c 'option go_package.*github.com/rollchains/rollchain/api' "$file" | grep -q ':0$'; then
      buf generate --template buf.gen.gogo.yaml $file
    fi
  done
done

echo "Generating pulsar proto code"
buf generate --template buf.gen.pulsar.yaml

cd ..

mv github.com/rollchains/rollchain/* ./
rm -rf github.com

# Copy files over for dep injection
rm -rf api && mkdir api
custom_modules=$(find . -name 'module' -type d -not -path "./proto/*")
for module in $custom_modules; do
  dirPath=`basename $(dirname $module)`
  mkdir -p api/$dirPath

  mv $dirPath/* ./api/$dirPath/
  rm -rf $dirPath
done

