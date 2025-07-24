% === Set base path and data folder ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/'; % local path for GitHub
matlab_local_path = '/Users/jacksonwalters/Documents/MATLAB/'; % local path for MATLAB
github_repository_name = 'neuroimage-analysis'; %github repository name
data_folder = 'ds000114-1.0.2'; %from the shell script
sample_data_folder = 'sample_data';

%option 1: load sample data from data directory inside github repository
local_data_path = fullfile(github_local_path,github_repository_name,sample_data_folder); %optional: full local data path
funcFile = fullfile(local_data_path, 'sub-01_ses-retest_task-fingerfootlips_bold.nii');
anatFile = fullfile(local_data_path, 'sub-01_ses-retest_T1w.nii');

%option 2: build file path pointing to full dataset downloaded from the shell script
full_data_path = fullfile(github_local_path, github_repository_name, data_folder);
%funcFile = fullfile(full_data_path, 'sub-01', 'ses-retest', 'func', 'sub-01_ses-retest_task-fingerfootlips_bold.nii');
%anatFile = fullfile(full_data_path, 'sub-01', 'ses-retest', 'anat', 'sub-01_ses-retest_T1w.nii');

%use niftiread to read in the 4d functional data
funcData = niftiread(funcFile);  % 4D array
funcInfo = niftiinfo(funcFile);  % metadata struct

%use niftiread to read in the 3d anatomical data
anatData = niftiread(anatFile);
anatInfo = niftiinfo(anatFile);  % metadata struct

%print the dimensions of the 4d array
size(funcData)

%grab a slice and display it
slice = 20; time_point = 100;
figure;
imagesc(funcData(:,:,slice,time_point));
axis image off; colormap gray;
title(sprintf('Slice %d @ timepoint %d', slice, time_point));

% === Loop through time slices to create and save an animation at a fixed spatial slice ===
function animateOverTime(volume4D, sliceIndex, gifFile, delayTime)
% animateOverTime: creates a GIF animation looping over time at a fixed slice
% volume4D   = 4D data (X,Y,Z,T)
% sliceIndex = which slice to display
% gifFile    = full path for the output GIF
% delayTime  = delay (seconds) between frames

    figure;
    for tp = 1:size(volume4D,4)
        imagesc(volume4D(:,:,sliceIndex,tp));
        axis image off; colormap gray;
        title(sprintf('Timepoint %d', tp));
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [A,map] = rgb2ind(im,256);
        if tp == 1
            imwrite(A,map,gifFile,'gif','LoopCount',Inf,'DelayTime',delayTime);
        else
            imwrite(A,map,gifFile,'gif','WriteMode','append','DelayTime',delayTime);
        end
    end

    fprintf('✅ Time GIF saved as: %s\n', gifFile);
end

% === Loop through spatial slices to create and save an animation at a fixed timepoint ===
function animateOverSlices(volume3Dor4D, timePoint, gifFile, delayTime)
% animateOverSlices: creates a GIF animation looping over slices at a fixed time
% volume3Dor4D = 3D or 4D data (X,Y,Z[,T])
% timePoint    = which time index to use (ignored if 3D)
% gifFile      = full path for the output GIF
% delayTime    = delay (seconds) between frames

    % Handle both 3D and 4D data
    if ndims(volume3Dor4D) == 4
        vol = volume3Dor4D(:,:,:,timePoint);
    else
        vol = volume3Dor4D;  % already 3D
    end

    figure;
    for slice = 1:size(vol,3)
        imagesc(vol(:,:,slice));
        axis image off; colormap gray;
        title(sprintf('Slice %d', slice));
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [A,map] = rgb2ind(im,256);
        if slice == 1
            imwrite(A,map,gifFile,'gif','LoopCount',Inf,'DelayTime',delayTime);
        else
            imwrite(A,map,gifFile,'gif','WriteMode','append','DelayTime',delayTime);
        end
    end

    fprintf('✅ Slice GIF saved as: %s\n', gifFile);
end

% Animate over time (for fMRI)
gif_time = fullfile(github_local_path, github_repository_path, 'animations/fmri_time_animation.gif');
animateOverTime(funcData, 20, gif_time, 0.05);

% Animate over slices (for fMRI at timepoint 100)
gif_spatial = fullfile(github_local_path, github_repository_path, 'animations/fmri_spatial_animation.gif');
animateOverSlices(funcData, 100, gif_spatial, 0.05);

% Animate over slices (for anatomical data)
gif_anat = fullfile(github_local_path, github_repository_path, 'animations/anat_spatial_animation.gif');
animateOverSlices(anatData, 1, gif_anat, 0.05);  % anatData is 3D, timePoint ignored

% create an image of a slice of anatomical data;
figure;
imagesc(anatData(:,:,slice));
axis image off; colormap gray;
title('Anatomical T1');

%compute simple statistics
meanVol = mean(funcData, 4);
figure;
imagesc(meanVol(:,:,slice));
axis image off; colormap gray;
title('Mean signal over time');

%extract a time series from a voxel
x = 32; y = 32; z = 18;
voxelTS = squeeze(funcData(x,y,z,:));
plot(voxelTS);
xlabel('Timepoint'); ylabel('Signal');
title(sprintf('Voxel (%d,%d,%d)',x,y,z));

%begin diffusion tensor imaging computation [AD, RD, MD, FA]
dwiFile = fullfile(github_local_path, github_repository_path, 'sample_data', 'sub-01_ses-retest_dwi.nii');
dwiData = niftiread(dwiFile);    % size: X x Y x Z x Nvols
dwiInfo = niftiinfo(dwiFile);
