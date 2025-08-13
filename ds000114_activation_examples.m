%% ds000114_activation_examples.m
% Task-based activation visualization for ds000114
% ------------------------------
clear; clc;

%% === Set base paths ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis';
data_folder = 'ds000114-1.0.2';

%% === Task and event files ===
task = 'fingerfootlips';
events_file = fullfile(github_local_path, data_folder, ...
    sprintf('task-%s_events.tsv', task));

if ~isfile(events_file)
    error('Events file not found: %s', events_file);
end

events = readtable(events_file, 'FileType', 'text', 'Delimiter', '\t');

%% === Parameters ===
TR = 2.5; % seconds
num_timepoints = 184; % for this task
condition_names = unique(events.trial_type);

%% === Loop over subjects ===
for subjNum = 1:10
    subjID = sprintf('sub-%02d', subjNum);
    fprintf('\n=== Processing %s ===\n', subjID);

    func_file = fullfile(github_local_path, data_folder, subjID, ...
        'ses-test', 'func', sprintf('%s_ses-test_task-%s_bold.nii', subjID, task));

    if ~isfile(func_file)
        warning('Functional file not found for %s. Skipping...', subjID);
        continue;
    end

    bold_data = double(niftiread(func_file)); % X x Y x Z x T
    [X,Y,Z,T] = size(bold_data);
    fprintf('Data size: [%d %d %d %d]\n', X,Y,Z,T);

    % Preallocate mean activation maps
    mean_maps = zeros(X,Y,Z,length(condition_names));

    % --- Loop over conditions ---
    for c = 1:length(condition_names)
        cond = condition_names{c};
        onsets = events.onset(strcmp(events.trial_type, cond));
        durations = events.duration(strcmp(events.trial_type, cond));

        % Compute which timepoints correspond to each event
        time_idx = false(T,1);
        for k = 1:length(onsets)
            start_tp = max(1, round(onsets(k)/TR)+1);
            end_tp   = min(T, round((onsets(k)+durations(k))/TR)+1);
            time_idx(start_tp:end_tp) = true;
        end

        % Average across selected timepoints
        mean_maps(:,:,:,c) = mean(bold_data(:,:,:,time_idx), 4);
    end

    %% === Display middle slice for each condition ===
    zslice = round(Z/2);
    f = figure('Name', sprintf('%s - %s activation', subjID, task), 'Visible','off');

    for c = 1:length(condition_names)
        subplot(2,2,c);
        imagesc(squeeze(mean_maps(:,:,zslice,c))');
        axis image off;
        colormap hot; colorbar;
        title(condition_names{c});
    end
    sgtitle(sprintf('%s - %s activation (slice %d)', subjID, task, zslice));

    %% --- Save figure ---
    figFolder = fullfile(github_local_path,'figures','activation_maps');
    if ~exist(figFolder,'dir')
        mkdir(figFolder);
    end
    saveas(f, fullfile(figFolder, sprintf('%s_task-%s_activation.png', subjID, task)));
    close(f);
end

fprintf('✅ Activation maps computed and saved for all subjects.\n');
