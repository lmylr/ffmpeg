#!/bin/bash
NDK=${ANDROID_NDK}
ANDROID_VER=21
X264=$(pwd)/x264/product

function guess_arch(){
  local arch=$1
  if [ "$arch" = "armv7a" ]; then
    arch=arm
  elif [ "$arch" = "arm64" ]; then
    arch=arm64
  elif [ "$arch" = "x86" ]; then
    arch=x86
  else
    echo "Need a arch param"
    exit 1
  fi
  echo $arch
  return $?
}

    # --disable-muxers \
    # --disable-demuxers \
    # --disable-parsers \
build(){
  ARCH=$1
  TOOLCHAIN=
  EXTRA_FF_FLAGS=
  EXTRA_CFLAGS=
  EXTRA_LDFLAGS=
  PREFIX=
  LIB_X264_STATIC=
  LIB_GCC=

  OS=linux-x86_64
  if [ ` uname -s ` = "Darwin" ]; then
    OS=darwin-x86_64
  fi

  ANDROID_TOOLCHAIN=$(../make_toolchain.sh $ANDROID_VER $arch $NDK)
  PLATFORM=${ANDROID_TOOLCHAIN}/sysroot
  echo "USE ${ANDROID_TOOLCHAIN}"
  if [ "$ARCH" = "arm" ]; then
    echo "------BUILD armv7a--------"
    PREFIX=$(pwd)/product/armeabi-v7a
    TOOLCHAIN=${ANDROID_TOOLCHAIN}/bin/arm-linux-androideabi-

  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --arch=arm --cpu=cortex-a8"
  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --enable-neon"
  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --enable-thumb  --enable-asm"
    EXTRA_CFLAGS="$EXTRA_CFLAGS -O3 -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb -std=c99 -ffast-math"
  	EXTRA_CFLAGS="$EXTRA_CFLAGS -I${X264}/armeabi-v7a/include"
  	EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,--fix-cortex-a8 -pie -fPIC"
  	EXTRA_LDFLAGS="$EXTRA_LDFLAGS -L${X264}/armeabi-v7a/lib"

    LIB_X264_STATIC=$X264/armeabi-v7a/lib/libx264.a
    #TODO version 4.9.x
    LIB_GCC=${ANDROID_TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.9.x/libgcc.a
  elif [ "$ARCH" = "arm64" ]; then
    echo "------BUILD arm64--------"
    PREFIX=$(pwd)/product/arm64-v8a
    TOOLCHAIN=${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android-

  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --arch=aarch64 --enable-yasm"
  	EXTRA_CFLAGS="$EXTRA_CFLAGS -O3 -I${X264}/arm64-v8a/include"
  	EXTRA_LDFLAGS="$EXTRA_LDFLAGS -L${X264}/arm64-v8a/lib"

    LIB_X264_STATIC=$X264/arm64-v8a/lib/libx264.a
    #TODO version 4.9.x
    LIB_GCC=${ANDROID_TOOLCHAIN}/lib/gcc/aarch64-linux-android/4.9.x/libgcc.a
  elif [ "$ARCH" = "x86" ]; then
    echo "------BUILD x86--------"
    PREFIX=$(pwd)/product/x86
    TOOLCHAIN=${ANDROID_TOOLCHAIN}/bin/i686-linux-android-

  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --arch=x86 --cpu=i686"
  	EXTRA_FF_FLAGS="${EXTRA_FF_FLAGS} --enable-yasm"
  	EXTRA_CFLAGS="$EXTRA_CFLAGS -O3 -Wall -fpic -pipe -DANDROID -DNDEBUG -march=atom -msse3 -ffast-math -mfpmath=sse"
  	EXTRA_CFLAGS="$EXTRA_CFLAGS -I${X264}/x86/include"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -lm -lz -Wl,--no-undefined -Wl,-z,noexecstack"
  	EXTRA_LDFLAGS="$EXTRA_LDFLAGS -L${X264}/x86/lib"

    LIB_X264_STATIC=$X264/x86/lib/libx264.a
    #TODO version 4.9.x
    LIB_GCC=${ANDROID_TOOLCHAIN}/lib/gcc/i686-linux-android/4.9.x/libgcc.a
  else
    echo "Not support arch for ${1}. Input arm, arm64 or x86 pls."
    exit 1
  fi
  ./configure \
    --prefix=$PREFIX \
    --target-os=android \
    --sysroot=$PLATFORM \
    --enable-cross-compile \
    --cross-prefix=$TOOLCHAIN \
    --cc=${TOOLCHAIN}gcc \
    --nm=${TOOLCHAIN}nm \
    \
    --disable-shared \
    --enable-static \
    \
    --disable-doc \
    --enable-gpl \
    --enable-nonfree \
    --enable-logging \
    --enable-jni \
    --enable-mediacodec \
    --enable-hwaccel=h264_mediacodec \
    --enable-runtime-cpudetect \
    --enable-zlib \
    --enable-fft \
    --enable-rdft \
    \
    --enable-swscale \
    --enable-avresample \
    \
    --disable-gray \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-avdevice \
    --disable-postproc \
    --disable-network \
    --disable-programs \
    --disable-indevs \
    --disable-outdevs \
    --disable-symver  \
    --disable-w32threads \
    --disable-debug \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-iconv \
    --disable-audiotoolbox \
    --disable-videotoolbox \
    --disable-armv5te \
    --disable-armv6 \
    --disable-armv6t2 \
    --disable-d3d11va \
    --disable-dxva2 \
    --disable-vaapi \
    --disable-vdpau \
    --disable-ffmpeg \
    \
    --disable-encoders \
    --enable-libx264 \
    --enable-encoder=libx264 \
    --enable-encoder=aac \
    --enable-encoder='pcm*' \
    --enable-encoder=gif \
    --enable-encoder=bmp \
    \
    --disable-decoders \
    --enable-decoder=h264_mediacodec \
    --enable-decoder=h264 \
    --enable-decoder=aac \
    --enable-decoder='pcm*' \
    --enable-decoder=gif \
    --enable-decoder=amrnb \
    --enable-decoder=amrwb \
    --enable-decoder=bmp \
    \
    --enable-protocol=file \
    \
    --disable-muxers \
    --enable-muxer=h264 \
    --enable-muxer=mp4 \
    --enable-muxer=mov \
    --enable-muxer=mp3 \
    --enable-muxer=wav \
    --enable-muxer=hevc \
    --enable-muxer='pcm*' \
    --enable-muxer=rawvideo \
    --enable-muxer=gif \
    --enable-muxer=f4v \
    --enable-muxer=m4v \
    --enable-muxer=flv \
    --enable-muxer=image2 \
    \
    --disable-demuxers \
    --enable-demuxer=h264 \
    --enable-demuxer=mov \
    --enable-demuxer=mp3 \
    --enable-demuxer=wav \
    --enable-demuxer=hevc \
    --enable-demuxer=aac \
    --enable-demuxer='pcm*' \
    --enable-demuxer=rawvideo \
    --enable-demuxer=mpegvideo \
    --enable-demuxer=gif \
    --enable-demuxer=m4v \
    --enable-demuxer=flv \
    --enable-demuxer=image2 \
    \
    --disable-parsers \
    --enable-parser=h264 \
    --enable-parser=mpegaudio \
    --enable-parser=mpegvideo \
    --enable-parser=mpeg4video \
    --enable-parser=hevc \
    --enable-parser=aac \
    --enable-parser=aac_latm \
    --enable-parser=gif \
    --enable-parser=bmp \
    \
    --enable-bsfs \
    --disable-bsf=text2movsub \
    --disable-bsf=mjpeg2jpeg \
    --disable-bsf=mjpega_dump_header \
    --disable-bsf=mov2textsub \
    --disable-bsf=imx_dump_header \
    --disable-bsf=chomp \
    --disable-bsf=noise \
    --disable-bsf=dump_extradata \
    --disable-bsf=remove_extradata \
    --disable-bsf=dca_core \
    \
    --disable-filters \
    --enable-filter=amix \
    --enable-filter=aformat \
    --enable-filter=scale \
    --enable-filter=format \
    --enable-filter=aformat \
    --enable-filter=fps \
    --enable-filter=trim \
    --enable-filter=atrim \
    --enable-filter=vflip \
    --enable-filter=hflip \
    --enable-filter=transpose \
    --enable-filter=rotate \
    --enable-filter=yadif \
    --enable-filter=pan \
    --enable-filter=volume \
    --enable-filter=aresample \
    --enable-filter=atempo \
    --enable-filter=asetrate \
    --enable-filter=setpts \
    --enable-filter=overlay \
    --enable-filter=paletteuse \
    --enable-filter=areverse \
    --enable-filter=anull \
    --enable-filter=palettegen \
    --enable-filter=showwavespic \
    --enable-filter=null \
    \
    --disable-devices \
    \
    --enable-pic \
    --enable-asm \
    --enable-yasm \
    --enable-inline-asm \
    --enable-optimizations \
    --enable-small \
    \
    --extra-cflags="$EXTRA_CFLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    $EXTRA_FF_FLAGS

  make clean
  make -j4
  make install

  ${TOOLCHAIN}ld \
    --sysroot=$PLATFORM \
    --allow-shlib-undefined \
    -rpath-link=$PLATFORM/usr/lib \
    -L$PLATFORM/usr/lib \
    -L$PREFIX/lib \
    -soname libhwffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -O3 \
    -o $PREFIX/libhwffmpeg.so \
    $PREFIX/lib/libavcodec.a \
    $PREFIX/lib/libavformat.a \
    $PREFIX/lib/libavresample.a \
    $PREFIX/lib/libavutil.a \
    $PREFIX/lib/libswresample.a \
    $PREFIX/lib/libavfilter.a \
    $PREFIX/lib/libswscale.a \
    $LIB_X264_STATIC \
    -lc -lm -lz -ldl -llog \
    ${LIB_GCC}
    #--no-undefined \

  cp config.h ${PREFIX}/include
}

arch=$1
cd ffmpeg
build $arch
