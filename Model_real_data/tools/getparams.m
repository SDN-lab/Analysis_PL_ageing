function [params] = getparams(rootfile, modelID, IDs)
% Function to extract the final learning parameters + % correct and average RT from a model
%   Written by Jo Cutler April 2020

% INPUT:       - rootfile: file with one or models and resulting parameters
%              - modelID: name of the model to take parameters from
%              (winning model)
%              - IDs: cell array listing participant codes or numbers 
% OUTPUT:      - params: structure containing the alphas, betas, average %
%              correct and average RT in each condition plus a table format 
%              of all this data to save
%
% DEPENDENCIES: - getparnames: function to get the names of the parameters 
%              in each model - update this with new models. Names must be
%              in the order they are output from the model file which often start
%              with betas then alphas

params.ID = IDs;
params.groups = rootfile.em.(modelID).groups;

names = getparnames(modelID); % returns a cell array of the parameter names

alphaind = [];
betaind = [];
otheralphaind = []; % index of other alpha to calculate other - self if relevant
selfalphaind = []; % index of self alpha to calculate other - self if relevant
% find the index of alpha parameters and beta parameters
for ip = 1:length(names)
    thisp=names{ip};
    if contains(thisp, 'alpha') == 1
        alphaind = [alphaind, ip];
        if contains(thisp, 'self') == 1
            selfalphaind = length(alphaind);
        elseif contains(thisp, 'other') == 1
            otheralphaind = length(alphaind);
        end
    elseif contains(thisp, 'beta') == 1
        betaind = [betaind, ip];
    end
end

params.alphas_norm = rootfile.em.(modelID).q(:,alphaind); % extract alphas from parameters
params.alphas_final = norm2alpha(params.alphas_norm); % transform alphas
params.betas_norm = rootfile.em.(modelID).q(:,betaind);  % extract betas from parameters
params.betas_final = norm2beta(params.betas_norm); % transform betas

% put the parameters together with alphas now first then betas
params.alphas_betas_final = [params.alphas_final, params.betas_final]; 
alphabetasind = [alphaind, betaind];

alphabetanamesfinal = {};
for ip = alphabetasind
    paramname = names{ip};
    % parameter names are in format alpha_agent but analysis needs format
    % agent_alpha
    if contains(paramname, 'alpha_') == 1
        paramname = strrep(paramname, 'alpha_', '');
        paramname = [paramname, '_alpha'];
    else
    end
    paramname = ['PL_', paramname]; % add PL to names to avoid confusion with other tasks
    alphabetanamesfinal = [alphabetanamesfinal, paramname];
end

% if an alpha for self and for other have been separately estimated include
% their subtraction in the final table
if isempty(selfalphaind) || isempty(otheralphaind)
else
    alphabetanamesfinal = [alphabetanamesfinal, 'other-self_alph'];
end

% for each participant extract their average % correct and reaction times
% in each condition
for i = 1:length(IDs)
   sum_data{i,1} = IDs{i};
   agents = unique(rootfile.beh{1, i}.agent); % the number of agents in the task, not the model
   for ag = 1:length(agents)
       a = agents(ag);
   ind = find(rootfile.beh{1, i}.agent == a);
   params.corr(i,a) = length(find(rootfile.beh{1, i}.choice(ind) == 1)) / length(find(rootfile.beh{1, i}.choice(ind) == 1 | rootfile.beh{1, i}.choice(ind) == 0));
   params.RT(i,a) = mean(rootfile.beh{1, i}.RT(ind(rootfile.beh{1, i}.choice(ind) == 1 | rootfile.beh{1, i}.choice(ind) == 0)));
   end
end

agentnames = {'self', 'other', 'noone'}; 
% this assumes that if there are 2 agents, they are (in order) self & other
% and if there are 3 agents, they are (in order) self, other & no one

% generate an array of column names for the % correct and RT columns (one
% for each agent in the task, not the model)
corrRTnames = {};
corrRT = {'_corr','_RT'};
for n = 1:2
for ag = 1:length(agents)
   corrRTnames = [corrRTnames, ['PL_', agentnames{ag}, corrRT{n}]];
end
end

% put all of the task (% correct & RT) model (alphas & betas) parameters
% together in a cell array and table format with column headings
params.all_cell = [params.ID, ... 
    num2cell(params.groups), ...
    num2cell(params.corr), ...
    num2cell(params.RT), ...
    num2cell(params.alphas_final), ...
    num2cell(params.betas_final), ...
    num2cell(params.alphas_final(:,otheralphaind) - params.alphas_final(:,selfalphaind))];
params.all_table = cell2table(params.all_cell, 'VariableNames', ['ID_Code', ...
    'Group', ...
    corrRTnames, ...
    alphabetanamesfinal]);

end

