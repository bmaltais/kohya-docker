FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

ARG KOHYA_VERSION=v21.7.10
ARG KOHYA_VENV=/workspace/kohya_ss/venv

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /workspace

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-tk \
        bash \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        unzip \
        p7zip-full \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Install Kohya_ss
ENV TZ=Africa/Johannesburg
RUN git clone https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss
WORKDIR /workspace/kohya_ss
RUN git checkout ${KOHYA_VERSION} && \
    python3 -m venv ${KOHYA_VENV} && \
    source ${KOHYA_VENV}/bin/activate && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir xformers && \
    pip3 install -r requirements_unix.txt && \
    pip3 install . && \
    pip3 cache purge && \
    deactivate

# Complete Jupyter installation
RUN source ${KOHYA_VENV}/bin/activate && \
    pip3 install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown && \
    deactivate

# Fix Tensorboard
RUN source ${KOHYA_VENV}/bin/activate && \
    pip3 uninstall -y tensorboard tb-nightly && \
    pip3 install tensorboard tensorflow && \
    pip3 cache purge && \
    deactivate

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Move Kohya_ss and venv to the root
# so it doesn't conflict with Network Volumes
WORKDIR /workspace
RUN mv /workspace/kohya_ss /kohya_ss

# Set up the container startup script
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]