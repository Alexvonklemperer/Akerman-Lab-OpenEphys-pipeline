%  create a channel map file

Nchannels = 32;
connected = true(Nchannels, 1);
chanMap   = [1 17 16 32 3 19 14 30 9 25 10 20 8 24 2 29 7 26 15 21 11 23 12 28 6 18 13 22 5 27 4 31];
chanMap0ind = chanMap - 1;
xcoords   = ones(Nchannels,1);
ycoords   = [Nchannels:-1:1]' * 25;
kcoords   = ones(Nchannels,1); % grouping of channels (i.e. tetrode groups)

fs = 30000; % sampling frequency
save([cd filesep 'chanMap.mat'], ...
    'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')

%%
% 
% Nchannels = 32;
% connected = true(Nchannels, 1);
% chanMap   = 1:Nchannels;
% chanMap0ind = chanMap - 1;
% 
% xcoords   = repmat([1 2 3 4]', 1, Nchannels/4);
% xcoords   = xcoords(:);
% ycoords   = repmat(1:Nchannels/4, 4, 1);
% ycoords   = ycoords(:);
% kcoords   = ones(Nchannels,1); % grouping of channels (i.e. tetrode groups)
% 
% fs = 30000; % sampling frequency
% 
% save([cd filesep 'chanMap.mat'], ...
%     'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')
% %%

% kcoords is used to forcefully restrict templates to channels in the same
% channel group. An option can be set in the master_file to allow a fraction 
% of all templates to span more channel groups, so that they can capture shared 
% noise across all channels. This option is

% ops.criterionNoiseChannels = 0.2; 

% if this number is less than 1, it will be treated as a fraction of the total number of clusters

% if this number is larger than 1, it will be treated as the "effective
% number" of channel groups at which to set the threshold. So if a template
% occupies more than this many channel groups, it will not be restricted to
% a single channel group. 