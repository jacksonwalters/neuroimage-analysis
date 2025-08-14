% === Group-level statistical maps from Script #1 output ===

github_local_path = '/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis';
beta_save_folder = fullfile(github_local_path, 'data', 'beta_maps'); % match Script #1

% --- Find all beta_maps .mat files ---
beta_files = dir(fullfile(beta_save_folder, '*_beta_maps.mat'));
if isempty(beta_files)
    error('No *_beta_maps.mat files found in %s. Run Script #1 first.', beta_save_folder);
end

% --- Load first file to get dimensions and conditions ---
tmp = load(fullfile(beta_save_folder, beta_files(1).name));
beta_sample = tmp.beta_maps;
[X,Y,Z,nConditions] = size(beta_sample);
conditions = tmp.conditions;

nSubjects = numel(beta_files);
all_beta_maps = zeros(X,Y,Z,nConditions,nSubjects);
subj_names = cell(1,nSubjects);

% --- Load all subjects' beta_maps ---
for s = 1:nSubjects
    tmp = load(fullfile(beta_save_folder, beta_files(s).name));
    all_beta_maps(:,:,:,:,s) = tmp.beta_maps;
    subj_names{s} = erase(beta_files(s).name, '_beta_maps.mat');
end

% --- Run voxelwise t-tests ---
t_maps = zeros(X,Y,Z,nConditions);
p_maps = zeros(X,Y,Z,nConditions);

for c = 1:nConditions
    for x = 1:X
        for y = 1:Y
            for z = 1:Z
                yvec = squeeze(all_beta_maps(x,y,z,c,:));
                if all(yvec == 0)
                    t_maps(x,y,z,c) = NaN;
                    p_maps(x,y,z,c) = NaN;
                    continue;
                end
                [~, p, ~, stats] = ttest(yvec);
                t_maps(x,y,z,c) = stats.tstat;
                p_maps(x,y,z,c) = p;
            end
        end
    end
end

% --- Threshold maps ---
p_thresh = 0.001;
mask = p_maps < p_thresh;

% --- Save thresholded slices ---
stat_fig_folder = fullfile(github_local_path, 'figures', 'group_stats');
if ~exist(stat_fig_folder, 'dir')
    mkdir(stat_fig_folder);
end

slice = round(Z/2);
tmax = max(abs(t_maps(:)));  % for symmetric color scaling

for c = 1:nConditions
    f = figure('Visible','off');
    t_slice = squeeze(t_maps(:,:,slice,c));
    mask_slice = squeeze(mask(:,:,slice,c));

    % Mask non-significant voxels
    t_slice(~mask_slice) = NaN;

    imagesc(t_slice');
    axis image off;
    colormap jet;
    colorbar;
    caxis([-tmax tmax]);  % symmetric scaling
    title(sprintf('Group t-map: %s (p<%g)', conditions{c}, p_thresh));
    
    % Save figure
    saveas(f, fullfile(stat_fig_folder, sprintf('group_tmap_%s.png', conditions{c})));
    close(f);
end

fprintf('✅ Group statistical maps saved in %s\n', stat_fig_folder);
