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
This image add a top layer to the non-interactive image by adding the following libraries and CLIs python3, git client, JFrog cli, Azure cli, AWS cli. This layer also clear the default docker image ENTRYPOINT value for better flexibility.

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
# 2. Configure your GitLab runner
Pipeline generation supports running padv docker images in GitLab CI using Docker executor approach. GitLab Docker executor uses Docker Engine to run each job in a separate and isolated container. To connect to Docker Engine, the executor uses:
+ The image you define in .gitlab-ci.yml.
+ The configurations you define in the runner config.toml.

For more information about GitLab Docker executor:
https://docs.gitlab.com/runner/executors/docker/

To use the Docker executor with existing runner, you must manually define Docker as the executor in config.toml and for new runner you must use gitlab-runner register --executor "docker" command to automatically define it.
> **_NOTE:_** Make sure to review the configuration for allowed_images, allowed_pull_policies and pull_policy configuration keys.

> **_NOTE:_** If you are using a MATLAB Docker image based on a Linux OS, you must configure your GitLab runner either on a Linux machine with Docker Engine installed or on a Windows machine with Docker Engine running in Linux mode. Using WSL is also an option as it is equvilant to using a Linux machine.

example runner configuration:
```
[[runners]]
  name = "runner_name"
  url = "http://gitlab.ci.local"
  id = 1
  token = "glrt-QMVANg_******"
  token_obtained_at = 2025-06-18T21:19:06Z
  token_expires_at = 0001-01-01T00:00:00Z
  [runners.docker]
    tls_verify = true
    image = "my.registry.tld:5000/alpine:latest"
    privileged = *
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = true
    volumes = ["/cache",]
    shm_size = 0
    allowed_pull_policies = ["always", "if-not-present"]
    pull_policy = "if-not-present"
    allowed_images = ["*:*", "*", "my.registry/*:*"]
    allowed_services = ["*:*"]
```

# 3. Configure your gitlab pipeline

In CI environemnts, MATLAB batch licensing token is the recommended way to license your MATLAB containers. MATLAB batch licensing token tool is already installed inside your Docker image but you need to supply the license token secrets through the container environemnt variables. We recommend saving the token secrets into your GitLab CI/CD variables section as 'MLM_LICENSE_TOKEN_SECRET' variable with visibality equal to "Masked and hidden"

The example .gitlab-ci.yml pipeline will send this token secret to the different containers automatically.

You need to set IMAGE_TAG variable at .gitlab-ci.yml variables section. This image will be used for all the pipeline jobs.

> **_NOTE:_** IMAGE_TAG variable is ignored if gitlab runner is not configured to use Docker executor.

At "generate_gitlab_pipeline.m", uncomment Docker image settings section and configure a valid MatlabLaunchCmd, MatlabStartupOptions and AddBatchStartupOption values.