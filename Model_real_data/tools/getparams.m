function [params] = getParams(rootfile, modelID, IDs)
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
% DEPENDENCIES: - none

params.ID = IDs;
params.groups = rootfile.em.(modelID).groups;
params.alphas_norm = rootfile.em.(modelID).q(:,2:end);
params.alphas_final = norm2alpha(params.alphas_norm);
params.betas_norm = rootfile.em.(modelID).q(:,1);
params.betas_final = norm2beta(params.betas_norm);
params.alphas_betas_final = [params.alphas_final, params.betas_final];

for i = 1:length(IDs)
   sum_data{i,1} = IDs{i};
   agents = unique(rootfile.beh{1, i}.agent);
   for ag = 1:length(agents)
       a = agents(ag);
   ind = find(rootfile.beh{1, i}.agent == a);
   params.corr(i,a) = length(find(rootfile.beh{1, i}.choice(ind) == 1)) / length(find(rootfile.beh{1, i}.choice(ind) == 1 | rootfile.beh{1, i}.choice(ind) == 0));
   params.RT(i,a) = mean(rootfile.beh{1, i}.RT(ind(find(rootfile.beh{1, i}.choice(ind) == 1 | rootfile.beh{1, i}.choice(ind) == 0))));
   end
end

% not updated from 3 conditions:
% params.all_cell = [params.ID, ... 
%     num2cell(params.groups), ...
%     num2cell(params.corr), ...
%     num2cell(params.RT), ...
%     num2cell(params.alphas_final), ...
%     num2cell(params.betas_final), ...
%     num2cell(params.alphas_final(:,2) - params.alphas_final(:,1))];
% params.all_table = cell2table(params.all_cell, 'VariableNames', {'ID_Code', ...
%     'Group', ...
%     'PL_self_corr', ...
%     'PL_other_corr', ...
%     'PL_self_RT', ...
%     'PL_other_RT', ...
%     'PL_self_alpha', ...
%     'PL_other_alpha', ...
%     'beta', ...
%     'other-self_alph'});

end

