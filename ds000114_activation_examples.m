%% === Base paths ===
github_local_path = '/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis';
data_folder = 'ds000114-1.0.2';
full_data_path = fullfile(github_local_path, data_folder);

%% --- Canonical HRF function ---
function hrf = canonical_hrf(TR)
    dt = TR;
    t = 0:dt:32;  % time vector in seconds

    peak1 = 6;       % main peak
    undershoot = 16; % undershoot
    p_u_ratio = 1/6; % ratio

    h1 = (t.^(peak1-1) .* exp(-t)) / factorial(peak1-1);
    h2 = (t.^(undershoot-1) .* exp(-t)) / factorial(undershoot-1);

    hrf = h1 - p_u_ratio*h2;
    hrf = hrf / max(hrf); % normalize
end

%% --- Task and parameters ---
task_name = 'task-fingerfootlips';
TR = 2.5;            % seconds
subj_list = 1:10;

all_beta_maps = [];  % accumulate for group average

%% --- Loop over subjects ---
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
    bold_data = double(niftiread(func_file));  % X x Y x Z x T
    [X,Y,Z,T] = size(bold_data);

    % --- Load events ---
    events_file = fullfile(full_data_path, sprintf('%s_events.tsv', task_name));
    if ~isfile(events_file)
        warning('Events file not found for %s. Skipping...', subjID);
        continue;
    end
    events = readtable(events_file, 'FileType', 'text', 'Delimiter', '\t');

    % --- Identify conditions ---
    conditions = unique(events.trial_type);  % adjust column if necessary
    nConditions = numel(conditions);
    Xdesign = zeros(T, nConditions);

    % --- HRF ---
    hrf = canonical_hrf(TR);

    % --- Build design matrix per condition ---
    for c = 1:nConditions
        idx = strcmp(events.trial_type, conditions{c});
        stim_vector = zeros(T,1);
        for e = find(idx)'
            onset_idx = round(events.onset(e)/TR) + 1;
            duration_idx = round(events.duration(e)/TR);
            stim_vector(onset_idx:min(onset_idx+duration_idx-1,T)) = 1;
        end
        Xdesign(:,c) = conv(stim_vector, hrf, 'same');
    end

    % Add intercept
    Xdesign = [Xdesign, ones(T,1)];

    % --- Fit GLM voxelwise ---
    beta_maps = zeros(X,Y,Z,nConditions);
    for x = 1:X
        for y = 1:Y
            for z = 1:Z
                yvec = squeeze(bold_data(x,y,z,:));
                if all(yvec==0), continue; end
                b = Xdesign\yvec;  % least squares
                beta_maps(x,y,z,:) = b(1:nConditions);
            end
        end
    end

    % --- Save as PNG images ---
    subj_fig_folder = fullfile(github_local_path, 'figures', 'activation_maps');
    if ~exist(subj_fig_folder, 'dir')
        mkdir(subj_fig_folder);
    end

    for c = 1:nConditions
        f = figure('Visible','off');
        slice = round(Z/2);  % middle slice
        imagesc(beta_maps(:,:,slice,c)'); 
        axis image off; 
        colormap jet; 
        colorbar; 
        title(sprintf('%s - %s', subjID, conditions{c}));
        saveas(f, fullfile(subj_fig_folder, sprintf('%s_%s_beta.png', subjID, conditions{c})));
        close(f);
    end

    % Accumulate for group average
    all_beta_maps = cat(5, all_beta_maps, beta_maps);
end

%% --- Group average ---
group_avg = mean(all_beta_maps,5,'omitnan');

for c = 1:nConditions
    f = figure('Visible','off');
    slice = round(Z/2);
    imagesc(group_avg(:,:,slice,c)');
    axis image off; colormap jet; colorbar;
    title(sprintf('Group average - %s', conditions{c}));
    saveas(f, fullfile(subj_fig_folder, sprintf('group_avg_%s_beta.png', conditions{c})));
    close(f);
end

fprintf('✅ All beta maps and group averages saved as PNGs.\n');
