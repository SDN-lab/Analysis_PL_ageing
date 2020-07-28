function [s, fitted] = em_PR(s,modelsTR, params)
% Fits RL models on simulated data and returns parameters for parameter
% recovery
% Patricia Lockwood, January 2020, Based on code by MK Wittmann, October 2018
% Applied to parameter recovery by Jo Cutler April 2020
%

s.PL.em = {};

% define data set(s) of interest:
expids = {'PL'};

% how to fit RL:
M.dofit     = 1;                                                                                                     % whether to fit or not
M.doMC      = 1;                                                                                                     % whether to do model comparison or not
M.modid     = strrep(modelsTR, 'model_', 'ms_');

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

    %%% calculate R^2 & extract model fit measures
    
    for iexp = 1:numel(expids)
        cur_exp = expids{iexp};
        for im = 1:numel(M.modid) % for the number of models
            s.(cur_exp).em.(M.modid{im}).fit.pseudoR2 = pseudoR2(s.(cur_exp),M.modid{im},2,1);
            s.(cur_exp) = choiceProbR2(s.(cur_exp),M.modid{im},1);
        end
        [fits.(cur_exp),fitstab.(cur_exp)] = getfits(s.(cur_exp),{'lme','bicint','pseudoR2','choiceProbMedianR2'},M.modid);
    end
    
%== II) ORDER PARAMETERS: ==========================================================================================

for param=1:length(params)
    
    ind = find(strcmp(s.(cur_exp).em.(M.modid{im}).qnames, params{param})); 
    fitted(:,param) = s.(cur_exp).em.(M.modid{im}).q(:,ind);
    
end

end

