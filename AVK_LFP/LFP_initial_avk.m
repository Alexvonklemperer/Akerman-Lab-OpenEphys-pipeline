
close all

experiment_type = ['Drive'] % either 'Drive' or 'Timing';
Outputdirect = 'F:\Multi_unit Coalated\1_POM'
OutputFn = [Outputdirect '\LFP_Analysis\' experiment_type];
exp = ephys_data.data_folder;

if ~exist([OutputFn '\Figs'] , 'dir')
       mkdir([OutputFn '\Figs'])
end

if ~exist([OutputFn '\LFP_linearity'] , 'dir')
       mkdir([OutputFn '\LFP_linearity'])
end
    

window_edges = 0.05; % time in seconds before and after stimulus onset/offset to keep;
CSD_window = 0.03; % window in which CSD to be measured following stimulus
si = 0.001; % sampling interval in s

LFP_out = struct;
LFP_out.exp_type =experiment_type;

channels_All = [1:32];
channels_L4 = [6:16];%
channels_L5 = [15:32];

LFP_out.Chans_All = channels_All;
LFP_out.Chans_L4 = channels_L4;
LFP_out.Chans_L5 = channels_L5;
       

        window_edges = window_edges/si; 
        CSD_window = CSD_window/si;
        CSD_window = [window_edges+1 window_edges+1+CSD_window];
     
%% Finding Layer focus for CSD
switch experiment_type
    case 'Drive'
         disp('Experiment Drive');
         cond_data = ephys_data.conditions(2);
        case 'Timing'
         disp('Experiment TIMING');
         cond_data = ephys_data.conditions(numel(ephys_data.conditions));
    end;
        LFP_out.Cond_data = cond_data;
       
         
        [CSD_w_L4,LFP_w_L4,Sinks_w_L4,Sources_w_L4] = CSD_analysis(window_edges,CSD_window,si,channels_L4,cond_data,'Whisk',[OutputFn '\Figs\' exp],true); 
        [~,W_Sink_focus] = min(Sinks_w_L4);
         W_Sink_focus = W_Sink_focus+channels_L4(1);
        
         [CSD_l_L5,LFP_l_L5,Sinks_l_L5,Sources_l_L5] = CSD_analysis(window_edges,CSD_window,si,channels_L5,cond_data,'LED',[OutputFn '\Figs\' exp],true); 
        [~,L_Source_focus] = max(Sources_l_L5);
         L_Source_focus = L_Source_focus+channels_L5(1);
        
        LFP_out.CSD_w_L4 = CSD_w_L4;
        LFP_out.LFP_w_L4 = LFP_w_L4;
        LFP_out.Sinks_w_L4 = Sinks_w_L4;
        LFP_out.Sources_w_L4 = Sources_w_L4;
        LFP_out.CSD_l_L5 = CSD_l_L5;
        LFP_out.LFP_l_L5 = LFP_l_L5;
        LFP_out.Sinks_l_L5 = Sinks_l_L5;
        LFP_out.Sources_l_L5 = Sources_l_L5;
        LFP_out.W_Sink_focus =  W_Sink_focus;
        LFP_out.L_Source_focus =  L_Source_focus;
      
%% LFP CSD additions
    
 All_layers = struct;
 
    [CSD_W,LFP_W,~,~] = CSD_analysis(window_edges,CSD_window,si,channels_All,cond_data,'Whisk',[OutputFn '\Figs\' exp],false); 
    [CSD_L,LFP_L,~,~] = CSD_analysis(window_edges,CSD_window,si,channels_All,cond_data,'LED_WWindow',[OutputFn '\Figs\' exp],false); 
    
    clear cond_data;
    cond_data = ephys_data.conditions(1);
    
    [CSD_D,LFP_D,~,~] = CSD_analysis(window_edges,CSD_window,si,channels_All,cond_data,'Whisk',[OutputFn '\Figs\' exp],false); 
   
    CSD_combine = CSD_W+CSD_L;
    LFP_combine = LFP_W+LFP_L;
    
    LFP_diff = LFP_combine-LFP_D;
    CSD_diff = CSD_combine-CSD_D;
    
    LFP_W_reshape = reshape(LFP_W,numel(LFP_W),1);
    LFP_L_reshape = reshape(LFP_L,numel(LFP_L),1);
    LFP_D_reshape = reshape(LFP_D,numel(LFP_D),1);
    LFP_combine_reshape = reshape(LFP_combine,numel(LFP_combine),1);
    
    CSD_W_reshape = reshape(CSD_W,numel(CSD_W),1);
    CSD_L_reshape = reshape(CSD_L,numel(CSD_L),1);
    CSD_D_reshape = reshape(CSD_D,numel(CSD_D),1);
    CSD_combine_reshape = reshape(CSD_combine,numel(CSD_combine),1);
    
    All_layers.CSD_W = CSD_W;
    All_layers.LFP_W = LFP_W;
    All_layers.CSD_L = CSD_L;
    All_layers.LFP_L = LFP_L;
    All_layers.LFP_D = LFP_D;
    All_layers.CSD_D = CSD_D;
    
    LFPlinmodel = fitlm([LFP_W_reshape LFP_L_reshape],LFP_D_reshape);
    LFPlinmodel_2 = fitlm([LFP_W_reshape LFP_L_reshape],LFP_combine_reshape);
    
    CSDlinModel = fitlm([CSD_W_reshape CSD_L_reshape],CSD_D_reshape);
    CSDlinModel_2 = fitlm([CSD_W_reshape CSD_L_reshape],CSD_combine_reshape);
   
    All_layers.LFPlinmodel = LFPlinmodel;
    All_layers.CSDlinModel = CSDlinModel;
    
LFP_out.All_layers = All_layers;    
    
%% plot images
    ha = figure('Name','Whole','NumberTitle','off');
    set(gcf,'Units','normalized','Position',[.2 .1 .4 .8])% left bottom width height
    
    colormap('hot');   % set colormap
    subplot(2,2,1)
    imagesc(LFP_W);        % draw image and scale colormap to values range
    title('LFP Whisk Alone');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'LFP (mV)';
  
    subplot(2,2,2)
    imagesc(LFP_L);        % draw image and scale colormap to values range
    title('LFP Light Alone');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'LFP (mV)';
  
    subplot(2,2,3)
    imagesc(LFP_D);        % draw image and scale colormap to values range
    title('LFP Dual stim');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'LFP (mV)';
  
    subplot(2,2,4)
    imagesc(LFP_combine);        % draw image and scale colormap to values range
    title('LFP Additive');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'LFP (mV)';
  
    
    hb = figure('Name','Whole','NumberTitle','off');
    set(gcf,'Units','normalized','Position',[.2 .1 .4 .8])% left bottom width height
    
   subplot(2,2,1)
    imagesc(CSD_W);        % draw image and scale colormap to values range
    title('CSD Whisk Alone');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'CSD (uA/mm^3)';
  
    subplot(2,2,2)
    imagesc(CSD_L);        % draw image and scale colormap to values range
    title('CSD Light Alone');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'CSD (uA/mm^3)';
    
    subplot(2,2,3)
    imagesc(CSD_D);        % draw image and scale colormap to values range
    title('CSD Dual Stim');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'CSD (uA/mm^3)';
    subplot(2,2,2)
     
    subplot(2,2,4)
    imagesc(CSD_combine);        % draw image and scale colormap to values range
    title('CSD Additive');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'CSD (uA/mm^3)';
    subplot(2,2,2)
    
     hc = figure('Name','Whole','NumberTitle','off');
    set(gcf,'Units','normalized','Position',[.2 .1 .4 .8])% left bottom width height
   
     subplot(2,1,1)
    imagesc(CSD_diff);        % draw image and scale colormap to values range
    title('CSD Difference');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'CSD (uA/mm^3)';
     
    subplot(2,1,2)
    imagesc(LFP_diff);        % draw image and scale colormap to values range
    title('LFP difference (additive - dual stim)');
    xlabel('time(ms)');
    ylabel('Channel');
    c = colorbar;          % show color scale
    c.Label.String = 'LFP mV)';
       
disp('Saving...');
disp('Saving Images');
saveas(ha,[OutputFn '\LFP_linearity\' exp '_AdditionLFP.fig']);
saveas(ha,[OutputFn '\LFP_linearity\' exp '_AdditionLFP.png']);
saveas(hb,[OutputFn '\LFP_linearity\' exp '_AdditionCSD.fig']);
saveas(hb,[OutputFn '\LFP_linearity\' exp '_AdditionCSD.png']);
saveas(hc,[OutputFn '\LFP_linearity\' exp '_AdditionDiffs.fig']);
saveas(hc,[OutputFn '\LFP_linearity\' exp '_AdditionDiffs.png']);
disp('Saving Data..');
save([OutputFn '\' exp '_LFP_out.mat'],'LFP_out');
disp('saved');