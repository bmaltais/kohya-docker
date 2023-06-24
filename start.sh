#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
export KOHYA_VENV=/workspace/kohya_ss/venv

echo "Container is running"

# Sync Kohya_ss to workspace to support Network volumes
echo "Syncing Kohya_ss to workspace, please wait..."
rsync -au --remove-source-files /kohya_ss/ /workspace/kohya_ss/
rm -rf /kohya_ss

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys
    chmod 700 -R ~/.ssh
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    source ${KOHYA_VENV}/bin/activate
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
    deactivate
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch them it using the launcher script:"
    echo ""
    echo "   cd /workspace/kohya_ss"
    echo "   ./gui.sh --listen 0.0.0.0 --server_port 3000 --headless"
else
    echo "Starting Kohya_ss Web UI"
    mkdir -p /workspace/logs
    cd /workspace/kohya_ss
    source /workspace/kohya_ss/venv/bin/activate
    nohup ./gui.sh --listen 0.0.0.0 --server_port 3000 --headless > /workspace/logs/kohya_ss.log &
    echo "Kohya_ss started"
    echo "Log file: /workspace/logs/kohya_ss.log"
fi

echo "All services have been started"

sleep infinity