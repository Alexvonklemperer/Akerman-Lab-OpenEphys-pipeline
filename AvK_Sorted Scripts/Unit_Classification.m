function Unit_Classify = Unit_Classification(Directory,Date);

fn = fullfile(Directory,'Stim Response','Figures', Date);
recording_check = 0;
%% Load timing experiments

matfiles = dir(fullfile(Directory,'Timing',Date, '*.mat'));

  
    nfiles = length(matfiles);
    disp(nfiles)
    if nfiles>0
    for i = 1 : nfiles
         disp(['Loading...' matfiles(i).name]);
         load(fullfile(matfiles(i).folder, matfiles(i).name));
         LED_Powers(i) = ephys_data.conditions(1).LED_power;
    end;
        [~,p] = max(LED_Powers);
        clear i ephys_data;
        load(fullfile(matfiles(p).folder, matfiles(p).name));
        timing_ephys = ephys_data;
        recording_check = 1;
    else 
        timing_ephys = [];   
    end;
clear ephys_data LED_Powers matfiles nfiles p;

%% Load Drive experiments
matfiles = dir(fullfile(Directory,'Drive',Date, '*.mat'));

nfiles = length(matfiles);
if nfiles>0
    for i = 1 : nfiles
         disp(['Loading...' matfiles(i).name]);
        load(fullfile(matfiles(i).folder, matfiles(i).name));
        LED_Powers(i) = ephys_data.conditions(1).LED_power;
    end;
    [~,p] = max(LED_Powers);
    clear i ephys_data;
    load(fullfile(matfiles(p).folder, matfiles(p).name));
    drive_ephys = ephys_data;
    recording_check = 1;
 else
    drive_ephys = [];
end;
clear ephys_data LED_Powers matfiles nfiles p;

%% Load LED flash experiments

matfiles = dir(fullfile(Directory,'LED Powers',Date, '*.mat'));

nfiles = length(matfiles);
if nfiles>0
    for i = 1 : nfiles
         disp(['Loading...' matfiles(i).name]);
        load(fullfile(matfiles(i).folder, matfiles(i).name));
        Experiments(i) = numel(ephys_data.conditions);
    end;
    [~,p] = max(Experiments);
    clear i ephys_data;
    load(fullfile(matfiles(p).folder, matfiles(p).name)); 
   LED_Powers_Ephys = ephys_data;
   recording_check = 1;
 
 else
    LED_Powers_Ephys = [];
end;
clear ephys_data Experiments matfiles nfiles p;

if (recording_check == 1);

%% Classify units
if ~isempty(drive_ephys)
    for k =1: numel(drive_ephys.conditions);
   LED_Onsets(k) = (drive_ephys.conditions(k).LED_onset);
    end;
    i = find(LED_Onsets == 2.5,1)
   Drive_classify = Unit_Plot(drive_ephys.conditions(i),'Both',[fn '_drive'])
else
    Drive_classify = [];
end;
clear LED_Onsets;

if ~isempty(timing_ephys)
     for k =1: numel(timing_ephys.conditions);
     LED_Onsets(k) = (timing_ephys.conditions(k).LED_onset);
    end;
    i = find(LED_Onsets == 2.5,1)
   Timing_classify = Unit_Plot(timing_ephys.conditions(2),'Both',[fn '_timing']);
else
        Timing_classify = [];
end

if ~isempty(LED_Powers_Ephys)
    for k = 1: numel(LED_Powers_Ephys.conditions);
   LED_Powers(k) = (LED_Powers_Ephys.conditions(k).LED_power);
    end;
    [~,i] = max(LED_Powers)
  LED_Power_classify = Unit_Plot(LED_Powers_Ephys.conditions(i),'Opto',[fn '_Flash'])
else
    LED_Power_classify = [];
end;
clear LED_Onsets;

%% Tabulate unit Classification
if ~ isempty(timing_ephys)
Unit_Depth = timing_ephys.unit_depths;
else 
    if ~ isempty(drive_ephys)
        Unit_Depth = drive_ephys.unit_depths;
    else
        Unit_Depth = LED_Powers_Ephys.unit_depths;
    end;
end;

z =1;

if ~isempty(Drive_classify)
Light_Drive_Rate = logical(Drive_classify.Opto_Resp.Good_resp_rate');
Light_Drive_Prob = logical(Drive_classify.Opto_Resp.Good_resp_prob');
Whisk_Drive_Rate = logical(Drive_classify.Whisk_Resp.Good_resp_rate');
Whisk_Drive_Prob = logical(Drive_classify.Whisk_Resp.Good_resp_prob'); 
else
    Light_Drive_Rate = NaN*ones(numel(Unit_Depth),z);
    Light_Drive_Prob = NaN*ones(numel(Unit_Depth),z);
    Whisk_Drive_Rate = NaN*ones(numel(Unit_Depth),z);
    Whisk_Drive_Prob = NaN*ones(numel(Unit_Depth),z);
end;

if ~ isempty(LED_Power_classify);
Light_LEDFlash_Rate = logical(LED_Power_classify.Opto_Resp.Good_resp_rate');
Light_LEDFlash_Prob = logical(LED_Power_classify.Opto_Resp.Good_resp_prob');
else
    Light_LEDFlash_Rate = NaN*ones(numel(Unit_Depth),z);
    Light_LEDFlash_Prob = NaN*ones(numel(Unit_Depth),z);
end;
    
if ~isempty(Timing_classify)
    if ~isnan(Timing_classify.Opto_Resp.Good_resp_rate)
    Light_Timing_Rate =  logical(Timing_classify.Opto_Resp.Good_resp_rate');
    else
    Light_Timing_Rate = NaN*ones(numel(Unit_Depth),z);
    end;

    if ~isnan(Timing_classify.Opto_Resp.Good_resp_prob)
    Light_Timing_Prob = logical(Timing_classify.Opto_Resp.Good_resp_prob');
    else
   Light_Timing_Prob = NaN*ones(numel(Unit_Depth),z);
    end;

    if ~isnan(Timing_classify.Whisk_Resp.Good_resp_rate);
    Whisk_Timing_Rate = logical(Timing_classify.Whisk_Resp.Good_resp_rate');
    else
     Whisk_Timing_Rate = NaN*ones(numel(Unit_Depth),z);
    end;

    if ~isnan(Timing_classify.Whisk_Resp.Good_resp_prob);
    Whisk_Timing_Prob = logical(Timing_classify.Whisk_Resp.Good_resp_prob');
    else
    Whisk_Timing_Prob = NaN*ones(numel(Unit_Depth),z);
    end;

else
    Light_Timing_Rate = NaN*ones(numel(Unit_Depth),z);
    Light_Timing_Prob = NaN*ones(numel(Unit_Depth),z);
    Whisk_Timing_Rate = NaN*ones(numel(Unit_Depth),z);
    Whisk_Timing_Prob = NaN*ones(numel(Unit_Depth),z);
end;
        
if ~ isempty(timing_ephys)
Exp_implant(1) = timing_ephys.parameters.implantation_nr;
else
Exp_implant(1) = NaN;
end;

if ~isempty(drive_ephys)
Exp_implant(2) = drive_ephys.parameters.implantation_nr;
else
Exp_implatn(2) = NaN;
end;

if ~isempty(LED_Powers_Ephys)
Exp_implant(3) = LED_Powers_Ephys.parameters.implantation_nr;
else
 Exp_implant(3) = NaN;   
end;

Exp_implant = Exp_implant(~isnan(Exp_implant));
   if range(Exp_implant) == 0
       Exp_implant = Exp_implant(1);
   else
       Exp_implant = 99;
   end;

       
ei   = Exp_implant;
   for k = 1 : numel(Unit_Depth);
    disp(k);
       Exp_Dates(k,1) = {Date};
    end;
    for k = 1 : numel(Unit_Depth)-1;
    Exp_implant = [Exp_implant;ei];
    end;
   
clear ed ei
disp(numel(Unit_Depth));
disp(Exp_Dates);
       

t = table(Unit_Depth,Light_Drive_Rate,Light_Drive_Prob,Light_LEDFlash_Rate,Light_LEDFlash_Prob,Light_Timing_Rate,Light_Timing_Prob,Whisk_Drive_Rate,Whisk_Drive_Prob,Whisk_Timing_Rate,Whisk_Timing_Prob);

Unit_Classify = addvars(t,Exp_Dates,Exp_implant,'Before','Unit_Depth')
Unit_Classify.Properties.VariableNames({'Exp_Dates',;'Exp_implant';'Unit_Depth';'Light_Drive_Rate';'Light_Drive_Prob';'Light_LEDFlash_Rate';'Light_LEDFlash_Prob';'Light_Timing_Rate';'Light_Timing_Prob';'Whisk_Drive_Rate';'Whisk_Drive_Prob';'Whisk_Timing_Rate';'Whisk_Timing_Prob'});

fn = fullfile(Directory,'Stim Response',[Date '_Stim_response.mat']);
disp('Saving output');
save(fn,'Unit_Classify');
disp(['Saved to ' fn]);

else
    disp('No timing, drive or flash experiments');
    Unit_Classify = [];
end;

end
