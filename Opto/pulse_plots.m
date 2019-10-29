function pulse_data = pulse_plots(ephys_data, channels, resp_win, psth_bins, artifact_win)
% function pulse_data = pulse_plots(EPHYS_DATA), OR:
% function pulse_data = pulse_plots(DATA_FOLDER)
% 
% FURTHER OPTIONS:
% function pulse_data = pulse_plots(EPHYS_DATA, CHANNELS, RESP_WIN, PSTH_BINS, ARTIFACT_WIN)
% function pulse_data = pulse_plots(DATA_FOLDER, CHANNELS, RESP_WIN, PSTH_BINS, ARTIFACT_WIN)
% 
% Visualise data and extract key measures from opto 'pulse' experiment, in which
% a short light pulse is delivered each trial, at different intensities.
% 
% This function can handle both single interleaved experiments and multi-file
% sequential experiments:
% 
% If given data structure EPHYS_DATA as input, this function expects responses 
% to all intensities to be collected in an interleaved manner in this single experiment.
% 
% Provide DATA_FOLDER - the full file path to the folder that contains *only* 
% the data for the same duration light pulse at different intensities to analyse cases 
% where responses to different intensities are collected sequentially in separate 
% experiments (e.g. when using the laser where intensity has to be set manually). 
% The function will then load these in sequence and organise them by light intensity.
% 
% This function will plot the following:
% 
% Figure 1: Raster plots for all light intensities
% Figure 2: PSTHs for all light intensities
% Figure 3: Spike density plots for all intensities
% Figure 4: Superimposed PSTHs for all intensities
% Figure 5: Binned spike rate for all intensities, showing all trials
% Figure 6: Plots of opto intensity vs. binned spike rate, peak spike rate,
%           and peak spike time
% 
% REQUIRED INPUTS:
% 
% EPHYS_DATA: EPHYS_DATA structure as generated by preprocess_multiunit, containing
% spike data and metadata for a 'Pulse' type experiment.
% 
% OR:
% 
% DATA_FOLDER: Full file path to a folder containing the multiple files for a
% sequentially collected pulse experiment, 
% 
% 
% OPTIONAL:
% 
% CHANNELS:     Specify which channels, e.g. [1:8]; Default is ':' (all). 
% RESP_WIN:     Window for assessing spiking response; Default is [0.007 0.030].
% PSTH_BINS:    Bins for PSTH and spike density plots; Default is [-0.05:0.001:0.2]
% ARTIFACT_WIN: To remove potential artifacts, spike times in this window are 
%               set to NaN. Default is [-0.001 0.007].
% 
% OUTPUT: a data structure PULSE_DATA with fields:
%
% % General experiment info 
% pulse_data.data_folder             = ephys_data.data_folder;
% 
% % Function input arguments
% pulse_data.channels                = channels;
% pulse_data.resp_win                = resp_win;
% pulse_data.psth_bins               = psth_bins;
% pulse_data.bin_size                = mean(diff(psth_bins));
% pulse_data.artifact_win            = artifact_win;
% 
% % Experiment parameters
% pulse_data.opto_powers             = opto_powers;
% pulse_data.opto_onset              = cond_data(end).LED_onset;
% pulse_data.opto_duration           = cond_data(end).LED_duration(end);
% 
% % Experimental measures
% pulse_data.binned_rate_by_trial    = spike_rate_by_power;
% pulse_data.peak_rate_by_trial      = spike_peak_by_power;
% pulse_data.peak_time_by_trial      = peak_time_by_power;
% 
% pulse_data.spont_rate              = mean_spont_rate;
% pulse_data.spont_rate_std          = std_spont_rate;
% 
% pulse_data.psth_counts            	= psth_by_power;
% pulse_data.spike_density_counts  	= spike_density_counts;
% 
% % Stats
% pulse_data.corr_binned_rate_mean  	= mean(corr_spike_rate_by_power);
% pulse_data.corr_binned_rate_median	= median(corr_spike_rate_by_power);
% pulse_data.binned_rate_std         = std(corr_spike_rate_by_power);
% pulse_data.binned_rate_p           = binned_rate_p;
% pulse_data.binned_rate_rank_p      = binned_rate_rank_p;
% 
% pulse_data.corr_peak_rate_mean   	= mean(corr_spike_peak_by_power);
% pulse_data.corr_peak_rate_median 	= median(corr_spike_peak_by_power);
% pulse_data.peak_rate_std           = std(corr_spike_peak_by_power);
% pulse_data.peak_rate_p             = peak_rate_p;
% pulse_data.peak_rate_rank_p        = peak_rate_rank_p;


%% Some hardcoded variables; consider whether they should be inputs?

smoothing               = 1;    % smoothing on superimposed PSTHs
color_max_percentile    = .5;   % reduces colour range on spike density plots such that the highest colour_max_percentile doesn't influence the colour range
lowest_power            = 1;    % default intensity value for any conditions where LED signal was too low to register 

%% Check for inputs and set defaults

% Default to all channels
if nargin < 2 || isempty(channels)
    channels        = ':';
end

% Default to resp win from 6ms (after any artifacts) to 30ms (should capture
% most of the direct stimulus-driven activity
if nargin < 3 || isempty(resp_win)
    resp_win        = [0.007 0.030];
end

% Default PSTH range; 300ms post stimulus should capture even long-tailed responses
if nargin < 4 || isempty(psth_bins)
    psth_bins       = [-0.05:0.001:0.2];
end

% Set any spikes during this window to NaN; -0.001 to 0.006 is where any piezo artifacts
% may occur
if nargin < 5
    artifact_win    = [-0.002 0.007];
end

plot_win        = [psth_bins(1) psth_bins(end)];
psth_bin_size   = mean(diff(psth_bins));

%% Data loading / unpacking

if ischar(ephys_data)
    data_dir        = ephys_data;
    folder_files    = dir([data_dir filesep '*.mat']); % read .mat files from folder
    cond_data       = [];
    for a = 1:length(folder_files)
        
        this_file       = folder_files(a).name;
        full_filenm     = fullfile(data_dir, this_file);
        
        disp(['Loading ' this_file]);
        load(full_filenm);  % this should load variable 'ephys_data' and'
        
        cond_data   = [cond_data ephys_data.conditions];
        cond_data(a).LED_power = ephys_data.parameters.LED_power;
    end
else
    cond_data       = ephys_data.conditions;
end

% get opto powers for each condition; replace any NaNs with a minimum power value
opto_powers     = [cond_data(:).LED_power]';
opto_powers(isnan(opto_powers)) = lowest_power;

% if any powers were NaN and replaced with a minimum nr, powers and conditions struct
% will not be in ascending order; fix:
[opto_powers]           = unique(opto_powers);
cond_data_powers      	= [cond_data.LED_power];
cond_data_powers(isnan(cond_data_powers)) = lowest_power;

% What is the onset of the opto stimulus (this should be the same for all conditions in this experiment type)
opto_onset              = nanmedian([cond_data.LED_onset]);
n_powers                = length(opto_powers);

%% Loop to get spike data and make plots for each laser power

% Pre-make figures
raster_fig          = figure;
set(gcf,'Units','normalized','Position',[.3 .1 .4 .9],'PaperPositionMode','auto')
psth_fig            = figure;
set(gcf,'Units','normalized','Position',[.3 .1 .4 .9],'PaperPositionMode','auto')
spike_density_fig   = figure;
set(gcf,'Units','normalized','Position',[.3 .1 .4 .9],'PaperPositionMode','auto')

for b = 1:n_powers
    this_power                  = opto_powers(b);
    q_power                     = cond_data_powers == this_power;
    
    power_inds                  = find(q_power);
    spikes                      = [];
    for c = 1:length(power_inds)
        
        these_spikes                = cond_data(power_inds(c)).spikes;

        spikes(1:size(these_spikes,1),size(spikes,2)+(1:size(these_spikes,2)),1:size(these_spikes,3)) = these_spikes;
        
    end
    spikes(spikes == 0)     = NaN; % Default var gets padded with zeros; change padding zeros to NaN
    
    spont_spikes            = spikes;
    spikes                  = spikes - opto_onset;
    
    n_trials                = size(spikes,2);
    
    q_artifact            	= spikes > artifact_win(1) & spikes < artifact_win(2);
    
    spikes(q_artifact)    	= NaN;

    %% Quantify spiking response

    trial_mask(1:n_trials,b)                                        = 1;
    
    % Binned spike rate
    spike_rate_by_power(1:n_trials,b)                               = spike_rate_by_trial(spikes, resp_win);
    
    % Peak spike rate and time
    [spike_peak_by_power(1:n_trials,b), peak_time_by_power(1:n_trials,b)]   = peak_ROF_by_trial(spikes, resp_win);
    
    % Spontaneous spike rate
    spont_rate_by_power(1:n_trials,b)                               = spike_rate_by_trial(spont_spikes, resp_win);
    
    % Spontaneous spike peak and time
    spont_peak_by_power(1:n_trials,b)                               = peak_ROF_by_trial(spont_spikes, resp_win);
    
    %% PSTH and spike density counts and plots
    % raster plot
    figure(raster_fig)
    subplot(n_powers,1,b)
    raster_plot(spikes,2);
    xlim([psth_bins(1) psth_bins(end)])
    fixplot
    set(gca,'FontSize',12)
    title(['Raster plot for opto power = ' num2str(opto_powers(b))])
    
    % Spike density counts, channels x time
    figure(spike_density_fig)
    subplot(n_powers,1,b)
    [~, spike_density_counts(:,:,b)]                    = spike_density_plot(spikes,1,psth_bins);
    set(gca,'FontSize',12)
    title(['Spike density for opto power = ' num2str(opto_powers(b))])
    
    % PSTH_counts
    figure(psth_fig)
    subplot(n_powers,1,b)
    [~, psth_by_power(:,b)]                           	= psth(spikes, psth_bins);
    fixplot
    set(gca,'FontSize',12)
    title(['PSTH for opto power = ' num2str(opto_powers(b))])
    
end

spike_rate_by_power(~trial_mask)    = NaN;
spike_peak_by_power(~trial_mask)    = NaN;
peak_time_by_power(~trial_mask)     = NaN;
spont_rate_by_power(~trial_mask)    = NaN;
spont_peak_by_power(~trial_mask)    = NaN;

%% Some figure aesthetic fixes
figure(psth_fig)
subplot_equal_y
figure(spike_density_fig)
subplot_equal_clims([0 robust_max(spike_density_counts(:), color_max_percentile)])

%%

mean_spont_rate             = nanmean(spont_rate_by_power(:));
std_spont_rate              = nanstd(spont_rate_by_power(:));

corr_spike_rate_by_power    = spike_rate_by_power - mean_spont_rate;
corr_spike_peak_by_power    = spike_peak_by_power - mean_spont_rate;


%% Plot PSTHs

figure
plot(psth_bins(1:end-1),psth_by_power,'LineWidth',2)
title('PSTH of spikes following LED pulse')
xlabel('Post-pulse Time (s)')
ylabel('Spike count in time bin')
legend()
fixplot
xlim(plot_win)
scf

legend(num2str(opto_powers))

%% Beeswarmplot of spiking rate to show variability of responses

opto_power_cell     = {'0'};
for i = 1:n_powers
    opto_power_cell{i+1}  = num2str(opto_powers(i));
end

figure
set(gcf,'Units','normalized','Position',[.1 .3 .8 .4],'PaperPositionMode','auto')

spont_resps         = spont_rate_by_power(:);
spont_group         = ones(size(spont_resps));

power_groups        = [1:n_powers] + 1;
spike_rate_groups   = repmat(power_groups, size(spike_rate_by_power,1),1);

all_spike_rates     = [spont_resps(:); spike_rate_by_power(:)];
spike_rate_groups   = [spont_group(:); spike_rate_groups(:)];

beeswarmplot(all_spike_rates, spike_rate_groups, opto_power_cell)

title('Spike response by trial for each laser power')
xlabel('Opto power')
ylabel('Spike rate (Hz)')
fixplot
scf


%% Summary of spiking measures in errorbar plot with standard error to make overall trends easier to see than in beeswarm above

figure
set(gcf,'Units','normalized','Position',[.1 .3 .8 .4],'PaperPositionMode','auto')

subplot(1,3,1)
errorbar(opto_powers,nanmean(corr_spike_rate_by_power),serr(corr_spike_rate_by_power),'k','LineWidth',2,'MarkerSize',30)
title('Opto power vs binned spiking response')
xlabel('Opto power')
ylabel('Binned spike rate')
fixplot

subplot(1,3,2)
errorbar(opto_powers,nanmean(corr_spike_peak_by_power),serr(corr_spike_peak_by_power),'k','LineWidth',2,'MarkerSize',30)
title('Opto power vs peak spiking response')
xlabel('Opto power')
ylabel('Peak spike rate')
fixplot

subplot(1,3,3)
errorbar(opto_powers,nanmean(peak_time_by_power),serr(peak_time_by_power),'k','LineWidth',2,'MarkerSize',30)
title('Opto power vs peak spike time')
xlabel('Opto power')
ylabel('Peak spike time')
fixplot

%% Statistical comparisons (laser powers against responses in spontaneous window)

all_spont_rates     = spont_rate_by_power(:);
all_spont_peaks     = spont_peak_by_power(:);

all_spont_rates(isnan(all_spont_rates))     = [];
all_spont_peaks(isnan(all_spont_peaks))     = [];

%% start for loop here; compare only non-NaN values in each category
for i = 1:n_powers
    
    this_power_spike_rates                  = spike_rate_by_power(:,i);
    this_power_spike_peaks                  = spike_peak_by_power(:,i);
    
    [binned_rate_h(i), binned_rate_p(i)]	= ttest2(this_power_spike_rates(~isnan(this_power_spike_rates)),all_spont_rates);
    [peak_rate_h(i), peak_rate_p(i)]        = ttest2(this_power_spike_peaks(~isnan(this_power_spike_peaks)),all_spont_peaks);

    binned_rate_rank_p(i)   = ranksum(this_power_spike_rates,all_spont_rates);
    peak_rate_rank_p(i)     = ranksum(this_power_spike_peaks,all_spont_peaks);
    
end


%% Set output variable

% General experiment info 
pulse_data.data_folder              = ephys_data.data_folder;

% Function input arguments
pulse_data.channels                 = channels;
pulse_data.resp_win                 = resp_win;
pulse_data.psth_bins                = psth_bins;
pulse_data.bin_size                 = mean(diff(psth_bins));
pulse_data.artifact_win             = artifact_win;

% Experiment condition properties
pulse_data.opto_powers              = opto_powers;
pulse_data.opto_onset               = [cond_data.LED_onset];
pulse_data.opto_duration            = [cond_data.LED_duration];

% Experimental measures
pulse_data.binned_rate_by_trial     = spike_rate_by_power;
pulse_data.peak_rate_by_trial       = spike_peak_by_power;
pulse_data.peak_time_by_trial       = peak_time_by_power;

pulse_data.spont_rate               = mean_spont_rate;
pulse_data.spont_rate_std           = std_spont_rate;

pulse_data.psth_counts            	= psth_by_power;
pulse_data.spike_density_counts  	= spike_density_counts;

% Stats
pulse_data.corr_binned_rate_mean  	= nanmean(corr_spike_rate_by_power);
pulse_data.corr_binned_rate_median	= nanmedian(corr_spike_rate_by_power);
pulse_data.binned_rate_std          = nanstd(corr_spike_rate_by_power);
pulse_data.binned_rate_p            = binned_rate_p;
pulse_data.binned_rate_rank_p       = binned_rate_rank_p;

pulse_data.corr_peak_rate_mean   	= nanmean(corr_spike_peak_by_power);
pulse_data.corr_peak_rate_median 	= nanmedian(corr_spike_peak_by_power);
pulse_data.peak_rate_std            = nanstd(corr_spike_peak_by_power);
pulse_data.peak_rate_p              = peak_rate_p;
pulse_data.peak_rate_rank_p         = peak_rate_rank_p;



