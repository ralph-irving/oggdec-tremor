#!/bin/sh

OGG=1.3.3
TREMOR=r19648
VORBIS=1.3.6
TOOLS=1.4.0
LOG=$PWD/config.log
#CHANGENO=` svn info .  | grep -i Revision | awk -F": " '{print $2}'`
CHANGENO=$(git rev-parse --short HEAD)
ARCH=`arch`
OUTPUT=$PWD/oggdec-build-$ARCH-$CHANGENO
export CFLAGS="-fno-exceptions -Wall -fsigned-char -O4 -fomit-frame-pointer -funroll-all-loops -finline-functions -ffast-math -march=armv6j -mtune=arm1136jf-s -s"

# Clean up
rm -rf $OUTPUT
rm -rf libogg-$OGG
rm -rf libvorbis-$VORBIS
rm -rf tremor-$TREMOR
rm -rf vorbis-tools-$TOOLS

## Start
echo "Most log mesages sent to $LOG... only 'errors' displayed here"
date > $LOG

## Build Ogg first
echo "Untarring libogg-$OGG.tar.gz..."
tar -zxf libogg-$OGG-bc82844df068429d209e909da47b1f730b53b689.tar.gz 
cd libogg-$OGG
sed -i "s:-O2 ::g" configure
sed -i "s:-O20::g" configure
echo "Configuring..."
./configure --disable-shared >> $LOG
echo "Running make..."
make >> $LOG
cd ..

## Build Tremor
echo "Untarring tremor-$TREMOR.tar.gz..."
tar -zxf tremor-$TREMOR.tar.gz
cd tremor-$TREMOR
autoreconf -if
sed -i "s:-O2 ::g" configure
sed -i "s:-O20::g" configure
echo "Configuring..."
./configure --with-ogg-includes=$PWD/../libogg-$OGG/include --with-ogg-libraries=$PWD/../libogg-$OGG/src/.libs --enable-shared=no --disable-oggtest >> $LOG
echo "Running make"
make >> $LOG
cd ..

## Build Vorbis
echo "Untarring libvorbis-$VORBIS.tar.gz..."
tar -zxf libvorbis-$VORBIS.tar.gz
cd libvorbis-$VORBIS
sed -i "s:-O2 ::g" configure
sed -i "s:-O20::g" configure
echo "Configuring..."
./configure --with-ogg-includes=$PWD/../libogg-$OGG/include --with-ogg-libraries=$PWD/../libogg-$OGG/src/.libs --disable-shared >> $LOG
echo "Running make"
make >> $LOG
cd ..

## Build vorbis-tools
echo "Untarring vorbis-tools-$TOOLS.tar.gz..."
tar -zxf vorbis-tools-$TOOLS.tar.gz >> $LOG
cd vorbis-tools-$TOOLS >> $LOG
sed -i "s:-O2 ::g" configure
sed -i "s:-O20::g" configure
echo "Configuring..."
CPF="-I$PWD/../libogg-$OGG/include -I$PWD/../libvorbis-$VORBIS/include"
LDF="-L$PWD/../libogg-$OGG/src/.libs -L$PWD/../libvorbis-$VORBIS/lib/.libs"

./configure CFLAGS="$CPF" LDFLAGS="$LDF" --prefix $OUTPUT >> $LOG

echo "Building Tremor oggdec"
cd oggdec
cp -p ../../oggdec-134b784a4d2f03e3fb5a389edc1adb84029b3cd3.c oggdec.c
patch -p0 -i ../../oggdec.c.patch
echo "gcc -D_GNU_SOURCE $CFLAGS -I$PWD/../../tremor-$TREMOR -I$PWD/../../libogg-$OGG/include -o oggdec oggdec.c $PWD/../../tremor-$TREMOR/.libs/libvorbisidec.a $PWD/../../libogg-$OGG/src/.libs/libogg.a" >> $LOG
gcc -D_GNU_SOURCE $CFLAGS -I$PWD/../../tremor-$TREMOR -I$PWD/../../libogg-$OGG/include -o oggdec oggdec.c $PWD/../../tremor-$TREMOR/.libs/libvorbisidec.a $PWD/../../libogg-$OGG/src/.libs/libogg.a >> $LOG
cd ..

mkdir $OUTPUT
cp -p oggdec/oggdec $OUTPUT

## Tar the whole package up
tar -zcvf $OUTPUT.tgz $OUTPUT

rm -rf $OUTPUT

cd ..
rm -rf libogg-$OGG
rm -rf libvorbis-$VORBIS
rm -rf tremor-$TREMOR
rm -rf vorbis-tools-$TOOLS
