# Dockerfile to build EE-UQ
#   installing: Qt5.15.2, OpenSees3.5.0, dakota6.15.0, python3.9.6
# written: fmk 08/23

FROM ubuntu:bionic

SHELL ["/bin/bash", "-c"]

ARG versionEE=d3.4.0
ARG versionSimCenterCommon=v23.09
ARG versionSimCenterBackend=v23.09
ARG versionOpenSees=v3.5.0

WORKDIR /simcenter

#
# Install Qt
#   note: utilizes following for Qt: https://launchpad.net/~beineri/+archive/ubuntu/opt-qt-5.15.2-bionic
# 

RUN apt-get update \
    && apt-get install -y sudo \
    && sudo apt install -y software-properties-common cmake \
    && sudo add-apt-repository -y  ppa:beineri/opt-qt-5.15.2-bionic \
    && sudo apt update \
    && sudo apt-get install -y build-essential freeglut3-dev python3-pip git \
    && sudo python3 -m pip install -U pip \
    && pip3 install conan==1.60.1 \
    && sudo apt-get install -y qt515base qt5153d qt515charts-no-lgpl qt515webengine

#
# Build the EE-UQ frontend & copy tacc config.json
#

RUN  source /opt/qt515/bin/qt515-env.sh \
    && git clone -b $versionSimCenterCommon --single-branch https://github.com/NHERI-SimCenter/SimCenterCommon.git \
    && git clone https://github.com/NHERI-SimCenter/QS3hark.git \    
    && git clone -b $versionEE --single-branch https://github.com/NHERI-SimCenter/EE-UQ.git \
    && cd EE-UQ \
    && mkdir build \
    && cd build \
    && qmake ../EE-UQ.pro \
    && make \
    && rm -fr .obj *.o *.cpp \
    && cp ../tacc/config.json ./ \
    && cd ../.. 


#
# Build OpenSees
#   note: some stuff in there to get latest cmake as 3.10 not doing it
#

RUN sudo apt-get install -y cmake liblapack-dev libomp-dev libssl-dev apt-transport-https ca-certificates wget \        
    && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null \
    && sudo apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    && sudo apt-get update \
    && sudo apt-get install -y cmake gfortran gcc g++ \
    && git clone -b $versionOpenSees --single-branch https://github.com/OpenSees/OpenSees.git \
    && cd OpenSees \
    && mkdir build; cd build \
    && conan install .. --build missing \
    && cmake .. \
    && cmake --build . --config Release \
    && cmake --install . \
    && sudo mv ./lib/* /usr/local/lib \
    && cd ../..; rm -fr OpenSees

#
# Build Dakota
#    note: dakota also needed more upto date cmake

RUN wget https://github.com/snl-dakota/dakota/releases/download/v6.15.0/dakota-6.15.0-public-src-cli.tar.gz \
    && sudo apt-get install -y libboost-dev libboost-all-dev libopenmpi-dev openmpi-bin xorg-dev libmotif-dev \
    && tar zxBf dakota-6.15.0-public-src-cli.tar.gz \
    && mv dakota-6.15.0-public-src-cli dakota-6.15.0 \
    && cd dakota-6.15.0 \
    && mkdir build; cd build \
    && cmake .. \
    && cmake --build . --config Release \
    && cmake --install . \
    && cd ../..; rm -fr dakot*    

   
#
# Build SimCenter Backend Applications
#    note: need newer gcc, gcc-10 which necessitates removing old conan 
#

RUN git clone -b $versionSimCenterBackend https://github.com/NHERI-SimCenter/SimCenterBackendApplications.git \
    && cp ./SimCenterBackendApplications/modules/performUQ/SimCenterUQ/nataf_gsa/CMakeLists.txt.UBUNTU ./SimCenterBackendApplications/modules/performUQ/SimCenterUQ/nataf_gsa/CMakeLists.txt \
    && rm -fr ~/.conan \
    && sudo apt-get install -y liblapack-dev libomp-dev libssl-dev apt-transport-https ca-certificates \        
    && sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && sudo apt-get update \
    && sudo apt-get install -y gcc-10 g++-10 gfortran-10 \
    && export CC=gcc-10 \
    && export CXX=g++-10 \
    && export FC=gfortran-10 \    
    && conan remote add simcenter https://nherisimcenter.jfrog.io/artifactory/api/conan/simcenter \
    && cd SimCenterBackendApplications \
    && mkdir build \
    && cd build \
    && conan install .. --build missing \
    && cmake .. \
    && cmake --build . --config Release \
    && cmake --install . \
    && cd ../..


#
# Install python3.9
#  note: need a later python3 for nheri-simcenter
#         which we have to build from source!!!
#

RUN sudo apt-get install -y zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libreadline-dev libffi-dev libbz2-dev \
    && wget https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tgz \
    && tar -xf Python-3.9.6.tgz \
    && cd Python-3.9.6 \
    && ./configure --enable-optimizations \
    && sudo make install \
    && cd ..; rm -fr python* \
    && pip3 install nheri-simcenter

#
# Copy all files into correct locations for running & clean up
#

RUN cd EE-UQ/build \
    && cp -r ../Examples ./ \
    && cp -r ../../SimCenterBackendApplications/applications . \
    && rm -fr /simcenter/SimCenterBackendApplications \
    && rm -fr /simcenter/SimCenterCommon

#
# add following for the missing lib libQt5Core.so error that is related to running on some versions linux
# with an older kernel, seemingly need kernel >= 3.5 on host .. soln from Sal T. found in an AskUbuntu thread
#

RUN strip --remove-section=.note.ABI-tag /opt/qt515/lib/libQt5Core.so.5

#
# Finally add a new user simcenter as root cannot run the Qt app
#

RUN useradd -ms /bin/bash simcenter

USER simcenter