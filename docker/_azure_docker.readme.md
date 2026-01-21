# 1. Preparing your Software Image
## 1.1 Build PADV non-interactive docker image
Following MathWorks Reference Architectures, you need to build an image from non-interactive docker file. you can find more details at the following repo:
https://github.com/mathworks-ref-arch/matlab-dockerfile

Example file path: https://raw.githubusercontent.com/mathworks-ref-arch/matlab-dockerfile/refs/heads/main/alternates/non-interactive/Dockerfile

```
# PowerShell script
$CONTAINER_REGISTRY = "<Container_Register_Domain>"
$PADV_IMAGE = "<Custom_Docker_Image_Name>"
$PADV_IMAGE_TAG = "<Custom_Image_Tag>"
$MATLAB_RELEASE = "R2024b"
$PADV_IMAGE_NAME = "${PADV_IMAGE}:${PADV_IMAGE_TAG}"

docker buildx build -f non-interactive.Dockerfile `
  --build-arg MATLAB_RELEASE=$MATLAB_RELEASE `
  --build-arg MATLAB_PRODUCT_LIST='MATLAB Simulink Simulink_Check Simulink_Design_Verifier Simulink_Report_Generator Simulink_Coder Simulink_Compiler Simulink_Test Embedded_Coder Simulink_Coverage Requirements_Toolbox CI/CD_Automation_for_Simulink_Check' `
  -t $CONTAINER_REGISTRY/$PADV_IMAGE_NAME .
  ```
> **_NOTE:_** You can remove or add more MATLAB's toolboxes by updating the 'MATLAB_PRODUCT_LIST' argument

> **_NOTE:_** Default docker file has ENTRYPOINT value equal to "xvfb-run" which may not be suitable for generic purpose senatios

## 1.2 Build PADV CI docker image
This image add a top layer to the non-interactive image by adding the following libraries and CLIs: python3, git client, JFrog cli, Azure cli, AWS cli. This layer also clear the default docker image ENTRYPOINT value for better flexibility.

You can use 'ci-addons.Dockerfile' to build this image using the following script
```
# PowerShell script
$CONTAINER_REGISTRY = "<Container_Register_Domain>"
$PADV_IMAGE = "<Custom_Docker_Image_Name>"
$PADV_IMAGE_TAG = "<Custom_Image_Tag>"
$MATLAB_RELEASE = "R2024b"
$PADV_IMAGE_NAME = "${PADV_IMAGE}:${PADV_IMAGE_TAG}"

$CI_TAG = "ci"
$PADV_CI_IMAGE_NAME = "${PADV_IMAGE_NAME}_${CI_TAG}"

docker build -f ci-addons.Dockerfile `
    --build-arg BASE_IMAGE="$CONTAINER_REGISTRY/$PADV_IMAGE_NAME" `
    -t $CONTAINER_REGISTRY/$PADV_CI_IMAGE_NAME .
```
# 2. Configure your Azure DevOps agents
Azure DevOps doens't support Linux containers operations on Windows agents, they are only supported on Linux agents. You can use WSL environemnt as your Azure DevOps agent, in this case you need also to install Docker-CE engine to support container operations.

```
########### Intsalling WSL
wsl --install -d Ubuntu
wsl --set-default Ubuntu

########### Installing Dokcer engine
# Add Docker's official GPG key for ubuntu:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker engine
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
 
# Adjusting the access
sudo chown $USER /var/run/docker.sock
sudo usermod -aG docker $USER
newgrp docker

# Optional: Install portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/home/ahmedh/data portainer/portainer-ce:latest
```

Add new self-hosted agent using the project settings screen at Runners section.
```
mkdir -p ~/runners/az/az01
cd ~/runners/az/az01
curl -L https://download.agent.dev.azure.com/agent/4.258.1/vsts-agent-linux-x64-4.258.1.tar.gz -o vsts-agent-linux-x64-4.258.1.tar.gz
tar zxvf vsts-agent-linux-x64-4.258.1.tar.gz
rm vsts-agent-linux-x64-4.258.1.tar.gz
./config.sh
# Server URL: https://dev.azure.com/<Organization>
# Authentication Type: PAT
./run.sh
```

> **_NOTE:_** Azure DevOps requires providing an image USER that has access to groupadd and other privileged commands without using sudo, for more details please check the following link:
https://learn.microsoft.com/en-us/azure/devops/pipelines/process/container-phases?view=azure-devops&tabs=linux
. These settings already configured at ci-addons.Dockerfile Image layers.

# 3. Configure your GitHub Actions pipeline

In CI environemnts, MATLAB batch licensing token is the recommended way to license your MATLAB containers. MATLAB batch licensing token tool is already installed inside your Docker image but you need to supply the license token secret through the container environemnt variables. We recommend saving the token secret into your Azure DevOps pipeline variables as a variable of type secret and name 'MLM_LICENSE_TOKEN_SECRET'.

At the generated pipeline, make sure to uncomment the resources container configuration section and to populate the default image full name; this image tag will be used for all the pipeline jobs.
Also at the generated pipeline uncomment container default mapping value at job_build_files job, you also need to uncomment the default container mapping value at generic-job.yml template file.

At the generated pipeline, make sure to review RUNNER_LABEL, and SUPPORT_PACKAGE_ROOT variables.

While generating the pipeline, make sure to review MatlabLaunchCmd, MatlabStartupOptions and AddBatchStartupOption values.