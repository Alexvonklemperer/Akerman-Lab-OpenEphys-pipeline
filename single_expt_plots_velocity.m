% single experiment plots for frequency experiment

close all

experiment          = sdata(10).expt(1);

summarise_channels  = [5:11]; % include these channels
split_conditions    = [1 5 6]; % split by these conditions, summarise over others

split_plots         = [5 6]; % [4 6] works

P_whisk_stim        = 1;
A_whisk_stim        = 2;


%% Make PSTH plots split by condition

condition_mat       = experiment.condition_mat;

split_cond_mat      = condition_mat(:,split_conditions);
[split_cond_rows, indxa, cond_inds] = unique(split_cond_mat,'rows');

split_plot_mat      = condition_mat(:,split_plots);
[split_plot_rows, indxa, cond_plot_inds] = unique(split_plot_mat,'rows');

[a,b,cond_plot_inds] = unique(cond_plot_inds);

figure
set(gcf,'Units','normalized')
set(gcf,'Position',[0 .4 1 .6])
for a = 1:size(split_cond_rows,1)
    
    these_conds         = split_cond_rows(a,:);
    sum_inds            = cond_inds == a;
    
    this_whisk_psth  	= mean(experiment.whisk_win_rates(sum_inds,:,:),1);
    
    subplot(length(unique(condition_mat(:,split_plots(1)))),length(unique(condition_mat(:,split_plots(2)))),cond_plot_inds(a))
    plot(experiment.whiskwinedges(1:end-1),smooth(mean(squeeze(this_whisk_psth(:,summarise_channels,:)),1),5),'LineWidth',2)
    xlim([-.5 1])
    ylim([0 800])
    hold on
    set(gca,'LineWidth',2,'FontName','Garamond','FontSize',16)
    
end
set(gcf,'Color',[1 1 1])
subplot(length(unique(condition_mat(:,split_plots(1)))),length(unique(condition_mat(:,split_plots(2)))),1)
title(gca,'Stimulator 1')
subplot(length(unique(condition_mat(:,split_plots(1)))),length(unique(condition_mat(:,split_plots(2)))),2)
title(gca,'Stimulator 2')


%% Look at peak instantaneous firing rate between LED and no LED conditions
contrast_conds      = [1 6];
contrast_cond_mat   = condition_mat(:,contrast_conds);
[contrast_cond_rows, indxa, cond_inds] = unique(contrast_cond_mat,'rows');
contrast_rates      = [];
contrast_times      = [];
for a  = unique(cond_inds)'
    
    contrast_rates  = [contrast_rates; mean(mean(experiment.whisk_peak_rate(cond_inds == a,summarise_channels)))];
    contrast_times  = [contrast_times; mean(mean(experiment.whisk_peak_time(cond_inds == a,summarise_channels)))];
end

P_rate_LED_on       = contrast_rates(P_whisk_stim);
P_rate_LED_off      = contrast_rates(P_whisk_stim+2);
A_rate_LED_on       = contrast_rates(A_whisk_stim);
A_rate_LED_off      = contrast_rates(A_whisk_stim+2);

PA_ratio_LED_on     = P_rate_LED_on / A_rate_LED_on;
PA_ratio_LED_off    = P_rate_LED_off / A_rate_LED_off;

P_LED_onoff_ratio   = P_rate_LED_on / P_rate_LED_off;
A_LED_onoff_ratio 	= A_rate_LED_on / A_rate_LED_off;

% plotting
figure
bar_handle  = bar([P_rate_LED_on P_rate_LED_off; A_rate_LED_on A_rate_LED_off],'LineWidth',2);
set(gca,'LineWidth',2,'FontName','Garamond','FontSize',20,'FontWeight','bold')
set(gcf,'Color',[1 1 1])
title('Response size, P vs. A whisker, LED ON vs. OFF')
ylabel('Peak stimulus-evoked firing rate (Hz)')
xlabel('Whisker (1 = principal, 2 = adjacent)')
legend({'LED ON' 'LED OFF'})