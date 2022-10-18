%%%%%%%%%
%% Data preparation for prosocial learning self/other/no one task 
%%%%%%%%%

% Combines individual participants' data and outputs the correct format
% ('s' structure)
% Written by Patricia Lockwood, March 2014
% Edited by Jo Cutler, September 2021

%%%%%%%%%
% Step 1 - run this script. 
% Step 2 - run the Run_em_model.m script changing the variable file_name to
% match out_name_group below for computational modelling with expectation
% maximisation
% Dependencies if using Presentation files:
%       - importPresentationLog.m function
%       - loadPresentation.m function

% Input for script: a datafile for each participant to include in the
% modelling in one of the following formats
%       - .log - files generated by running the task in Presentation
%       (assumes from task as programmed by Patricia Lockwood)
%       - .csv or .txt - files must contain a row for each trial and
%       the following columns (see demos in /demofiles):
%                   + cond: 1=self, 2=other, 3=no one
%                   + chosen: 1=correct (high chance of reward), 0=incorrect (low chance of reward)
%                   + reward: 1=reward/avpain, 0=noreward/pain
%                   + rt: reaction time (in ms)
%                   + stim_order: the index of the repetition for that
%                   agent condition i.e 1 for the first block of the self
%                   condition, 2 for the second block of the self
%                   condition, the same for other and for no one
%       note this script could also be adapted to read .mat files with a structure or table format 
%
% Output from script:
%       - Participants data file format saved in 's' with file name
%       specified in out_name_group below
 
%% Instructions for running the script

% specify ext to be the extension of your files (.csv / .txt / .log or see
% above for .mat)
% change the dir_input to be the place where your files are
% change the dir_output if you want to save the output somewhere other than
% the current folder
% change the out_name_group to the name you want to use for your output
% (use this as the file_name in Run_em_model.m)
% change the no_o_subs to the number of participants you have log files for
% ensure the data_name EXACTLY matches the names of all files

% if using .log files, ensure importPresentationLog and loadPresentation scripts 
% are in a directory called 'preptools' or somewhere on the path

%% Notes

% If your data is in a single file e.g. .csv or .txt for all participants,
% simply read the file before the loop over participants [for k=1:size(data_name,2)],
% [e.g. all_data = readtable([dir_input,'/all_data.csv']);]
% enter the ID codes manually or extract them from a column in the file 
% [e.g. id_codes = unique(all_data.participantNum);],
% then within the loop subset the data for one participant each time
% [e.g. data = all_data(all_data.participantNum == id_codes{k},:)].
% You will also need to change the loop to use the size of id_codes if
% data_name not defined [for k=1:size(id_codes,2)].

% If your file names contain further information, for example group or
% sessions you can use split() to split the file names into columns by 
% dividing them at a certain character [e.g. files = split({listfiles.name}, '_');].
% An index for different groups or sessions can be added to the s structure
% by uncommenting the following and changing 0 to the group or session index:
% s.PL.beh{1,k}.group     = repmat(0,size(data.cond));
% For example if file names have the format id_group.csv, then
% id_codes = files(:,:,1);
% str2double(strrep(files(:,:,2), ext, '')); and
% s.PL.beh{1,k}.group     = repmat(groups(k),size(data.cond));
% The modelling script uses the term 'group' so it might be easiest to use
% this for within-subject manipulations too.

%%

clear all
close all
clc

ext = '.csv';                               % what type of file is your data in? should be one of '.log' (Presentation), '.txt' or '.csv'

dir_input = 'demofiles';                    % directory where the data files are

dir_output =  pwd;                          % change this to a different folder to save the output somewhere other than the current folder

out_name_group = 'demo_data_prep.mat';      % enter name for output file containing data for all participants

no_o_subs = 3;                              % number of subjects you want to include (used as a check)

switch ext
    case '.log'
        addpath('preptools')                % for presentation format add directory with functions
end

%% Generate file names
% make variables that provide the names of your input files using one of the following methods:

% ** Method 1 **
% enter names manually e.g.

data_name{1} = ['PL101', ext];
data_name{2} = ['PL102', ext];
data_name{3} = ['PL103', ext];

% % if you want to save a .mat file for each participant separately also generate names for the output files
% out_name{1} = 'PL101.mat';
% out_name{2} = 'PL102.mat';
% out_name{3} = 'PL103.mat';

% ** Method 2 **
% get names of files in folder - ensure only files in dir_input are those you want to use
listfiles = dir([dir_input,'/*', ext]); % list all the text files in that folder
data_name = {listfiles.name}; % just get the names of the files (not the other details given by dir)

% % if you want to save a .mat file for each participant separately also generate names for the output files
% out_name = strrep(data_name, ext, '.mat');

% check number of files found
if size(data_name,2) ~= no_o_subs
    error('Number of log files to analyse doesn`t match specified number of participants')
end

%% Generate participant names
% using one of the following methods:

% ** Method 1 **
% enter names manually e.g.

id_codes{1} = 'PL101';
id_codes{2} = 'PL102';
id_codes{3} = 'PL103';

% ** Method 2 **

id_codes = strrep(data_name, ext, ''); % edit this if the participant id codes are different to the file names with the end removed

%% Read and format data for each participant

for k=1:size(data_name,2)
    
    clear data
    
    switch ext % use the appropriate function to read the data depending on format
        case '.log'
            % This calls the function which imports the .log files in a way that MATLAB can read.
            % make sure importPresentationLog.m file is in the preptools directory or on the path
            data = loadPresentation([dir_input,'/', data_name{k}]);
            
        case {'.txt', '.csv'}
            % import data in a table format
            data = readtable([dir_input,'/', data_name{k}]); 
            
        % if using a different format add here e..g case '.mat'    
            
        otherwise
            error('Variable "ext" must be one of: .log, .txt or .csv or you must edit the script for a different format')
            
    end
    
    % for each of the key fields (columns in table or fields in data output
    % from loadPresentation function) make sure it is numeric and in a
    % column not a row
    fields = {'cond', 'chosen', 'reward', 'rt', 'stim_order'};
    for f = 1:length(fields)
        field = fields{f};
        if ~isnumeric(data.(field))
            data.(field) = str2double(data.(field));
        end
        [r, c] = size((data.(field)));
        if r < c
            data.(field) = data.(field)';
        end
    end
    
    %% create s structure used by modelling script
    
    s.PL.ID{1,k}.ID         = id_codes{k};
    s.PL.beh{1,k}.agent     = data.cond;                     % 1=self, 2=other, 3=no one
    s.PL.beh{1,k}.choice    = data.chosen;                   % 1=correct, 0=incorrect
    s.PL.beh{1,k}.outcome   = data.reward;                   % 1=reward/avpain, 0=noreward/pain
    s.PL.beh{1,k}.RT        = data.rt;                       % reaction time
    s.PL.beh{1,k}.block     = data.stim_order;               % block number
%     s.PL.beh{1,k}.group     = repmat(0,size(data.cond));   % if there are different groups / sessions etc you can add an index here
    s.PL.expname = 'ProsocialLearn';
    s.PL.em = {};
    
end

save([dir_output, '/', out_name_group],'s') % save the s structure in the output directory