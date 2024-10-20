###########################################
#  Ubuntu 20.04 as the base image 
###########################################
FROM ubuntu:20.04


###########################################
#  Labels for metadata and other configs
###########################################

LABEL maintainer="ArthurRL"
LABEL version="1.0.0"
LABEL description="This image builds Qt 6.7.2 from source with support for X11, Vulkan, CUDA, and Qt Creator."
LABEL qt_version="6.7.2"
LABEL vulkan_sdk_version="1.3.290.0"
LABEL cuda_version="12.6.1"
LABEL CMAKE="3.30.3"
LABEL python_script="monitor.py"
LABEL base_image="ubuntu:20.04"

# Set non-interactive mode for apt-get installs
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=America/Sao_Paulo


#######################################
#  Install Python and psutil
#######################################

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip && \
    pip3 install psutil && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


##########################################
#  Install basic dependencies with apt
##########################################

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    dkms \
    git \
    make \
    gdb \
    pkg-config \
    gnupg \
    lsb-release \
    ca-certificates \
    software-properties-common \
    gnupg \
    lldb \
    libssl-dev \
    libsecret-1-dev \
    libgcrypt20-dev \
    xz-utils \
    libxcb-cursor-dev \
    libx11-xcb1 \
    libx11-dev \
    libxi6 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libxext-dev \
    libxrandr-dev \
    libxrender-dev \
    libxcb1-dev \
    libxcb-glx0-dev \
    libxcb-keysyms1-dev \
    libxcb-image0-dev \
    libxcb-shm0-dev \
    libxcb-icccm4-dev \
    libxcb-sync0-dev \
    libxcb-xfixes0-dev \
    libxcb-shape0-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-xinerama0-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxkbcommon-x11-0 \
    libfontconfig1-dev \
    libfreetype6-dev \
    locales \
    libclang-dev \
    ninja-build \
    libglvnd-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    libsm6 \
    libice6 \
    libpci-dev \
    libpulse-dev \
    libudev-dev \
    libxtst-dev \
    mesa-common-dev \
    mesa-utils \
    libjsoncpp-dev \
    libblas-dev \
    liblapack-dev \
    libopus-dev \
    libminizip-dev \
    libavutil-dev \
    libavformat-dev \
    libavcodec-dev \
    libevent-dev \
    libasound2-dev \
    libcpprest-dev \
    alsa-base \
    alsa-utils \
    pulseaudio \
    libvulkan1 libvulkan-dev vulkan-tools vulkan-utils mesa-vulkan-drivers vulkan-validationlayers \
    libglvnd0 \
    libglu1-mesa-dev \
    x11-xserver-utils \
    libwayland-dev wayland-protocols \
    xorg-dev \
    xterm \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get -y upgrade \
    && apt-get autoremove


###################################
#  Locale and Language
###################################

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


############################################
#  Installing CMake (newer version)
############################################

ENV CMAKE_VERSION="3.30.3"
RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz -O /tmp/cmake-$CMAKE_VERSION.tar.gz && \
    cd /tmp && \
    tar -xzvf cmake-$CMAKE_VERSION.tar.gz && \
    cd cmake-$CMAKE_VERSION && \
    ./bootstrap && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/cmake-$CMAKE_VERSION*


############################################
#  CUDA drivers and toolkit installation
############################################

ENV CUDA_VERSION="12.6.1"
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin && \
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/cuda-repo-ubuntu2004-12-6-local_$CUDA_VERSION-560.35.03-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2004-12-6-local_$CUDA_VERSION-560.35.03-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2004-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && apt-get -y install cuda-toolkit-12-6 cuda-drivers && \
    rm cuda-repo-ubuntu2004-12-6-local_$CUDA_VERSION-560.35.03-1_amd64.deb /etc/apt/sources.list.d/cuda-ubuntu2004-12-6-local.list && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cuda-repo-ubuntu2004-12-6-local


###################################
#  Install LLVM and Clang
###################################

RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && ./llvm.sh 14 && \
    apt-get update && \
    apt-get install -y libclang-14-dev llvm-14-dev || cat /var/log/apt/term.log && \
    rm llvm.sh && apt-get clean && rm -rf /var/lib/apt/lists/*


###################################
# C++ configs
###################################

ENV CC="gcc"
ENV CXX="g++"


###################################
# Building Qt
###################################

ENV LLVM_INSTALL_DIR="/usr/lib/llvm-14"
ENV CMAKE_PREFIX_PATH="$LLVM_INSTALL_DIR"

ENV QT="6.7.2"
ENV QT_DIR="/opt/Qt/$QT"

# Install Qt manually using the specified version
RUN wget https://download.qt.io/official_releases/qt/6.7/$QT/single/qt-everywhere-src-$QT.tar.xz -O /tmp/qt-everywhere-src-$QT.tar.xz && \
    cd /tmp && \
    tar -xJf qt-everywhere-src-$QT.tar.xz && \
    mkdir -p /tmp/qt-everywhere-src-$QT/build && \
    cd /tmp/qt-everywhere-src-$QT/build && \
    /tmp/qt-everywhere-src-$QT/configure -prefix $QT_DIR -release -opensource -confirm-license -nomake tests -nomake examples -skip qtopcua && \
    cmake --build . --parallel $(( $(nproc) / 2 )) && \
    cmake --install . && \
    rm -rf /tmp/qt-everywhere-src-$QT*


###################################
# Building QtCreator
###################################

ENV CMAKE_PREFIX_PATH="$QT_DIR/gcc_64:$QT_DIR/lib:$QT_DIR/lib/cmake:$QT_DIR/lib/cmake/Qt6:$CMAKE_PREFIX_PATH"

# Download Qt Creator source and build using CMake and Ninja
ENV QTCREATOR_VERSION="13.0.2"
ENV QTCREATOR="/opt/QtCreator"

RUN wget https://download.qt.io/official_releases/qtcreator/13.0/$QTCREATOR_VERSION/qt-creator-opensource-src-$QTCREATOR_VERSION.tar.xz -O /tmp/qt-creator-opensource-src-$QTCREATOR_VERSION.tar.xz && \
    cd /tmp && \
    tar -xJf qt-creator-opensource-src-$QTCREATOR_VERSION.tar.xz && \
    mkdir /tmp/qtcreator_build && \
    cd /tmp/qtcreator_build && \
    cmake -DCMAKE_BUILD_TYPE=Debug -G Ninja "-DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH" /tmp/qt-creator-opensource-src-$QTCREATOR_VERSION && \
    cmake --build . --parallel $(( $(nproc) / 2 )) && \
    cmake --install . --prefix $QTCREATOR && \
    rm -rf /tmp/qtcreator_build /tmp/qt-creator-opensource-src-$QTCREATOR_VERSION /tmp/qt-creator-opensource-src-$QTCREATOR_VERSION.tar.xz


###################################
# Set up all Libraries
###################################

# Env libraries version
ENV LIBRARY_PATH="/usr/local"

# Set up Vulkan SDK
ENV VULKAN_SDK_VERSION="1.3.290.0"
RUN mkdir -p $LIBRARY_PATH/VulkanSDK && \
    wget -qO - https://sdk.lunarg.com/sdk/download/$VULKAN_SDK_VERSION/linux/vulkansdk-linux-x86_64-$VULKAN_SDK_VERSION.tar.xz | \
    tar -xJf - -C $LIBRARY_PATH/VulkanSDK

# Download and install GLFW from source
ENV GLFW_VERSION="3.4"
RUN wget https://github.com/glfw/glfw/archive/refs/tags/$GLFW_VERSION.tar.gz -O /tmp/glfw-$GLFW_VERSION.tar.gz && \
    tar -xzf /tmp/glfw-$GLFW_VERSION.tar.gz -C /tmp/ && \
    cd /tmp/glfw-$GLFW_VERSION && mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$LIBRARY_PATH .. && \
    make && make install && \
    rm /tmp/glfw-$GLFW_VERSION.tar.gz && rm -rf /tmp/glfw-$GLFW_VERSION

# Download and install PLOG (header-only library)
ENV PLOG_VERSION="1.1.10"
RUN wget https://github.com/SergiusTheBest/plog/archive/refs/tags/$PLOG_VERSION.tar.gz -O /tmp/plog-$PLOG_VERSION.tar.gz && \
    tar -xzf /tmp/plog-$PLOG_VERSION.tar.gz -C /tmp/ && \
    mv /tmp/plog-$PLOG_VERSION/include/plog/ $LIBRARY_PATH/include/plog && \
    rm /tmp/plog-$PLOG_VERSION.tar.gz && rm -rf /tmp/plog-$PLOG_VERSION

# Download and install GLM (header-only library)
ENV GLM_VERSION="1.0.1"
RUN wget https://github.com/g-truc/glm/archive/refs/tags/$GLM_VERSION.tar.gz -O /tmp/glm-$GLM_VERSION.tar.gz && \
    tar -xzf /tmp/glm-$GLM_VERSION.tar.gz -C /tmp/ && \
    mv /tmp/glm-$GLM_VERSION/glm/ $LIBRARY_PATH/include/glm && \
    rm /tmp/glm-$GLM_VERSION.tar.gz && rm -rf /tmp/glm-$GLM_VERSION


###################################
# Important environment variables
###################################

ENV VULKAN_SDK="$LIBRARY_PATH/VulkanSDK/$VULKAN_SDK_VERSION/x86_64"
ENV VK_ICD_FILENAMES="$VULKAN_SDK/etc/vulkan/icd.d:/usr/share/vulkan/icd.d"
ENV PATH="$LIBRARY_PATH:$LIBRARY_PATH/include:$VULKAN_SDK/bin:$QTCREATOR/bin:$QT_DIR/gcc_64/bin:$LLVM_INSTALL_DIR/bin:$PATH"
ENV QT_QPA_PLATFORM_PLUGIN_PATH="$QT_DIR/gcc_64/plugins/platforms"
ENV LD_LIBRARY_PATH="$QTCREATOR/lib:$QT_DIR/gcc_64/lib:$QT_DIR/lib:$VULKAN_SDK/lib:$LLVM_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="$QT_DIR/gcc_64/lib/pkgconfig:$PKG_CONFIG_PATH"

# Copy Python script
RUN mkdir -p /app
COPY ./monitor.py /app/monitor.py

# Default shell for interactive debugging (optional)
SHELL ["/bin/bash", "-c"]

# Run the Python script
ENTRYPOINT ["python3", "-u", "/app/monitor.py"]
