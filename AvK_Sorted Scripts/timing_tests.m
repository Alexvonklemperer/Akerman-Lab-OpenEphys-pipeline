clc; clear all;
reload = 1;
animal = '2019_11_28_2'
sorted_units = 'F:\Sorted_Pom\Timing\2020_01_27_1\2020_01_27-23-Timing.mat'
multi_unit = 'F:\Multi_unit Coalated\1_POM\Timing\2020_01_27_1\2020_01_27-23-Timing.mat'

experiment_type = ['Timing'] % either 'Drive' or 'Timing';
Outputdirect = 'F:\Coalated_analysis\POM'
experiment = [animal '_timing_1'];
OutputFn = [Outputdirect experiment_type];
Layer_bounds_width = [178 241 314 273]; % L1 L2/3 L4 L5 L6

%% script starts
if ~exist([OutputFn '\Figs'] , 'dir')
       mkdir([OutputFn '\Figs'])
end;

if (reload == 1)
    load(sorted_units);
    sorted_data = ephys_data;
    clear ephys_data;
    load(multi_unit);
    MUE_data =  ephys_data;
    clear ephys_data;
end;

LFP_out = LFP_Depth(experiment_type,MUE_data,OutputFn,true);
mean_sinks = 0 - mean(LFP_out.Sinks);
[~,a] = findpeaks(0-LFP_out.Sinks,'MinPeakHeight',mean_sinks);
[~,b] = min(LFP_out.LFP_Sinks);
[~,c] = min(abs(a-b));
L4_sink = a(c)+1; % Defines the sink in Layer 4 as the Peak CSD sink closes to the LFP sink. 

Channel_depths = L4_sink

clear a b c;

Layers.L4_sink_depth = 25*L4_sink;
Layers.L4 = [L4_sink-4:L4_sink+4];
Layers.L4_depth = [int16(Layers.L4_sink_depth-Layer_bounds_width(3)/2);int16(Layers.L4_sink_depth+Layer_bounds_width(3)/2)];
Layers.L5_depth = [Layers.L4_depth(2);Layers.L4_depth(2)+Layer_bounds_width(4)];
Layers.L2_3_depth = [Layers.L4_depth(1)-Layer_bounds_width(2);Layers.L4_depth(1)+50]; % gave 50um boundry to l2/3 for overlap with upper L4?
Layers.L5 = [Layers.L4(end)+1:Layers.L4(end)+12];
Layers.L2_3 = [Layers.L4(1)-7:Layers.L4(1)+1];% gave 50um boundry to l2/3 for overlap with upper L4?
Layers.L2_3 = Layers.L2_3(Layers.L2_3>0); % only includes up to highest channel
Layers.L5 = Layers.L5(Layers.L5<33); % only includes up to lowest channel

%% Whisk and Light Responsiveness

L2_3_units = sorted_data.unit_depths < Layers.L2_3_depth(2);


resp_win            = [0.005 0.055];
opto_resp_win       = [0.006 0.055];
control_win(1)      = 0-resp_win(2);
control_win(2)      = 0-resp_win(1);
opto_control_win(1) = 0 - opto_resp_win(2);
opto_control_win(2) = 0 - opto_resp_win(1);
this_t_opto         = sorted_data.conditions(end).LED_onset; 
this_t_whisk        = sorted_data.conditions(end).whisk_onset;


spikes          = sorted_data.conditions(end).spikes(:,:,:);
spikes          = spikes - this_t_whisk;
opto_spikes     = sorted_data.conditions(end).spikes(:,:,:) - this_t_opto;
delta_t         = this_t_opto - this_t_whisk;
n_trials        =  sorted_data.conditions(end).n_trials;  

L5_MUA_Spikes   = MUE_data.conditions(end).spikes(Layers.L5,:,:);
L5_MUA_Spikes   = L5_MUA_Spikes - this_t_opto;

Whisk_Resp = Stim_Responsive(spikes,resp_win,control_win,n_trials,delta_t,true,'Whisker Stim Response',Outputdirect); % tests whether spike rate or probablity is signifactly larger following stimulus
Opto_Resp = Stim_Responsive(opto_spikes,opto_resp_win,opto_control_win,n_trials,delta_t,true,'Opto Stim Response',Outputdirect);

L5_opto_recruitment = spike_rate_in_win(L5_MUA_Spikes,opto_resp_win);
L5_opto_control = spike_rate_in_win(L5_MUA_Spikes,opto_control_win);
L5_delta_recruitment = L5_opto_recruitment - L5_opto_control;

%%
window = [0.004 0.1]
unit_of_interest = squeeze(sorted_data.conditions(6).spikes(3,:,:));
unit_of_interest = unit_of_interest - this_t_whisk;

for k = 1: n_trials
    a = find(unit_of_interest(k,:) > window(1),1,'first');
    if~isempty(a)
    first_spike(k) = unit_of_interest(k,a);
    else
    first_spike(k) = NaN;   
    end;
end;
first_spike(first_spike > window(2)) = NaN;
figure();
plot(first_spike,'*');

unit_of_interest = squeeze(sorted_data.conditions(end).spikes(3,:,:));
unit_of_interest = unit_of_interest - this_t_whisk;

for k = 1: n_trials
    a = find(unit_of_interest(k,:) > window(1),1,'first');
    if~isempty(a)
    first_spike_2(k) = unit_of_interest(k,a);
    else
    first_spike_2(k) = NaN;   
    end;end;
hold on;
first_spike_2(first_spike_2 > window(2)) = NaN;

plot(first_spike_2,'o');


h = kstest(first_spike_2);
h_2 = kstest(first_spike);
[p,h] = ranksum(first_spike,first_spike_2);
[p,stats] = vartestn([first_spike' first_spike_2']);

%{
for k = 4:7;
figure();
subplot(3,1,1);
raster_plot(sorted_data.conditions(k).spikes(2,:,:),2,0.2);
title(['Trial : ' num2str(k) ]);
xlim([0 4]);

subplot(3,1,2);
raster_plot(MUE_data.conditions(k).spikes(Layers.L5,:,:),2,0.2);
xlim([0 4]);

subplot(3,1,3)
LFP = MUE_data.conditions(k).LFP_trace(L2_3_units,:,:);
LFP = squeeze(nanmean(LFP,1));
LFP = nanmean(LFP,1);
plot(LFP);
xlim([0 4000]);

end;

%}