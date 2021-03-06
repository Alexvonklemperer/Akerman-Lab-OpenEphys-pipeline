% check_whisk_resp_baseline

%% File I/O settings
expt_folder         = '/Volumes/Akermanlab/Joram/In_vivo_mouse_data/2019_01_11/CBLK_2019-01-11_11-26-11_1';
q_reload            = 1;

%% Visualisation settings
psth_win            = [-.2 .3];
bin_size            = [0.001];

stim_type           = 'whisk'; % 'whisk' or 'opto'

%% Responsiveness settings
spike_resp_win    	= [0.006 0.04]; % where to measure response (relative to stim onset)
spike_spont_win  	= [-1 -.1]; % where to measure spontaneous activity (relative to stim onset)

n_trials_for_drift  = 10; % number of trials on each side of recording to use for drift assessment

%% Data loading settings

% for synchronisation data:
events_chans        = [1 1 3 2]; % order of events channels: [trial, whisk, opto, whisk_stim_nr]

% for spike detection:
spike_thresh        = 4; % threshold for spike detection

% channel order for current probe:
channel_map         = [1 17 16 32 3 19 14 30 9 25 10 20 8 24 2 29 7 26 15 21 11 23 12 28 6 18 13 22 5 27 4 31];


%% Load and preprocess data

if q_reload
    ephys_data          = get_ephys_data(expt_folder,events_chans,channel_map, spike_thresh);
end

%% Unpack data

spikes              = ephys_data.conditions(1).spikes;
LFPs                = ephys_data.conditions(1).LFP_trace;

switch stim_type
    case 'whisk'
        stim_onset      = ephys_data.conditions(1).whisk_start;
    case 'opto'
        stim_onset      = ephys_data.conditions(1).opto_onset;
end

spikes              = spikes - stim_onset; % set whisk onset time to 0
LFP_timestamps      = ([1:size(LFPs,3)]/1000) - stim_onset;

%% Visualisation

figure
set(gcf,'Units','normalized','Position',[0.05 .1 .9 .3])
subplot(1,5,1)
psth(spikes,bin_size,psth_win)
fixplot

subplot(1,5,2)
spike_density_plot(spikes,1,psth_win(1):bin_size:psth_win(2))

subplot(1,5,3)
raster_plot(spikes,2)
xlim(psth_win)
fixplot

subplot(1,5,4)
plot_LFP_traces(LFPs,1,LFP_timestamps)
xlim(psth_win)
fixplot

subplot(1,5,5)
plot_LFP_traces(LFPs,1,LFP_timestamps,0.2,0.6)
xlim(psth_win)
fixplot

%% Responsiveness assessment

resp_spikes         = spikes >= spike_resp_win(1) & spikes < spike_resp_win(2);
spont_spikes        = spikes >= spike_spont_win(1) & spikes < spike_spont_win(2);

resp_spikes         = sum(resp_spikes,3);
spont_spikes        = sum(spont_spikes,3);

resp_win_size       = spike_resp_win(2) - spike_resp_win(1);
spont_win_size      = spike_spont_win(2) - spike_spont_win(1);

win_ratio           = resp_win_size / spont_win_size;

corr_spont_spikes   = spont_spikes .* win_ratio;

spont_by_trial      = mean(corr_spont_spikes,1);
mean_spont_spikes   = mean(spont_by_trial);
spont_serr_spikes   = serr(spont_by_trial);

resp_by_trial       = mean(resp_spikes,1);
mean_resp_spikes    = mean(resp_by_trial);
resp_serr_spikes    = serr(resp_by_trial);

% for drift assessment:

early_spike_resps   = resp_by_trial(1:n_trials_for_drift);
late_spike_resps    = resp_by_trial(((end-n_trials_for_drift)+1):end);

median_early        = median(early_spike_resps);
iqr_early           = iqr(early_spike_resps);
median_late         = median(late_spike_resps);

median_diff         = abs(median_early - median_late);
nonparam_zscore     = median_diff / iqr_early;

% for spont vs resp beeswarmplot:
spikes_by_trial     = [spont_by_trial(:); resp_by_trial(:)];
grouping_var        = ones(size(spikes_by_trial));
grouping_var((length(spont_by_trial)+1):end)    = 2;
labels              = {'Spontaneous' 'Evoked'};

% for baseline drift beeswarmplot
drift_spike_resps   = [early_spike_resps(:) late_spike_resps(:)];
drift_groups        = ones(size(drift_spike_resps));
drift_groups((length(early_spike_resps)+1):end)     = 2;
drift_labels        = {'Early' 'Late'};

%% Responsiveness visualisation

figure
set(gcf,'Units','normalized','Position',[0.05 .1 .9 .3])

subplot(1,4,1)
beeswarmplot(spikes_by_trial,grouping_var,labels)
fixplot
title('Spont vs evoked spikes')
ylabel('Spike count')
yzero

subplot(1,4,2)
beeswarmplot(drift_spike_resps,drift_groups,drift_labels)
fixplot
yzero
title(['Baseline z-score = ' num2str(nonparam_zscore)])
ylabel('Spike count')

subplot(1,2,2)
plot(resp_by_trial - mean_spont_spikes,'k.','MarkerSize',20)
fixplot
yzero
xlabel('Trial number')
ylabel('Spike count')
title('Spiking response over time')

