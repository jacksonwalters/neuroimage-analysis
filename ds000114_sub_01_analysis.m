%load data file in which you downloaded from the shell script
funcFile = '/Users/jacksonwalters/Documents/GitHub/ds000114-1.0.2/sub-01/ses-retest/func/sub-01_ses-retest_task-fingerfootlips_bold.nii';

%use niftiread to read in the 4d data
funcData = niftiread(funcFile);  % 4D array
funcInfo = niftiinfo(funcFile);  % metadata struct

%print the dimensions of the 4d array
size(funcData)

%grab a slice and display it
slice = 20; tp = 10;
figure;
imagesc(funcData(:,:,slice,tp));
axis image off; colormap gray;
title(sprintf('Slice %d @ timepoint %d', slice, tp));

%loop through the timepoints to make a quick animation
slice = 20;
for tp = 1:size(funcData,4)
    imagesc(funcData(:,:,slice,tp));
    axis image off; colormap gray;
    title(sprintf('Timepoint %d', tp));
    pause(0.05); % adjust speed
end

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

%working with anatomical data
anatFile = '/Users/jacksonwalters/Documents/GitHub/ds000114-1.0.2/sub-01/ses-retest/anat/sub-01_ses-retest_T1w.nii';
anatData = niftiread(anatFile);
figure;
imagesc(anatData(:,:,slice));
axis image off; colormap gray;
title('Anatomical T1');
