function [s, fits, fitMeasures] = mle_MI(s, modelsTR, beston, nrep)
% Fits RL models with mle and does model comparison on simulated data for model
% identifiability
% Patricia Lockwood, January 2020, Based on code by MK Wittmann, October 2018
% Applied to model identifiability by Jo Cutler April 2020
%

s.PL.ml = {};

% define data set(s) of interest:
expids = {'PL'};

% how to fit RL:
M.dofit     = 1;                                                                                                     % whether to fit or not
M.doMC      = 1;                                                                                                     % whether to do model comparison or not
M.modid     = strrep(modelsTR, 'model_', '');

fitMeasures = {'aic','bic','pseudoR2','choiceProbMedianR2'};

bestcol = contains(fitMeasures, beston);

%== I) RUN MODELS: ==========================================================================================

for iexp = 1:numel(expids)
   if M.dofit == 0,  break; end
   cur_exp = expids{iexp};   

   %%% MLE fit %%%
   for im = 1:numel(M.modid) % for the number of models
       for i=1:nrep
           s.(cur_exp).ml.(M.modid{im}) = fit_PL_model(s,M.modid{im}, i);
       end
   end
end

%== II) COMPARE MODELS: ==========================================================================================

for iexp = 1:numel(expids)
    if M.doMC~=1, break; end
    cur_exp = expids{iexp};
    s.(cur_exp).ml.fit = MLEmc(s.(cur_exp).ml,M.modid,length(s.PL.beh{1, 1}.choice),[1 0]);
end

% lowaicid = find(output.sum_all_aic == min(output.sum_all_aic)); % find the model number with the lowest aic
% lowbicid = find(output.sum_all_bic == min(output.sum_all_bic)); % find the model number with the lowest bic
% if lowaicid ~= lowbicid
%     if strcmp(beston,'aic')
%         bestmodel = lowaicid;
%     elseif strcmp(beston,'bic')
%         bestmodel = lowbicid;
%     else
%         error('Please specify at start whether to use aic or bic for model comparison')
%     end
% elseif lowaicid == lowbicid
%     bestmodel = lowaicid;
% end

% Calculate R^2 & extract model fit measures 

for iexp = 1:numel(expids)
    cur_exp = expids{iexp};
    for im = 1:numel(M.modid) % for the number of models
        s.(cur_exp).ml.fit.(M.modid{im}).pseudoR2 = pseudoR2(s.(cur_exp),M.modid{im},2,0);
        s.(cur_exp) = choiceProbR2(s.(cur_exp),M.modid{im},0);
    end
    [fits,~] = getfitsml(s.(cur_exp),fitMeasures,M.modid);
    fits(:,length(fitMeasures)+1) = 0;
    switch beston
        case {'aic','bic'}
            [~, wins] = min(fits(:,bestcol));
        case {'pseudoR2','choiceProbMedianR2'}
            [~, wins] = max(fits(:,bestcol));
        otherwise
            error(['Call to mle_MI must specify one of the following to determine winning model: ',...
                fitMeasures{1},' / ',...
                fitMeasures{2},' / ',...
                fitMeasures{3},' / ',...
                fitMeasures{4}])
    end
    fits(wins,length(fitMeasures)+1) = 1;
end

fitMeasures = [fitMeasures, 'wins'];

end

