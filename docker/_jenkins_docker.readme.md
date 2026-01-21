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
# 2. Configure your Jenkins agent
ProcessAdvisor support containers in Jenkins through Docker's plugin (https://plugins.jenkins.io/docker-plugin/). Using Docker plugin, Jenkins doens't support Linux containers operations on Windows agents due to workspace mapping mismatching. You can use WSL environemnt as your Jenkins agent, in this case you need also to install Docker-CE engine to support container operations.

Tested with Docker plugin's version: 1274.vc0203fdf2e74


> **_NOTE:_** Jenkins Docker's plugin requires choosing the agent's user carfully becuase this will be by default the container user, standard MATLAB image run with MATLAB user with ID equal 1001, so you need to maintain the user and its access to the host workspace. Privilege mismatch is a common configuration problem where the user running a process inside a container does not match the bind-mount privileges it tries to access.
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

You may need to install Java openjdk if not yet:
```
sudo apt install openjdk-21-jdk -y
```
Tested with openjdk 21.0.7 2025-04-15


<!-- Add matlab user with the same ID (i.e. 1001) as the container-->
sudo groupadd -g 1001 matlab
sudo useradd -m -u 1001 -g 1001 matlab
sudo usermod -aG docker matlab
sudo passwd matlab
<!-- Switch to the user -->
sudo -su matlab


Add new self-hosted Jenkins' agent, you can check the example script below.
```
<!-- Make sure to login to the custom container registry -->
docker login slcicd.azurecr.io -u slcicd -p ********
<!-- You can check by pulling images -->
docker pull 'slcicd.azurecr.io/slcheck/padv-ci:r2024b_apr25t_ci_spkg20250729'

<!-- adjust github access -->
credentials type: Username with password
credentials: PAT
Repository URL: https://github.com/********.git


mkdir -p /home/matlab/runners/jenkins/wsl01
cd /home/matlab/runners/jenkins/wsl01

curl -sO http://localhost:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://localhost:8080/ -secret ******** -name "wsl_agent" -webSocket -workDir "/home/ahmedh/runners/jenkins/j01"
```

# 3. Configure your Jenkins pipeline

In CI environemnts, MATLAB batch licensing token is the recommended way to license your MATLAB containers. MATLAB batch licensing token tool is already installed inside your Docker image but you need to supply the license token secret through the container environemnt variables. We recommend saving the token secret into your Jenkins credentials with the name 'MLM_LICENSE_TOKEN_SECRET', please check the example below.

At your Jenkins pipeline, make sure to uncomment and supply MW_SUPPORT_PACKAGE_ROOT and MW_RELATIVE_PROJECT_PATH variables, also you need to set the different pipeline options at generate_jenkins_pipeline

For docker container support, uncomment docker image settings section at "generate_jenkins_pipeline.m" file, and configure a valid MatlabLaunchCmd, MatlabStartupOptions and AddBatchStartupOption, RunnerType and ImageTag properties.

If you want to run the root job in container also, add the docker.image wrapper as in the example below.

```
withCredentials([string( credentialsId: 'MLM_LICENSE_TOKEN_SECRET',variable: 'mlm_license_token')]) {
    env.MLM_LICENSE_TOKEN = mlm_license_token;
}

def pipelineGenerationPath = "${env.MW_RELATIVE_PROJECT_PATH}${env.MW_PIPELINE_GEN_DIRECTORY}";
stage('Pipeline Generation'){
    cleanWs();def scmVars=checkout scm;
    docker.image('<Full Image Name>').inside("<Optional Containers Arguments>") {
        // Loading pipeline utilities script
        ...
    }
}
```