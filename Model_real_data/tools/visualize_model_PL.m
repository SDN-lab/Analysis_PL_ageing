function [output] = visualize_model_PL(allmodels,allmodel_IDs,nTrials,doanalyse)%no_subs, modelID,s,doanalyse )
% Analyses visualise results
% trials
% INPUT:    - allmodels: struct with all model parameters in it
%           - modelID: string if you want to pick one specific model
%           - doanalyse: vector indicating which analyses to run
% OPTIONS:  - doanalyse:    1. Plot AIC/BIC/NNL for all models


%%% NULL model - NLL for full model, NLL for null model, number of free
%%% parameters for full (6)

%%
figpath=['figs'];
% save:
if ~isdir(figpath), mkdir(figpath); end;
output.models = allmodel_IDs;

%no_subs=5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. Plot AIC/BIC/NNL for all models
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if doanalyse(1)==1
    

figure;
no_o_models=numel(allmodel_IDs);
   
for imodel=1:no_o_models
    
    modelID=allmodel_IDs{imodel};
    
    %pick model:
    
    mod=allmodels.(modelID);
    
    nr_trials_raw=nTrials;   %%%% CHANGE THIS IF NECESSARY!!!
    
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
    
    output.all_aic_all(:,imodel) = all_aic;
    output.all_bic_all(:,imodel) = all_bic;
    output.all_nnl_all(:,imodel) = all_nll;
    output.sum_all_aic(:,imodel)= sum(all_aic);
    output.sum_all_bic(:,imodel)= sum(all_bic);
    output.sum_all_nll(:,imodel)= sum(all_nll);
    
    bar(mean(all_param));
    
    set(gca, 'xtick',1:numel(param_names),'xticklabel',param_names)
    
    %errorbar(std(all_param),'k.')
    
    figname=(modelID);
    full_figname=[figpath '/' figname  ];
    saveas(gcf,full_figname);
    close all;
    
end

subplot(3,1,1)
plot(output.all_aic_all)
legend(allmodel_IDs); title('AIC');


hold on;

subplot(3,1,2)
plot(output.all_bic_all)
legend(allmodel_IDs); title('BIC');
hold on;

subplot(3,1,3)
plot(output.all_nnl_all)
legend(allmodel_IDs); title('NLL');
figname=(['modelfit_aic_bic_nll_' date]);
full_figname=[figpath '/' figname  ];
saveas(gcf,full_figname);

close all

subplot(3,1,1)
bar(output.sum_all_aic)

hold on;

subplot(3,1,2)
bar(output.sum_all_bic)

hold on;

subplot(3,1,3)
bar(output.sum_all_nll)
set(gca, 'xtick',1:numel(allmodel_IDs),'xticklabel',allmodel_IDs)  ;

figname=(['modelfit_aic_bic_nll_bar_' date]);
full_figname=[figpath '/' figname  ];
saveas(gcf,full_figname);

close all

end %doanalyse

% figname='fig_all_NlL_all_models';
% full_figname=[figpath '/' figname  ];
% saveas(gcf,full_figname);
% close all;

if doanalyse(2)==1
   figure;
   for is = 1:no_subs
       subplot(7,7,is);
       corsub = corrcoef([allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_self(:) allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_fri(:) allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_str(:)],'rows','complete');
       imagesc(corsub,[-.6,.6]); colorbar;
   
   
   end
   
end

if doanalyse(2)==1
   figure;
   for is = 1:no_subs
       subplot(7,7,is);
       corsub = corrcoef([allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_self(:) allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_fri(:) allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_str(:)],'rows','complete');
       imagesc(corsub,[-.6,.6]); colorbar;

   end
   
   figure;
   
   
   for is=1:no_subs
       allchoice = [s(is).data.self_c s(is).data.other_c s(is).data.stranger_c];
       allchoice = allchoice(:); 
       
       ind_self  = find(allchoice==1);
       
       self_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_self; self_PE=self_PE(:);
       fri_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_fri; fri_PE=fri_PE(:);
       str_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_str; str_PE=str_PE(:);
       
       self_chosen_PEs = [self_PE(ind_self) fri_PE(ind_self) str_PE(ind_self)];

       subplot(7,7,is);
       corsub = corrcoef([self_chosen_PEs], 'rows','complete');
       imagesc(corsub,[-.9,.9]); colorbar;
       
   end
   
   figure;
   
   
   for is=1:no_subs
       allchoice = [s(is).data.self_c s(is).data.other_c s(is).data.stranger_c];
       allchoice = allchoice(:); 
       
       ind_fri   = find(allchoice==2);
       
       self_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_self; self_PE=self_PE(:);
       fri_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_fri; fri_PE=fri_PE(:);
       str_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_str; str_PE=str_PE(:);

       fri_chosen_PEs  = [self_PE(ind_fri) fri_PE(ind_fri) str_PE(ind_fri)];
    
       subplot(7,7,is);
       corsub = corrcoef([fri_chosen_PEs], 'rows','complete');
       imagesc(corsub,[-.9,.9]); colorbar;
       
   end
   
   figure;
   
   
   for is=1:no_subs
       allchoice = [s(is).data.self_c s(is).data.other_c s(is).data.stranger_c];
       allchoice = allchoice(:); 
       
       ind_str   = find(allchoice==3);
       
       self_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_self; self_PE=self_PE(:);
       fri_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_fri; fri_PE=fri_PE(:);
       str_PE = allmodels.default_model_multiPE_9_param{1,is}.info.all_PE_str; str_PE=str_PE(:);

       str_chosen_PEs  = [self_PE(ind_str) fri_PE(ind_str) str_PE(ind_str)];
    
       subplot(7,7,is);
       corsub = corrcoef([str_chosen_PEs], 'rows','complete');
       imagesc(corsub,[-.9,.9]); colorbar;
   
       
   end

   
end





