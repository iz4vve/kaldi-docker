FROM centos:latest

LABEL maintainer="Pietro Mascolo <iz4vve@gmail.com>"

RUN yum update -y && yum upgrade -y && \
    yum install -y epel-release && yum --enablerepo=epel clean metadata && \
                yum update && yum install -y \
        	    make \
                which \
                gcc-c++ \
                zlib-devel \
                automake \
                autoconf \
                patch \
                grep \
                bzip2 \
                gzip \
                wget \
                git \
                libtoolize \
                subversion \
                awk \
                python2.7 \
                yum-utils \
                groupinstall development \
                libtool \
                atlas.x86_64 \
                atlas-devel \
                curl \
                git \
                unzip \
                python34 \
                python-devel \
                python34-devel \
                python34-setuptools \
                sox \
                vim \
                && easy_install-3.4 pip  && yum clean all

ENV PYTHONWARNINGS="ignore:a true SSLContext object"

# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
#	update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

# Install pip and Add SNI support to Python
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
	python get-pip.py && \
	rm get-pip.py && pip --no-cache-dir install \
		pyopenssl \
		ndg-httpsclient \
		pyasn1

# Kaldi related packages
ARG OPENFST_VERSION=1.6.5
ARG NUM_BUILD_CORES=4
ENV OPENFST_VERSION ${OPENFST_VERSION}
ENV NUM_BUILD_CORES ${NUM_BUILD_CORES}
ENV DEBIAN_FRONTEND noninteractive
ENV LD_LIBRARY_PATH "/app/src/kaldi/lib"
ENV PKG_CONFIG_PATH "./pkg-config:/usr/local:/app/src/kaldi/kaldiasr:/app/src/kaldi/pkg-config:/usr/local/include/atlas"

RUN git clone https://github.com/kaldi-asr/kaldi.git /kaldi --depth=1 && \
    /kaldi/tools/extras/check_dependencies.sh | grep "sudo apt-get" | \
	while read -r cmd; do \
            $cmd -y ; \
        done

RUN cd /kaldi/tools && \
	make OPENFST_VERSION=${OPENFST_VERSION} -j${NUM_BUILD_CORES}

RUN cd /kaldi/src && \
	./configure --shared && make depend && make -j${NUM_BUILD_CORES}

# CLEANUP
RUN find /kaldi -iname '*.[oa]' -exec rm {} \;

