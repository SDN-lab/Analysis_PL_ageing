%%%%%%%%%
%% Modelling for prosociaL learning self/other/no one task using expectation maximisation
%%%%%%%%%

% Fits RL models using expectation maximisation (em) approach and does model comparison
% Written by Patricia Lockwood, January 2020
% Based on code by MK Wittmann, October 2018
% Edited by Jo Cutler, July 2020

%%%%%%%%%
% Step 1 - run the Prosocial_learning_behav_analysis script to save a
% variable 's' that contains a struct for each persons data
% Step 2 - run this script.  
% Dependencies: tools subfolder containing required functions e.g. fit_PL_model
%               models subfolder containing various comp models you have made 
%               in this example 'RWPL', 'RWPL_SO_LR etc

%% Input for script
%       - Participants data file format saved in 's':

%% Output from script
%   - workspaces/EM_fit_results_[date] has all variables from script
%           - 's.PL.em' contains model results including the model parameters per ppt
%   - datafiles in specified output directory:
%       - PL_model_fit_statistics.xlsx - model comparison fit statistics
%       - EM_fit_parameters.xlsx - estimated parameters for each participant
%       - Compare_fit_between_groups.xlsx - median R^2 for each participant with group index

%% Prosocial learning models based Lockwood et PL. (2016), PNAS
% test different variations of learning rate and beta parameters

% Models compared:
% M1 = 'RWPL' beta, alpha
%    simple RL model with one beta and one learning rate
%
% M2 = 'RWPL_SO_LR' beta, self LR, other LR, no one LR
%    RL model with a self other & no one seperate learning
%    rates and one beta parameter
%
% M3 = 'RWPL_SO_comb' RL model with a combined self and other (other & no one)
%      learning rate and one beta parameter - beta, self LR, other LR
%
% M4 = 'RWPL_SON_LR_SON_beta'
% original model from PNAS with 3 learning rates and 3 betas - beta self,
% beta other, beta no one, self LR, other LR, no one LR

%%

%== -I) Prepare workspace: ============================================================================================

clearvars
addpath('models');
addpath('tools');
setFigDefaults;

rng default % resets the randomisation seed to ensure results are reproducible (MATLAB 2019b)

output_dir = '../Prosocial_learning_R_code/'; % enter path to save output in **

%== 0) Load and organise data: ==========================================================================================
% load data:
file_name = 'Combined_data_152'; % specify data **
load([file_name, '.mat']); % .mat file saved from the behavioural script that contains all participants data in 's'

% how to fit RL:
M.dofit     = 1;                                                                            % whether to fit or not
M.doMC      = 1;                                                                            % whether to do model comparison or not
M.modid     = {'ms_RWPL', 'ms_RWPL_SO_LR', 'ms_RWPL_SO_LR_comb','ms_RWPL_SON_LR_SON_beta'}; % complete list of models to fit

fitMeasures = {'lme','bicint','xp','pseudoR2','choiceProbMedianR2'}; % which fit measures to calculate ** 
criteria = 'bicint'; % of above, which to use to choose the best model **

% run optional additional analysis using the VBA toolbox? (see below)
doVBA = 1; % 1 = yes, 0 = no **

% define data set(s) of interest:
expids = {'PL'}; % **

%== I) RUN MODELS: ==========================================================================================

for iexp = 1:numel(expids)
    if M.dofit == 0,  break; end
    cur_exp = expids{iexp};
    
    %%% EM fit %%%
    for im = 1:numel(M.modid) % for the number of models
        dotry=1;
        while 1==dotry
            try
                close all;
                s.(cur_exp).em = EMfit_ms_HessFix(s.(cur_exp),M.modid{im});dotry=0;
            catch
                dotry=1; disp('caught');
            end
        end
    end
    
    %%% calc BICint for EM fit
    for im = 1:numel(M.modid)
        
        s.(cur_exp).em.(M.modid{im}).fit.bicint =  cal_BICint_ms(s.(cur_exp).em, M.modid{im});
        
    end
end

%== II) COMPARE MODELS: ==========================================================================================

for iexp = 1:numel(expids)
    if M.doMC~=1, break; end
    cur_exp = expids{iexp};
    s.(cur_exp) = EMmc_ms(s.(cur_exp),M.modid);
end

% Calculate R^2 & extract model fit measures

for iexp = 1:numel(expids)
    cur_exp = expids{iexp};
    for im = 1:numel(M.modid) % for the number of models
        s.(cur_exp).em.(M.modid{im}).fit.pseudoR2 = pseudoR2(s.(cur_exp),M.modid{im},2,1);
        s.(cur_exp) = choiceProbR2(s.(cur_exp),M.modid{im},1);
    end
    [fits.(cur_exp),fitstab.(cur_exp)] = getfits(s.(cur_exp),fitMeasures,M.modid);
end

%== III) LOOK AT PARAMETERS: ==========================================================================================

bestPLmod = find(fitstab.PL.(criteria) == min(fitstab.PL.bicint));
bestPLmodname = M.modid{bestPLmod};
disp(['Extracting parameters from ', bestPLmodname,' based on best ',criteria])

% For PL models:
for sub=1:length(s.PL.ID)
    
    ID_all(sub, :)=s.PL.ID{1,sub}.ID;
    
end

%== IV) SAVE: ==========================================================================================

for iexp = 1:numel(expids)
    cur_exp = expids{iexp};
    fit = fits.(cur_exp);
    fit = [[1:numel(M.modid)]',fit];
    fittabnum = cell2table(num2cell(fit), 'VariableNames', ['model', fitMeasures]);
    writetable(fittabnum,[output_dir,cur_exp,'_model_fit_statistics.xlsx'],'WriteRowNames',true)
end

IDs = strrep(ID_all, 'PL', ''); % remove characters PL and .log from the ID codes
IDs = strrep(IDs, '.log', '');

params = getparams(s.PL, bestPLmodname, IDs);

writetable(params.all_table,[output_dir,'EM_fit_parameters.xlsx'],'WriteRowNames',true) % combine this with other participant data for analysis

save(['workspaces/EM_fit_results_',date,'.mat'])

%== V) COMPARE PARAMETERS BETWEEN GROUPS: ==========================================================================================

compareFitGroups = [(s.PL.em.(bestPLmodname).groups),(s.PL.em.(bestPLmodname).fit.eachSubProbMedianR2)];
compareFitTab = cell2table(num2cell(compareFitGroups), 'VariableNames', {'group', 'fit'});
writetable(compareFitTab,[output_dir,'Compare_fit_between_groups.xlsx'],'WriteVariableNames',true) % export file to analyse in R

if doVBA == 1
    
    % optional - use the VBA toolbox - https://mbb-team.github.io/VBA-toolbox/
    % to calcuate the xp and expected frequencies in each group and test
    % whether the groups are different in model fit    
    
    L1ind = find(s.PL.em.(bestPLmodname).groups == 1); % group 1
    L2ind = find(s.PL.em.(bestPLmodname).groups == 2); % group 2
    Lallind = [L1ind;L2ind]; % both groups
    L2ind = L2ind(find(L2ind ~= 91 & L2ind ~= 126)); % remove outliers (based on parameters)
    Lind = [L1ind;L2ind]; % both groups, no outliers
    
    for im = 1:numel(M.modid) % for the number of models
        L(im,1:length(Lind)) = s.PL.em.(M.modid{im}).fit.lme(Lind); % extract log model evidence for each participant
        L1(im,1:length(L1ind)) = s.PL.em.(M.modid{im}).fit.lme(L1ind);
        L2(im,1:length(L1ind)) = s.PL.em.(M.modid{im}).fit.lme(L2ind);
        Lall(im,1:length(Lallind)) = s.PL.em.(M.modid{im}).fit.lme(Lallind);
    end
    
    [posteriorA,outA] = VBA_groupBMC(Lall); % both groups, including outliers
    [posterior,out] = VBA_groupBMC(L); % both groups, no outliers
    [posterior1, out1] = VBA_groupBMC(L1) ; % group 1
    [posterior2, out2] = VBA_groupBMC(L2) ; % group 2
    [h, p] = VBA_groupBMC_btwGroups({L1, L2}); % between groups comparison
    
else
end