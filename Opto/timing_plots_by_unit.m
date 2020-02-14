function timing_data = timing_plots_by_unit(ephys_data, units, resp_win, psth_bins, artifact_win)
% TIMING_DATA = timing_plots_by_unit(EPHYS_DATA)
% or
% TIMING_DATA = timing_plots_by_unit(EPHYS_DATA, UNITS, RESP_WIN, PSTH_BINS, ARTIFACT_WIN)
% 
% Visualise data and extract key measures from 'Timing' experiment, in which
% an optogenetic stimulus is pulsed at varying time intervals with respect to
% a whisker stimulus.
% 
% This function will plot the following:
% 
% Figure 1: Raster plots for each of the time delays
% Figure 2: Post stimulus time histograms (PSTHs) for each of the time delays
% Figure 3: Spike density plots for each of the time delays
% Figure 4: Point plots showing binned spike rate, peak spike rate and peak
%           spike time for each of the time delays
% 
% REQUIRED INPUTS:
% 
% EPHYS_DATA: EPHYS_DATA structure as generated by preprocess_multiunit, containing
% spike data and metadata for a 'Timing' type experiment.
% 
% OPTIONAL:
% 
% UNITS:        Specify which units, e.g. [1:8]; Default is ':' (all). 
% RESP_WIN:     Window for assessing spiking response; Default is [0.007 0.030].
% PSTH_BINS:    Bins for PSTH and spike density plots; Default is [-0.1:0.001:0.3]
% ARTIFACT_WIN: To remove potential artifacts, spike times in this window 
%               (with respect to whisker stim onset) are set to NaN. Default 
%               is [-0.001 0.006].
% 
% OUTPUT:
% 
% TIMING_DATA structure with fields:
% 


% Default to all units
if nargin < 2 || isempty(units)
    units        = ':';
end

% Default to resp win from 6ms (after any artifacts) to 30ms (should capture
% most of the direct stimulus-driven activity
if nargin < 3 || isempty(resp_win)
    resp_win        = [0.006 0.030];
end

% Default PSTH range; 300ms post stimulus should capture even long-tailed responses
if nargin < 4 || isempty(psth_bins)
    psth_bins       = [-0.1:0.001:0.3];
end

% Set any spikes during this window to NaN; -0.001 to 0.006 is where any piezo artifacts
% may occur
if nargin < 5
    artifact_win    = [-0.001 0.006];
end

% Hardcoded for now:
rate_kernel_size    = 0.01;
opto_resp_win       = [0.006 0.030];


%% Code execution starts here

opto_onsets             = [ephys_data.conditions(:).LED_onset];
n_delta_ts              = length(opto_onsets);

% Set up some figures
raster_plot_h         	= figure;
set(gcf,'Units','Normalized','Position',[.3 0 .4 1],'PaperPositionMode','auto')
psth_h                  = figure;
set(gcf,'Units','Normalized','Position',[.3 0 .4 1],'PaperPositionMode','auto')
density_plot_h          = figure;
set(gcf,'Units','Normalized','Position',[.3 0 .4 1],'PaperPositionMode','auto')

counter                 = 0;
for a = 1:length(ephys_data.conditions)
    
    % Fetch data for this condition
    this_cond                       = ephys_data.conditions(a);
    
    % Increment counter and find stimulus data for this condition
    counter                         = counter + 1;
    this_t_whisk                    = this_cond.whisk_onset;
    this_t_opto                     = this_cond.LED_onset;
    if isfield('whisk_stimulator','this_cond')
        this_whisker_nr                 = this_cond.whisk_stimulator;
    else
        this_whisker_nr                 = this_cond.whisk_stim_nr;
    end
    n_trials(counter)             	= this_cond.n_trials;
    
    delta_t(counter)                = this_t_opto - this_t_whisk;
    whisker_nr(counter)             = this_whisker_nr;
    opto_power(counter)             = this_cond.LED_power;
    
    % Get spike data and remove artifact spikes
    spikes                          = this_cond.spikes(units, :, :) - this_t_whisk;
    
    q_artifact                      = spikes > artifact_win(1) & spikes < artifact_win(2);
    spikes(q_artifact)              = NaN;
    
    % Binned spike rate
    [spike_rates(:,counter)]        = spike_rate_by_channel(spikes, resp_win);
    [spike_probs(:,counter)]        = spike_prob_by_channel(spikes, resp_win);
    [first_spikes(:,counter)]    	= first_spike_by_channel(spikes, resp_win);
    
    
    first_spikes_ind(:,1:n_trials(counter),counter) = first_spike_individual(spikes,resp_win);
    
    spike_rates_ind(:,1:n_trials(counter),counter)	= spike_rates_individual(spikes,resp_win);
    
    
    mean_spike_rate(counter)        = mean(spike_rates(:,counter));
    serr_spike_rate(counter)        = serr(spike_rates(:,counter));
    
    % Peak spike rate and time
    [peak_spike_rates(:,counter), peak_spike_times(:,counter)]  = peak_ROF_by_channel(spikes, resp_win, rate_kernel_size);
    
    mean_peak_spike_rate(counter)   = mean(peak_spike_rates(:,counter));
    serr_peak_spike_rate(counter)   = serr(peak_spike_rates(:,counter));
    
    mean_peak_spike_time(counter)   = mean(peak_spike_times(:,counter));
    serr_peak_spike_time(counter)   = serr(peak_spike_times(:,counter));
    
%     %% opto resp -- is this relevant?

    opto_spikes                  	= (spikes + this_t_whisk) - this_t_opto;
    opto_spike_rates(:,:,counter) 	= spike_rates_individual(opto_spikes, opto_resp_win);

    %% Figures
    
    % Raster plots
    figure(raster_plot_h)
    subplot(n_delta_ts,1,counter)
    raster_plot(spikes,1);
    xlim([min(psth_bins) max(psth_bins)])
    title(['Opto-whisk delay = ' num2str(-delta_t(counter) * 1000) 'ms'])
    ylabel('Unit number')
    set(gca,'FontName','Helvetica','FontWeight','Bold','box','off')
    
    % PSTH
    figure(psth_h)
    subplot(n_delta_ts,1,counter)
    [plot_handle, all_psth_counts(:,counter), psth_bins]  = psth(spikes, psth_bins);
    
    q_whisk_time            = psth_bins > 0 & psth_bins < 0.1;
    max_whisk_y(counter)    = max(all_psth_counts(q_whisk_time,counter));

     % Set sensible axis and labels
    title(['Opto-whisk delay = ' num2str(-delta_t(counter) * 1000) 'ms'])
    ylabel('Spike count')
    
    set(gca,'FontName','Helvetica','FontWeight','Bold','box','off')
    
    % Spike density plot
    figure(density_plot_h)
    subplot(n_delta_ts,1,counter)
    [image_handle, density_rates(:,:,counter)]     = spike_density_plot(spikes,1, psth_bins);
    ylabel('Unit number')
    
    set(gca,'FontName','Helvetica','FontWeight','Bold','box','off')
end

% set all y axes to equal
figure(psth_h)
subplot_equal_y(robust_max(max_whisk_y,30,'all') * 1.2);
axes_hs = get(gcf,'Children');
for i = 1:length(axes_hs)
    axes(axes_hs(i))
    shaded_region(resp_win,'g',0.4)
end

% Set color scaling to equal
figure(density_plot_h)
subplot_equal_clims

%% Plots of spiking response metrics

figure
set(gcf,'Units','Normalized','Position',[.1 .4 .8 .4],'PaperPositionMode','auto')

% Binned spike rate
subplot(1,3,1)
plot([delta_t(1:end-1) 0.025],spike_rates)
xlimits     = xlim;
% line([xlimits],[mean_spike_rate(end) mean_spike_rate(end)],'Color',[1 0 0],'LineWidth',2,'LineStyle',':')
xlim(xlimits)
title('Binned spike rate')
ylabel('Mean spike rate')
xlabel('Opto-whisk time delay')
fixplot
yzero

% Peak spike rate
subplot(1,3,2)
plot([delta_t(1:end-1) 0.025],peak_spike_rates)
xlimits     = xlim;
% line([xlimits],[mean_peak_spike_rate(end) mean_peak_spike_rate(end)],'Color',[1 0 0],'LineWidth',2,'LineStyle',':')
xlim(xlimits)
title('Peak spike rate')
ylabel('Peak spike rate')
xlabel('Opto-whisk time delay')
fixplot
yzero

% Peak spike time
subplot(1,3,3)
plot([delta_t(1:end-1) 0.025],peak_spike_times)
xlimits     = xlim;
% line([xlimits],[mean_peak_spike_time(end) mean_peak_spike_time(end)],'Color',[1 0 0],'LineWidth',2,'LineStyle',':')
xlim(xlimits)
title('Peak spike time')
ylabel('Peak spike time')
xlabel('Opto-whisk time delay')
fixplot
yzero

%% Spike probability and first spike time by unit (ugly)

figure
set(gcf,'Units','Normalized','Position',[.1 .4 .8 .4],'PaperPositionMode','auto')

subplot(1,2,1)
plot([delta_t(1:end-1) 0.025],spike_probs)
xlimits     = xlim;
% line([xlimits],[mean_spike_rate(end) mean_spike_rate(end)],'Color',[1 0 0],'LineWidth',2,'LineStyle',':')
xlim(xlimits)
title('Spike probability')
ylabel('Spike probability')
xlabel('Opto-whisk time delay')
fixplot
yzero

subplot(1,2,2)
plot([delta_t(1:end-1) 0.025],first_spikes)
xlimits     = xlim;
% line([xlimits],[mean_spike_rate(end) mean_spike_rate(end)],'Color',[1 0 0],'LineWidth',2,'LineStyle',':')
xlim(xlimits)
title('First spike time')
ylabel('First spike time')
xlabel('Opto-whisk time delay')
fixplot
yzero


%% Some stats on the firing rate differences compared to control

for a = 1:(length(delta_t))
    [binned_rate_h(:,a) binned_rate_p(:,a)] = ttest2(spike_rates_ind(:,:,a)',spike_rates_ind(:,:,end)');
end

for a = 1:(length(delta_t))
    [first_spike_h(:,a) first_spike_p(:,a)] = ttest2(first_spikes_ind(:,:,a)',first_spikes_ind(:,:,end)');
end

spike_prob_hits     = spike_probs .* n_trials;
spike_prob_misses  	= n_trials - spike_prob_hits;

for a = 1:(length(delta_t))
    for b = 1:size(spike_prob_hits,1)
        control_row             = [spike_prob_hits(b,end) spike_prob_misses(b,end)];
        test_row                = [spike_prob_hits(b,a) spike_prob_misses(b,a)];
        
        fisher_tab              = int32([control_row; test_row]);
        
        [h, spike_prob_p(b,a)]  = fishertest(fisher_tab);
    end
end


%% Set output variable timing_data

% Metadata
timing_data.data_folder             = ephys_data.data_folder;

% Function input data
timing_data.units                   = units;
timing_data.resp_win                = resp_win;
timing_data.artifact_win            = artifact_win;
timing_data.psth_bins               = psth_bins;
timing_data.bin_size                = mean(diff(psth_bins));

% Experiment data
timing_data.delta_t                 = delta_t;
timing_data.n_trials                = n_trials;

% Quantification data

% Spike counts
timing_data.all_psth_counts         = all_psth_counts;
timing_data.density_rates           = density_rates;

% Binned spike rates
timing_data.spike_rate              = spike_rates;
timing_data.spike_rate_by_trial     = spike_rates_ind;

timing_data.spike_rate_p            = binned_rate_p;

% Peak spike rates
timing_data.peak_spike_rates        = peak_spike_rates;

% Peak spike times
timing_data.peak_spike_times        = peak_spike_times;

% Spike probabilities
timing_data.spike_probabilities    	= spike_probs;
timing_data.spike_prob_p            = spike_prob_p;

% First spike times
timing_data.first_spike_times       = first_spikes;
timing_data.first_spikes_individual = first_spikes_ind;
timing_data.first_spike_p           = first_spike_p;

