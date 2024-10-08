# !!! Don't execute this script directly !!!
# It is imported in $TOP/install.sh

export CMAKE_VERSION=3.21.1 \
    BOOST_VERSION=1.67.0 \
    MDNS_VERSION=878.30.4 \
    REST_VERSION=2.10.11

install_cmake()
{
    echo "Installing CMake"
    DIR=$(mktemp -d)
    cd $DIR/
    # wget --no-check-certificate https://cmake.org/files/v3.21/cmake-$CMAKE_VERSION.tar.gz
    tar xvf $TOP_DIR/install/cmake-$CMAKE_VERSION.tar.gz
    cd $DIR/cmake-$CMAKE_VERSION
    ./bootstrap
    make
    make install
    rm -rf $DIR
}

install_conan()
{
    echo "Installing conan"
    pip install conan==v1.45
}

install_boost()
{
    echo "Installing Boost"
    DIR=$(mktemp -d)
    cd $DIR/
    boost_version=$(echo $BOOST_VERSION | tr '.' '_')
    # wget --no-check-certificate https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/boost_$boost_version.tar.gz
    tar xvf $TOP_DIR/install/boost_$boost_version.tar.gz
    cd $DIR/boost_$boost_version
    ./bootstrap.sh --with-libraries=date_time,regex,system,thread,random,filesystem,chrono,atomic --prefix=$PREFIX
    ./b2 install
    rm -rf $DIR
}

install_mdns(){
    ## You should use either Avahi or Apple mDNS - DO NOT use both
    echo "Installing mDNSResponder"
    # wget --no-check-certificate https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-$MDNS_VERSION.tar.gz
    tar xvf $TOP_DIR/install/mDNSResponder-$MDNS_VERSION.tar.gz

    # patch to make mdnsd work with unicast DNS
    # wget https://raw.githubusercontent.com/sony/nmos-cpp/master/Development/third_party/mDNSResponder/poll-rather-than-select.patch
    patch -d mDNSResponder-$MDNS_VERSION/ -p1 < $TOP_DIR/install/poll-rather-than-select.patch
    # wget https://raw.githubusercontent.com/sony/nmos-cpp/master/Development/third_party/mDNSResponder/unicast.patch
    patch -d mDNSResponder-$MDNS_VERSION/ -p1 < $TOP_DIR/install/unicast.patch

    cd ./mDNSResponder-$MDNS_VERSION/mDNSPosix
    set HAVE_IPV6=0
    #TODO: put that in $PREFIX
    make os=linux
    make os=linux install
    #rm -rf $DIR
}

install_cpprest()
{
    echo "Installing C++ REST"
    DIR=$(mktemp -d)
    cd $DIR/
    # git clone --recurse-submodules --branch v$REST_VERSION https://github.com/Microsoft/cpprestsdk
    tar zxvf $TOP_DIR/install/cpprestsdk-src.tar.gz
    mkdir cpprestsdk/Release/build
    cd cpprestsdk/Release/build

    cmake .. \
        -DCMAKE_BUILD_TYPE:STRING="Release" \
        -DWERROR:BOOL="0"
    make
    make install
    cp -rf ../libs/websocketpp/websocketpp/ $PREFIX/include/

    rm -rf $DIR
}

install_cppnode()
{
    echo "Installing Sony nmos-cpp"
    # git clone https://github.com/sony/nmos-cpp.git
    tar zxvf $TOP_DIR/install/nmos-cpp-src.tar.gz
    mkdir ./nmos-cpp/Development/build
    cd ./nmos-cpp/Development/build

    cmake .. \
        -G "Unix Makefiles" \
        -DCMAKE_CONFIGURATION_TYPES:STRING="Debug" \
        -DBoost_USE_STATIC_LIBS:BOOL="1" \
        -DCMAKE_CXX_FLAGS="-fpermissive" \
        -DWEBSOCKETPP_INCLUDE_DIR:PATH="$PREFIX/include/websocketpp"

    make
    install -m 755 ./nmos-cpp-node ./nmos-cpp-registry ./nmos-cpp-test $PREFIX/bin
}

install_cppnode_example()
{
    echo "Installing node example based on nmos-cpp lib"
    mkdir dev
    cd dev
    # git clone https://github.com/pkeroulas/nmos-cpp-examples
    tar zxvf $TOP_DIR/install/nmos-cpp-examples-src.tar.gz
    mkdir ./nmos-cpp-examples/build
    cd ./nmos-cpp-examples/build
    cmake .. -DCMAKE_BUILD_TYPE:STRING="Release"
    make
    ln -s ~/dev/nmos-cpp-examples/build/my-nmos-node/my-nmos-node ~/my-nmos-node
    cp ./nmos.json ~/my-nmos-node
}

install_nmos_init(){
    install -m 755 ./nmos.init /etc/init.d/nmos
    update-rc.d nmos defaults
    systemctl enable nmos
    systemctl start nmos
}

install_nmos() {
    set -x
    install_cmake
    install_conan
    install_cppnode_example
    install_nmos_init
    set +x
}
