# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CglBuilder"
version = v"0.59.10"

# Collection of sources required to build CglBuilder
sources = [
   "https://github.com/coin-or/Cgl/archive/releases/0.59.10.tar.gz" =>
   "2a4038dfeb00b4f4084bbe00b144b6bae4ddfe87873ac5913603af248cb3f1d4",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Cgl-releases-0.59.10/
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
# To fix an OSX toolchain bug. See https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/388
if [[ ${target} == *darwin* ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi
mkdir build
cd build/
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
   export LDFLAGS="-L${prefix}/lib -lClp"
fi

## STATIC BUILD START
../configure --prefix=$prefix --disable-pkg-config --with-pic --host=${target} --disable-shared --enable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin" \
--with-osiclp-lib="-L${prefix}/lib -lOsiClp" --with-osiclp-incdir="$prefix/include/coin"
## STATIC BUILD END

## DYNAMIC BUILD START
#../configure --prefix=$prefix --disable-pkg-config --with-pic --host=${target} --enable-shared --disable-static \
#--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
#--with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin" \
#--with-osiclp-lib="-L${prefix}/lib -lOsiClp" --with-osiclp-incdir="$prefix/include/coin"
## DYNAMIC BUILD END

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
platforms = setdiff(platforms, [Windows(:x86_64, compiler_abi=CompilerABI(:gcc4)), Windows(:i686, compiler_abi=CompilerABI(:gcc4))])
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# The products that we will ensure are always built
products(prefix) = [
   LibraryProduct(prefix, "libCgl", :libCgl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaOpt/OsiBuilder/releases/download/v0.107.9-1/build_OsiBuilder.v0.107.9.jl",
    "https://github.com/JuliaOpt/CoinUtilsBuilder/releases/download/v2.10.14-1/build_CoinUtilsBuilder.v2.10.14.jl",
    "https://github.com/JuliaOpt/COINMumpsBuilder/releases/download/v1.6.0-1/build_COINMumpsBuilder.v1.6.0.jl",
    "https://github.com/JuliaOpt/COINMetisBuilder/releases/download/v1.3.5-1/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/JuliaOpt/COINLapackBuilder/releases/download/v1.5.6-1/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/JuliaOpt/COINBLASBuilder/releases/download/v1.4.6-1/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/JuliaOpt/ASLBuilder/releases/download/v3.1.0-1/build_ASLBuilder.v3.1.0.jl",
   "https://github.com/juan-pablo-vielma/ClpBuilder/releases/download/v1.16.11-1/build_ClpBuilder.v1.16.11.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
