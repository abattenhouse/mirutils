#!/bin/bash

RELVER=$1

TMP_VDIR="mirUtils-$RELVER";
if [   -d "$TMP_VDIR" ]; then rm -rf "$TMP_VDIR"; fi
if [ ! -d "$TMP_VDIR" ]; then mkdir "$TMP_VDIR"; fi

cp  -p ../COPYING  $TMP_VDIR/
cp  -p ../README   $TMP_VDIR/
cp  -p ../mirUtils $TMP_VDIR/
cp -rp ../lib      $TMP_VDIR/lib
cp -rp ../mirbase  $TMP_VDIR/mirbase

tar -cf "$TMP_VDIR.tar" $TMP_VDIR
gzip "$TMP_VDIR.tar"

rm -rf "$TMP_VDIR"
