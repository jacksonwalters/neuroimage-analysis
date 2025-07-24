% === Set base path and data folder ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/'; % local path for GitHub
github_repository_name = 'neuroimage-analysis'; %github repository name
data_folder = 'ds000114-1.0.2'; %from the shell script
sample_data_folder = 'sample_data';

%option 1: load sample data from data directory inside github repository
local_data_path = fullfile(github_local_path,github_repository_name,sample_data_folder); %optional: full local data path

dwiFile = fullfile(github_local_path, github_repository_name, 'sample_data', 'sub-01_ses-retest_dwi.nii');
dwiData = niftiread(dwiFile);    % size: X x Y x Z x Nvols
dwiInfo = niftiinfo(dwiFile);

size(dwiData)

% pick a middle slice in Z
slice = round(size(dwiData,3)/2);  % ~36
% pick a B0 volume (often the first one)
vol = 1;

figure;
imagesc(dwiData(:,:,slice,vol));
axis image off;
colormap gray;
title(sprintf('DWI slice %d, volume %d', slice, vol));

for v = 1:size(dwiData,4)
    imagesc(dwiData(:,:,slice,v));
    axis image off;
    colormap gray;
    title(sprintf('DWI slice %d, volume %d', slice, v));
    drawnow;
    pause(0.05);
end

dwiInfo % show the whole struct

bvalFile = fullfile(github_local_path, github_repository_name, data_folder, 'dwi.bval');
bvecFile = fullfile(github_local_path, github_repository_name, data_folder, 'dwi.bvec');

bvals = dlmread(bvalFile);   % 1 x N
bvecs = dlmread(bvecFile);   % 3 x N

size(bvals)   % expect [1 71]
size(bvecs)   % expect [3 71]

% === Compute diffusion tensors for single voxel === 

% Build design matrix from bvecs and bvals
G = zeros(length(bvals), 6);
for i = 1:length(bvals)
    gx = bvecs(1,i); gy = bvecs(2,i); gz = bvecs(3,i);
    G(i,:) = [gx^2, gy^2, gz^2, 2*gx*gy, 2*gx*gz, 2*gy*gz] * bvals(i);
end

% pick a voxel (for testing)
x = 64; y = 64; z = 36;
S = double(squeeze(dwiData(x,y,z,:)));   % 71 x 1 vector
S0 = mean(S(bvals<50));  % approximate b0 using low-b volumes
lnSig = log(S / S0);     % log signal ratios

% Solve least squares: G * d = -lnSig
d = G \ (-lnSig);  % 6 coefficients

% Rebuild diffusion tensor
D = [ d(1) d(4) d(5);
      d(4) d(2) d(6);
      d(5) d(6) d(3) ];

% Eigen-decomposition
[eigvecs, eigvalsMat] = eig(D);
lambdas = sort(diag(eigvalsMat),'descend'); % λ1≥λ2≥λ3

AD = lambdas(1);
RD = (lambdas(2)+lambdas(3))/2;
MD = mean(lambdas);
FA = sqrt(1/2) * sqrt(( (lambdas(1)-lambdas(2))^2 + (lambdas(1)-lambdas(3))^2 + (lambdas(2)-lambdas(3))^2 ) ...
                      / (lambdas(1)^2 + lambdas(2)^2 + lambdas(3)^2));

fprintf('Voxel (%d,%d,%d): AD=%.4f, RD=%.4f, MD=%.4f, FA=%.4f\n',x,y,z,AD,RD,MD,FA);

%=== compute diffusion tensors for 2d array of voxels ===

% Pick a slice in Z
z = 36;
[X,Y,~,N] = size(dwiData);

% Preallocate output maps
FAmap = zeros(X,Y);
ADmap = zeros(X,Y);
RDmap = zeros(X,Y);
MDmap = zeros(X,Y);

% Build design matrix G once
G = zeros(N,6);
for i = 1:N
    gx = bvecs(1,i); gy = bvecs(2,i); gz = bvecs(3,i);
    G(i,:) = [gx^2, gy^2, gz^2, 2*gx*gy, 2*gx*gz, 2*gy*gz] * bvals(i);
end

% Loop over voxels in the slice
for x = 1:X
    for y = 1:Y
        S = double(squeeze(dwiData(x,y,z,:)));  % signal for all volumes
        if all(S==0), continue; end  % skip background

        % Estimate S0 from low-b
        S0 = mean(S(bvals<50));
        if S0 <= 0, continue; end

        lnSig = log(S / S0);

        % Solve for tensor elements
        d = G \ (-lnSig);

        D = [ d(1) d(4) d(5);
              d(4) d(2) d(6);
              d(5) d(6) d(3) ];

        % Eigenvalues
        [~,eigvals] = eig(D);
        lambdas = sort(diag(eigvals),'descend');

        % Store values
        ADmap(x,y) = lambdas(1);
        RDmap(x,y) = (lambdas(2)+lambdas(3))/2;
        MDmap(x,y) = mean(lambdas);
        FAmap(x,y) = sqrt(1/2) * sqrt( ((lambdas(1)-lambdas(2))^2 + (lambdas(1)-lambdas(3))^2 + (lambdas(2)-lambdas(3))^2) ...
                            / (lambdas(1)^2 + lambdas(2)^2 + lambdas(3)^2) );
    end
end

% === Display the maps ===
figure; 
subplot(2,2,1); imagesc(FAmap'); axis image off; colormap jet; colorbar; title('FA');
subplot(2,2,2); imagesc(ADmap'); axis image off; colormap jet; colorbar; title('AD');
subplot(2,2,3); imagesc(RDmap'); axis image off; colormap jet; colorbar; title('RD');
subplot(2,2,4); imagesc(MDmap'); axis image off; colormap jet; colorbar; title('MD');
sgtitle(sprintf('DTI metrics at slice %d', z));

%=== save the maps as PNG or TIFF ===

f = figure;
subplot(2,2,1); imagesc(FAmap'); axis image off; colormap jet; colorbar; title('FA');
subplot(2,2,2); imagesc(ADmap'); axis image off; colormap jet; colorbar; title('AD');
subplot(2,2,3); imagesc(RDmap'); axis image off; colormap jet; colorbar; title('RD');
subplot(2,2,4); imagesc(MDmap'); axis image off; colormap jet; colorbar; title('MD');
sgtitle(sprintf('DTI metrics at slice %d', z));

saveas(f, fullfile(github_local_path, github_repository_name, 'figures', 'DTI_maps.png'));
%exportgraphics(f, fullfile(github_local_path, github_repository_name, 'DTI_maps.png'), 'Resolution',300);
