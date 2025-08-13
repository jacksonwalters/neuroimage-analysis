% === Set base path and data folder ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis';
data_folder = 'ds000114-1.0.2';
full_data_path = fullfile(github_local_path, data_folder);

% --- Preallocate accumulators ---
FA_all = [];
AD_all = [];
RD_all = [];
MD_all = [];

% Loop over subjects
for subjNum = 1:10
    subjID = sprintf('sub-%02d', subjNum);  % sub-01, sub-02, etc.
    fprintf('\n=== Processing %s ===\n', subjID);

    % --- Load DWI ---
    dwiFile = fullfile(full_data_path, subjID, 'ses-retest', 'dwi', ...
        sprintf('%s_ses-retest_dwi.nii', subjID));
    bvalFile = fullfile(full_data_path, 'dwi.bval');
    bvecFile = fullfile(full_data_path, 'dwi.bvec');

    if ~isfile(dwiFile)
        warning('DWI file not found for %s. Skipping...', subjID);
        continue;
    end

    dwiData = niftiread(dwiFile);
    dwiInfo = niftiinfo(dwiFile);
    bvals = dlmread(bvalFile);
    bvecs = dlmread(bvecFile);

    [X,Y,Z,N] = size(dwiData);
    z = round(Z/2); % middle slice

    % --- Preallocate maps ---
    FAmap = zeros(X,Y);
    ADmap = zeros(X,Y);
    RDmap = zeros(X,Y);
    MDmap = zeros(X,Y);

    % --- Build design matrix ---
    G = zeros(N,6);
    for i = 1:N
        gx = bvecs(1,i); gy = bvecs(2,i); gz = bvecs(3,i);
        G(i,:) = [gx^2, gy^2, gz^2, 2*gx*gy, 2*gx*gz, 2*gy*gz] * bvals(i);
    end

    % --- Compute maps ---
    for x = 1:X
        for y = 1:Y
            S = double(squeeze(dwiData(x,y,z,:)));
            if all(S==0), continue; end
            S0 = mean(S(bvals<50));
            if S0 <= 0, continue; end

            lnSig = log(S / S0);
            d = G \ (-lnSig);

            D = [ d(1) d(4) d(5);
                  d(4) d(2) d(6);
                  d(5) d(6) d(3) ];

            [~,eigvals] = eig(D);
            lambdas = sort(diag(eigvals),'descend');

            ADmap(x,y) = lambdas(1);
            RDmap(x,y) = mean(lambdas(2:3));
            MDmap(x,y) = mean(lambdas);
            FAmap(x,y) = sqrt(1/2) * sqrt( ((lambdas(1)-lambdas(2))^2 + ...
                                            (lambdas(1)-lambdas(3))^2 + ...
                                            (lambdas(2)-lambdas(3))^2) / ...
                                          (lambdas(1)^2 + lambdas(2)^2 + lambdas(3)^2) );
        end
    end

    % --- Accumulate for averaging ---
    FA_all = cat(3, FA_all, FAmap);
    AD_all = cat(3, AD_all, ADmap);
    RD_all = cat(3, RD_all, RDmap);
    MD_all = cat(3, MD_all, MDmap);

    % --- Save figure for this subject ---
    figFolder = fullfile(github_local_path, 'figures', 'DTI_maps');
    if ~exist(figFolder, 'dir')
        mkdir(figFolder);
    end

    f = figure('Visible','off');
    subplot(2,2,1); imagesc(FAmap'); axis image off; colormap jet; colorbar; title('FA');
    subplot(2,2,2); imagesc(ADmap'); axis image off; colormap jet; colorbar; title('AD');
    subplot(2,2,3); imagesc(RDmap'); axis image off; colormap jet; colorbar; title('RD');
    subplot(2,2,4); imagesc(MDmap'); axis image off; colormap jet; colorbar; title('MD');
    sgtitle(sprintf('%s - DTI metrics (slice %d)', subjID, z));

    saveas(f, fullfile(figFolder, sprintf('%s_DTI_maps.png', subjID)));
    close(f);
end

% === Compute group averages ===
FA_avg = mean(FA_all, 3, 'omitnan');
AD_avg = mean(AD_all, 3, 'omitnan');
RD_avg = mean(RD_all, 3, 'omitnan');
MD_avg = mean(MD_all, 3, 'omitnan');

% --- Save group average figure ---
figFolder = fullfile(github_local_path, 'figures', 'DTI_group_average');
if ~exist(figFolder, 'dir')
    mkdir(figFolder);
end

f = figure;
subplot(2,2,1); imagesc(FA_avg'); axis image off; colormap jet; colorbar; title('FA avg');
subplot(2,2,2); imagesc(AD_avg'); axis image off; colormap jet; colorbar; title('AD avg');
subplot(2,2,3); imagesc(RD_avg'); axis image off; colormap jet; colorbar; title('RD avg');
subplot(2,2,4); imagesc(MD_avg'); axis image off; colormap jet; colorbar; title('MD avg');
sgtitle('Group Average DTI metrics');

saveas(f, fullfile(figFolder, 'DTI_group_average.png'));
close(f);
