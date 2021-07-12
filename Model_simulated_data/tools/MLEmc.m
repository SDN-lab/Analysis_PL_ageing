function [fits] = MLEmc(allmodels,allmodel_IDs,nTrials,doanalyse)
% % Model comparison for MLE fitted models
% Adapted from visualize_model_PL.m (for real data) by Jo Cutler 2020
%
% INPUT:    - allmodels: struct with all model parameters in it
%           - allmodel_IDs: strings with model names
%           - nTrials: number of trials
%           - doanalyse: vector indicating which analyses to run

%%% NULL model - NLL for full model, NLL for null model, number of free
%%% parameters for full (6)

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. Calculate AIC/BIC/NNL for all models
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if doanalyse(1)==1
    
no_o_models=numel(allmodel_IDs);
   
for imodel=1:no_o_models
    
    modelID=allmodel_IDs{imodel};
    
    %pick model:
    
    mod=allmodels.(modelID);
    
    nr_trials_raw=nTrials;
    
    % information you want to have:
    
    all_nll=[];
    all_aic=[];
    all_bic=[];
    all_param=[];
    
    % loop over subjects
    for is=1:numel(mod)
        nr_trials = nr_trials_raw - sum(isnan(mod{is}.info.prob));          % number of trials minus number of nans (as those are not used for fitting)
        all_param=[all_param; mod{is}.x];
        param_names= mod{1}.xnames;
        nr_free_p=length(mod{is}.x);
        all_nll=[all_nll; mod{is}.fval];
        [aic, bic]=aicbic(-mod{is}.fval, nr_free_p, nr_trials);
        all_aic=[all_aic; aic];
        all_bic=[all_bic; bic];
    end
    
    fits.(modelID).aic = all_aic;
    fits.(modelID).bic = all_bic;
    fits.(modelID).nll = all_nll;
    fits.(modelID).aicSum = sum(all_aic);
    fits.(modelID).bicSum = sum(all_bic);
    fits.(modelID).nllSum = sum(all_nll);
    
end

end

