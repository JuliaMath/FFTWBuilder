using BinaryBuilder, Compat

# Collection of sources required to build ZMQ
sources = [
    "http://fftw.org/fftw-3.3.8.tar.gz" =>
    "6113262f6e92c5bd474f2875fa1b01054c4ad5040f6b0da7c03c98821d9ae303",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fftw-3.3.8
config="--prefix=$prefix --host=${target} --enable-shared --disable-static --disable-fortran --disable-mpi"

if [[ $target == x86_64-*  ]] || [[ $target == i686-* ]]; then config="$config --enable-sse2 --enable-avx2"; fi
# todo: --enable-avx512 on x86_64?
if [[ $target == aarch64-* ]]; then config="$config --enable-neon"; fi

# FreeBSD threads are problematic: BinaryBuilder.jl#232
if [[ $target != *-freebsd*  ]]; then config="$config --enable-threads --with-combined-threads"; fi

if [[ $target == *-w64-* ]]; then config="$config --with-our-malloc"; fi
if [[ $target == i686-w64-* ]]; then config="$config --with-incoming-stack-boundary=2"; fi

mkdir double && cd double
../configure $config
perl -pi -e "s/doc tools m4/doc m4/" Makefile # work around FFTW/fftw3#146
make install
cd ..

if [[ $target == powerpc64le-*  ]]; then config="$config --enable-altivec"; fi
if [[ $target == arm-*  ]]; then config="$config --enable-neon"; fi
mkdir single && cd single
../configure $config --enable-single
perl -pi -e "s/doc tools m4/doc m4/" Makefile # work around FFTW/fftw3#146
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libfftw3", :libfftw3),
    LibraryProduct(prefix, "libfftw3f", :libfftw3f),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "FFTW", sources, script, platforms, products, dependencies)
