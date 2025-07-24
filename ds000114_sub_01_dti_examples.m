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
