% Copyright 2025 The MathWorks, Inc.

function generate_github_pipeline()
    op = padv.pipeline.GitHubOptions;
    op.PipelineArchitecture = "IndependentModelPipelines";
    op.GeneratorVersion = 2;
    % op.SupportPackageRoot = "/home/ahmedh/Documents/MATLAB/SupportPackages/R2025b";
    op.SupportPackageRoot = "D:/sb/bslcicd_0118/matlab";
    
    % op.RunnerLabels = "padv_linux_vm_agents";
    op.RunnerLabels = "padv_win_agents";
    op.GeneratedPipelineDirectory = "_pipelineGen_";
    op.StopOnStageFailure = true;
    op.RunprocessCommandOptions.GenerateJUnitForProcess = true;
    op.ReportPath = "$PROJECTROOT$/PA_Results/Report/ProcessAdvisorReport";
    op.RelativeProjectPath = "mainproject/level1-a/level2/ProcessAdvisorProjectReferenceExample/";
    op.RemoteBuildCacheName = "GitHub_Project_root2";
    op.CacheFallbackBranches = ["master", "main", "develop"];
    op.CheckoutSubmodules = 'recursive';

    % We can enhance the vaidation now of the options on the matlab side
    op.ArtifactServiceMode = 'azure_blob';         % network/jfrog/s3/azure_blob
    % op.NetworkStoragePath = '<Artifactory network storage path>';
    % op.ArtifactoryUrl = '<JFrog artifactory url>';
    % op.ArtifactoryRepoName = '<JFrog artifactory repo name>';
    % op.S3BucketName = '<AWS S3 bucket name>';
    % op.S3AwsAcessKeyID = '<AWS S3 access key id>';
    op.AzContainerName = 'padvblobcontainer';
    % op.RunnerType = "container";        % default/container
    % op.ImageTag = 'slcicd.azurecr.io/slcheck/padv-ci:r2024b_apr25t_ci_spkg20250802';
    
    % Docker image settings
    op.UseMatlabPlugin = false;
    op.MatlabLaunchCmd = "matlab -batch"; 
    % op.MatlabLaunchCmd = "xvfb-run -a matlab-batch";
    % op.MatlabStartupOptions = "";
    op.AddBatchStartupOption = false;
    
    padv.pipeline.generatePipeline(op, "CIPipeline");
end