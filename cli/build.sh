#!/bin/bash

# cli file naem
OUTPUT_FILENAME="cachetmonitor"

PLATFORMS="darwin/amd64"
# disable windows build
# PLATFORMS="$PLATFORMS windows/amd64 windows/386"
PLATFORMS="$PLATFORMS linux/amd64 linux/386"
PLATFORMS_ARM="linux"

type setopt >/dev/null 2>&1

SCRIPT_NAME=`basename "$0"`
FAILURES=""
SOURCE_FILE=`echo $@ | sed 's/\.go//'`
CURRENT_DIRECTORY=${PWD##*/}
OUTPUT=build/${SOURCE_FILE:-$OUTPUT_FILENAME} # if no src file given, use current dir name
FLAGS="-ldflags \"-X main.Version=${VERSION}\" -mod=vendor"

for PLATFORM in $PLATFORMS; do
  GOOS=${PLATFORM%/*}
  GOARCH=${PLATFORM#*/}
  BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}"
  if [[ "${GOOS}" == "windows" ]]; then BIN_FILENAME="${BIN_FILENAME}.exe"; fi
  CMD="GOOS=${GOOS} GOARCH=${GOARCH} go build ${FLAGS} -o ${BIN_FILENAME} $@"
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
  zip -j "${BIN_FILENAME}.zip" ${BIN_FILENAME}
  rm ${BIN_FILENAME}
done

# ARM builds
if [[ $PLATFORMS_ARM == *"linux"* ]]; then 
  BIN_FILENAME="${OUTPUT}-linux-arm64"
  CMD="GOOS=linux GOARCH=arm64 go build ${FLAGS} -o ${BIN_FILENAME} $@"
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
  zip -j "${BIN_FILENAME}.zip" ${BIN_FILENAME}
  rm ${BIN_FILENAME}
fi

for GOOS in $PLATFORMS_ARM; do
  GOARCH="arm"
  # build for each ARM version
  for GOARM in 7 6 5; do
    BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}${GOARM}"
    CMD="GOARM=${GOARM} GOOS=${GOOS} GOARCH=${GOARCH} go build ${FLAGS} -o ${BIN_FILENAME} $@"
    echo "${CMD}"
    eval "${CMD}" || FAILURES="${FAILURES} ${GOOS}/${GOARCH}${GOARM}"
    zip -j "${BIN_FILENAME}.zip" ${BIN_FILENAME}
    rm ${BIN_FILENAME}
  done
done

# eval errors
if [[ "${FAILURES}" != "" ]]; then
  echo ""
  echo "${SCRIPT_NAME} failed on: ${FAILURES}"
  exit 1
fi