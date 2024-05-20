@echo on


::
export CC=$CC_FOR_BUILD
export CXX=$CXX_FOR_BUILD
export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH//$PREFIX/$BUILD_PREFIX}

# Unset them as we're ok with builds that are either slow or non-portable
unset CFLAGS
unset CXXFLAGS

cmake ${SRC_DIR} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$BUILD_PREFIX -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True
# No need to compile everything, just gazebomsgs_out is sufficient
cmake --build . --target ShaderEncoder --parallel ${CPU_COUNT} --config Release
cmake --build . --target ShaderLinker --parallel ${CPU_COUNT} --config Release


mkdir build
cd build

:: config

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DSHADER_ENCODER_PATH:STRING=`pwd`/../build-host/bin/ShaderEncoder"
  export CMAKE_ARGS="${CMAKE_ARGS} -DSHADER_LINKER_PATH:STRING=`pwd`/../build-host/bin/ShaderLinker"
fi

cmake -G "Visual Studio 16 2019" -A x64 -DCMAKE_INSTALL_PREFIX="<open3d_install_directory>"
cmake ${SRC_DIR} ${CMAKE_ARGS} \
    -DBUILD_AZURE_KINECT=OFF \
    -DBUILD_CUDA_MODULE=ON \
    -DGLIBCXX_USE_CXX11_ABI=OFF \
    -DBUILD_PYTORCH_OPS=ON \
    -DBUILD_TENSORFLOW_OPS=ON \
    -DBUNDLE_OPEN3D_ML=ON \
    -DOPEN3D_ML_ROOT=https://github.com/isl-org/Open3D-ML.git \
    -DBUILD_COMMON_CUDA_ARCHS=OFF \
    -DBUILD_CACHED_CUDA_MANAGER=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_ISPC_MODULE=OFF \
    -DBUILD_GUI=OFF \
    -DBUILD_LIBREALSENSE=OFF \
    -DBUILD_REALSENSE=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_WEBRTC=OFF \
    -DENABLE_HEADLESS_RENDERING=OFF \
    -DBUILD_JUPYTER_EXTENSION=OFF \
    -DOPEN3D_USE_ONEAPI_PACKAGES=OFF \
    -DUSE_BLAS=ON \
    -DUSE_SYSTEM_ASSIMP=ON \
    -DUSE_SYSTEM_BLAS=ON \
    -DUSE_SYSTEM_CURL=ON \
    -DUSE_SYSTEM_EIGEN3=ON \
    -DUSE_SYSTEM_EMBREE=ON \
    -DUSE_SYSTEM_FMT=ON \
    -DUSE_SYSTEM_GLEW=ON \
    -DUSE_SYSTEM_GLFW=ON \
    -DUSE_SYSTEM_GOOGLETEST=ON \
    -DUSE_SYSTEM_IMGUI=ON \
    -DUSE_SYSTEM_JPEG=ON \
    -DUSE_SYSTEM_JSONCPP=ON \
    -DUSE_SYSTEM_LIBLZF=ON \
    -DUSE_SYSTEM_LIBREALSENSE=OFF \
    -DUSE_SYSTEM_MSGPACK=ON \
    -DUSE_SYSTEM_NANOFLANN=ON \
    -DUSE_SYSTEM_OPENSSL=ON \
    -DUSE_SYSTEM_PNG=ON \
    -DUSE_SYSTEM_PYBIND11=ON \
    -DUSE_SYSTEM_QHULLCPP=ON \
    -DUSE_SYSTEM_TBB=OFF \
    -DUSE_SYSTEM_TINYGLTF=OFF \
    -DUSE_SYSTEM_TINYOBJLOADER=ON \
    -DUSE_SYSTEM_VTK=ON \
    -DUSE_SYSTEM_ZEROMQ=ON \
    -DWITH_IPPICV=OFF \
    -DWITH_FAISS=OFF \
    -DPython3_EXECUTABLE=$PYTHON

:: install
cmake --build . --config Release -- -j$CPU_COUNT
cmake --build . --config Release --target install
cmake --build . --config Release --target install-pip-package


:: -wnx flags mean: --wheel --no-isolation --skip-dependency-check
%PYTHON% -m build -w -n -x ^
    -Cbuilddir=builddir ^
    -Csetup-args=-Dblas=blas ^
    -Csetup-args=-Dlapack=lapack
if %ERRORLEVEL% neq 0 
