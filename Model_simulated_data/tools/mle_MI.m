function [s, fits, fitMeasures] = mle_MI(s, modelsTR, beston)
% Fits RL models and does model comparison on simulated data for model
% identifiability
% Patricia Lockwood, January 2020, Based on code by MK Wittmann, October 2018
% Applied to model identifiability by Jo Cutler April 2020
%

s.PL.em = {};

% define data set(s) of interest:
expids = {'PL'};

% how to fit RL:
M.dofit     = 1;                                                                                                     % whether to fit or not
M.doMC      = 1;                                                                                                     % whether to do model comparison or not
M.modid     = strrep(modelsTR, 'model_', 'ms_');

fitMeasures = {'lme','bicint','xp','pseudoR2','choiceProbMedianR2'};

bestcol = contains(fitMeasures, beston);

%== I) RUN MODELS: ==========================================================================================

for iexp = 1:numel(expids)
   if M.dofit == 0,  break; end
   cur_exp = expids{iexp};   

         %%% MLE fit %%%
   for im = 1:numel(M.modid) % for the number of models
      dotry=1;
      while 1==dotry
      % try
%          close all;
           s.(cur_exp).ml.(M.modid{im}) = EMfit_ms_HessFix(s.(cur_exp),M.modid{im});dotry=0; 
%         catch
%            dotry=1; disp('caught');
%         end
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
    [fits,~] = getfits(s.(cur_exp),fitMeasures,M.modid);
    fits(:,length(fitMeasures)+1) = 0;
    [~, wins] = max(fits(:,bestcol));
    fits(wins,length(fitMeasures)+1) = 1;
end



end

