% Copyright 2025 The MathWorks, Inc.

function generate_gitlab_pipeline()
    workspace = string(getenv('CI_PROJECT_DIR'));      % Reading GitLab workspace environment variable
    supportPackageRoot = string(getenv('MW_SUPPORT_PACKAGE_ROOT'));
    relativeProjectPath = string(getenv('MW_RELATIVE_PROJECT_PATH'));
    remoteBuildCacheName = string(getenv('MW_REMOTE_BUILD_CACHE_NAME'));
    pipelineGenDirectory = string(getenv('MW_PIPELINE_GEN_DIRECTORY'));

    cp = openProject(strcat(workspace,filesep,string(relativeProjectPath)));
    op = padv.pipeline.GitLabOptions;
    op.Tags = "padv_wsl_agents";
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    op.SupportPackageRoot = supportPackageRoot;
    op.GeneratedPipelineDirectory = pipelineGenDirectory;
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/ProcessAdvisorReport";
    op.RelativeProjectPath = relativeProjectPath;
    op.RemoteBuildCacheName = remoteBuildCacheName;
    op.CacheFallbackBranches = ["master", "main", "develop"];
    op.UpstreamJobName = "SPGeneration";
    op.CheckoutSubmodules = 'recursive';

    op.ArtifactServiceMode = 'azure_blob';         % network/jfrog/s3/azure_blob
    % op.NetworkStoragePath = '<Network storage path>';
    % op.ArtifactoryUrl = '<JFrog Artifactory url>';
    % op.ArtifactoryRepoName = '<JFrog Artifactory repo name>';
    % op.S3BucketName = '<AWS S3 bucket name>';
    % op.S3AwsAccessKeyID = '<AWS S3 access key id>';
    op.AzContainerName = 'padvblobcontainer';
    % op.RunnerType = "container";              % default/container
    % op.ImageTag = '<Docker Image full name>';

    % Docker image settings
    % op.MatlabLaunchCmd = "xvfb-run -a matlab -batch"; 
    op.MatlabLaunchCmd = "matlab -batch"; 
    op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    padv.pipeline.generatePipeline(op, "CIPipeline");
end