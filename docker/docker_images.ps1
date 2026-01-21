################################################################
#           r2024b_apr25
################################################################
# PowerShell script
$CONTAINER_REGISTRY = "slcicd.azurecr.io/slcheck"
$PADV_IMAGE = "padv-non-interactive"
$PADV_IMAGE_TAG = "r2024b_apr25"
$MATLAB_RELEASE = "R2024b"
$PADV_IMAGE_NAME = "${PADV_IMAGE}:${PADV_IMAGE_TAG}"

docker buildx build -f non-interactive.Dockerfile `
  --build-arg MATLAB_RELEASE=$MATLAB_RELEASE `
  --build-arg MATLAB_PRODUCT_LIST='MATLAB Simulink Simulink_Check Simulink_Design_Verifier Simulink_Report_Generator Simulink_Coder Simulink_Compiler Simulink_Test Embedded_Coder Simulink_Coverage Requirements_Toolbox CI/CD_Automation_for_Simulink_Check' `
  -t $CONTAINER_REGISTRY/$PADV_IMAGE_NAME .

docker push "$CONTAINER_REGISTRY/$PADV_IMAGE_NAME"
################################################################
#           r2024b_apr25_ci
################################################################
$CI_TAG = "ci"
$PADV_CI_IMAGE_NAME = "${PADV_IMAGE_NAME}_${CI_TAG}"

docker build -f ci-addons.Dockerfile `
    --build-arg BASE_IMAGE="$CONTAINER_REGISTRY/$PADV_IMAGE_NAME" `
    -t $CONTAINER_REGISTRY/$PADV_CI_IMAGE_NAME .

docker push "$CONTAINER_REGISTRY/$PADV_CI_IMAGE_NAME"
################################################################
#           r2024b_apr25_ci_spkg202ymmdd
################################################################
$SPKG_TAG = "spkg20250707"
$PADV_CI_SPKG_IMAGE_NAME = "${PADV_CI_IMAGE_NAME}_${SPKG_TAG}"

docker build -f spkg.copy.Dockerfile `
    --build-context spkg_src="$pwd/../matlab" `
    --build-arg BASE_IMAGE="$CONTAINER_REGISTRY/$PADV_CI_IMAGE_NAME" `
    -t $CONTAINER_REGISTRY/$PADV_CI_SPKG_IMAGE_NAME .

docker push "$CONTAINER_REGISTRY/$PADV_CI_SPKG_IMAGE_NAME"