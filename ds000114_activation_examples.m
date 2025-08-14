% === Set base path and data folder ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis';
data_folder = 'ds000114-1.0.2';
full_data_path = fullfile(github_local_path, data_folder);

%% --- Canonical HRF function ---
function hrf = canonical_hrf(TR)
    dt = TR;
    t = 0:dt:32;  
    peak1 = 6; undershoot = 16; p_u_ratio = 1/6;
    h1 = (t.^(peak1-1) .* exp(-t)) / factorial(peak1-1);
    h2 = (t.^(undershoot-1) .* exp(-t)) / factorial(undershoot-1);
    hrf = h1 - p_u_ratio*h2;
    hrf = hrf / max(hrf);
end

%% --- Task and events ---
task_name = 'task-fingerfootlips';
TR = 2.5;  
subj_list = 1:10;

% Directories
beta_save_folder = fullfile(github_local_path, 'data', 'beta_maps');
subj_fig_folder = fullfile(github_local_path, 'figures', 'activation_maps');
if ~exist(beta_save_folder, 'dir'), mkdir(beta_save_folder); end
if ~exist(subj_fig_folder, 'dir'), mkdir(subj_fig_folder); end

all_beta_maps = [];

for subjNum = subj_list
    subjID = sprintf('sub-%02d', subjNum);
    fprintf('\n=== Processing %s ===\n', subjID);

    % --- Load functional data ---
    func_file = fullfile(full_data_path, subjID, 'ses-test', 'func', ...
        sprintf('%s_ses-test_%s_bold.nii', subjID, task_name));
    if ~isfile(func_file)
        warning('Functional file not found for %s. Skipping...', subjID);
        continue;
    end
    bold_data = double(niftiread(func_file));  
    [X,Y,Z,T] = size(bold_data);

    % --- Load events ---
    events_file = fullfile(full_data_path, sprintf('%s_events.tsv', task_name));
    if ~isfile(events_file)
        warning('Events file not found. Skipping %s...', subjID);
        continue;
    end
    events = readtable(events_file, 'FileType', 'text', 'Delimiter', '\t');

    % --- Conditions ---
    conditions = unique(events.trial_type);
    nConditions = length(conditions);

    % --- Build design matrix ---
    Xdesign = zeros(T, nConditions);
    hrf = canonical_hrf(TR);

    for c = 1:nConditions
        stim_vector = zeros(T,1);
        cond_events = events(strcmp(events.trial_type, conditions{c}), :);
        for e = 1:height(cond_events)
            onset_idx = round(cond_events.onset(e)/TR) + 1;
            duration_idx = round(cond_events.duration(e)/TR);
            stim_vector(onset_idx:onset_idx+duration_idx-1) = 1;
        end
        Xdesign(:,c) = conv(stim_vector, hrf, 'same');
    end
    Xdesign = [Xdesign, ones(T,1)];

    % --- Fit GLM ---
    beta_maps = zeros(X,Y,Z,nConditions);
    for x = 1:X
        for y = 1:Y
            for z = 1:Z
                yvec = squeeze(bold_data(x,y,z,:));
                if all(yvec==0), continue; end
                b = Xdesign\yvec;
                beta_maps(x,y,z,:) = b(1:nConditions);
            end
        end
    end

    % --- Save beta maps for later use ---
    save(fullfile(beta_save_folder, sprintf('%s_beta_maps.mat', subjID)), ...
         'beta_maps', 'conditions', 'TR', '-v7.3');

    % --- Save figure for quick view ---
    f = figure('Visible','off');
    slice = round(Z/2);
    for c = 1:nConditions
        subplot(1,nConditions,c);
        imagesc(beta_maps(:,:,slice,c)');
        axis image off; colormap jet; colorbar;
        title(conditions{c});
    end
    sgtitle(subjID);
    saveas(f, fullfile(subj_fig_folder, sprintf('%s_all_conditions_beta.png', subjID)));
    close(f);

    all_beta_maps = cat(5, all_beta_maps, beta_maps);
end

%% --- Group average ---
group_avg = mean(all_beta_maps,5,'omitnan');
f = figure('Visible','off');
slice = round(Z/2);
for c = 1:nConditions
    subplot(1,nConditions,c);
    imagesc(group_avg(:,:,slice,c)');
    axis image off; colormap jet; colorbar;
    title(conditions{c});
end
sgtitle('Group average');
saveas(f, fullfile(subj_fig_folder, 'group_avg_all_conditions_beta.png'));
close(f);

fprintf('✅ Beta maps saved to %s and PNGs saved to %s.\n', beta_save_folder, subj_fig_folder);
