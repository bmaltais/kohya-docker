# Stage 1: Base
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Africa/Johannesburg \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    KOHYA_VERSION=dev2

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        apt-transport-https \
        bash \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        htop \
        libcairo2-dev \
        libglib2.0-0 \
        libgl1 \
        libgoogle-perftools4 \
        libsm6 \
        libtcmalloc-minimal4 \
        libxext6 \
        libxrender1 \
        ncdu \
        net-tools \
        openssh-server \
        p7zip-full \
        pkg-config \
        psmisc \
        python3.10-venv \
        python3-tk \
        rsync \
        software-properties-common \
        unzip \
        vim \
        wget && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Stage 2: Install kohya_ss and python modules
FROM base as kohya_ss_setup

# Install Kohya_ss

WORKDIR /kohya_ss
RUN git clone https://github.com/bmaltais/kohya_ss.git . && \
    git checkout $KOHYA_VERSION && \
    python3 -m venv --system-site-packages venv && \
    . venv/bin/activate && \
    pip3 install torch==2.0.1+cu118 torchvision==0.15.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118 \
        xformers==0.0.20 bitsandbytes==0.35.0 accelerate==0.15.0 tensorboard==2.12.1 tensorflow==2.12.0 wheel \
        -r requirements.txt && \
    # Fix Tensorboard
    pip3 uninstall -y tensorboard tb-nightly && \
    pip3 install tensorboard tensorflow && \
    deactivate

# # Stage 3: Final setup
# FROM base as final
# WORKDIR /workspace

# COPY --from=kohya_ss_setup /workspace/kohya_ss /kohya_ss

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install Jupyter
RUN . venv/bin/activate && \
    pip3 install \
        jupyterlab \
        ipywidgets \
        jupyter-archive \
        jupyter_contrib_nbextensions \
        gdown && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    deactivate

WORKDIR /workspace

# Copy startup script and config file
COPY start.sh /start.sh
RUN chmod a+x /start.sh
COPY accelerate.yaml /accelerate.yaml

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
