#!/bin/bash

RELVER=$1

err() {
  echo "** ERROR: $1...exiting";
  if [ "$no_exit" == "" ]; then exit 1; fi
}

echo "---------------------------------------------";
echo "makeRelease '$RELVER' - `date`";
if [ "$RELVER" == "" ]; then err "No release version provided"; fi

echo "..Checking mirUtils version for string '$RELVER'...";
CMD="grep -P '$RELVER' ../mirUtils";
STR="`$CMD`";
if [ "$STR" == "" ]; then err "Release version '$RELVER' not found in ../mirUtils"; fi

TMP_VDIR="mirUtils-$RELVER";
echo "..Preparing release directory '$TMP_VDIR'...";
if [   -d "$TMP_VDIR" ]; then rm -rf "$TMP_VDIR"; fi
if [ ! -d "$TMP_VDIR" ]; then mkdir -p "$TMP_VDIR/test/data"; fi

cp  -p ../COPYING           $TMP_VDIR/
cp  -p ../README            $TMP_VDIR/
cp  -p ../test/data/*small* $TMP_VDIR/test/data
cp  -p ../mirUtils          $TMP_VDIR/
cp -rp ../lib               $TMP_VDIR/lib
cp -rp ../mirbase           $TMP_VDIR/mirbase
cp -rp ../htdocs            $TMP_VDIR/htdocs

echo "..Preparing $TMP_VDIR.tar.gz...";
tar -cf "$TMP_VDIR.tar" $TMP_VDIR
gzip "$TMP_VDIR.tar"
mv "$TMP_VDIR.tar.gz" versions/

rm -rf "$TMP_VDIR"

echo "..Done! - `date`";
