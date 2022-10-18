function [params] = getparnames(modelID)
% Lookup table to get names of free parameters per model
% Jo Cutler 2020

%%%%%
if       strcmp(modelID,'ms_RWPL')
    params = {'beta'; 'alpha';};
elseif   strcmp(modelID,'ms_RWPL_SO_LR')
    params = {'beta'; 'alpha_self'; 'alpha_other'; 'alpha_noone'};
elseif   strcmp(modelID,'ms_RWPL_SO_LR_comb')
    params = {'beta'; 'alpha_self'; 'alpha_other';};
elseif   strcmp(modelID,'ms_RWPL_SON_LR_SON_beta')
    params = {'beta_self'; 'beta_other'; 'beta_noone'; 'alpha_self'; 'alpha_other'; 'alpha_noone'};
elseif   strcmp(modelID,'ms_RWPL_SON_beta')
    params = {'beta_self'; 'beta_other'; 'beta_noone'; 'alpha'};
elseif   strcmp(modelID,'ms_RWPL_SO_LR_group')
    params = {'beta'; 'alpha_self'; 'alpha_other'; 'alpha_noone'; 'delta_alpha'};

    % MLE versions
elseif       strcmp(modelID,'RWPL')
    params = {'beta'; 'alpha';};
elseif   strcmp(modelID,'RWPL_SO_LR')
    params = {'beta'; 'alpha_self'; 'alpha_other'; 'alpha_noone'};
elseif   strcmp(modelID,'RWPL_SO_LR_comb')
    params = {'beta'; 'alpha_self'; 'alpha_other';};
elseif   strcmp(modelID,'RWPL_SON_LR_SON_beta')
    params = {'beta_self'; 'beta_other'; 'beta_noone'; 'alpha_self'; 'alpha_other'; 'alpha_noone'};
elseif   strcmp(modelID,'RWPL_SON_beta')
    params = {'beta_self'; 'beta_other'; 'beta_noone'; 'alpha'};
elseif   strcmp(modelID,'RWPL_SO_LR_group')
    params = {'beta'; 'alpha_self'; 'alpha_other'; 'alpha_noone'; 'delta_alpha'};
    
    % Used in the versions with no 'no one' condition
elseif   strcmp(modelID,'ms_RWPL_SO_LR_SO_beta')
    params = {'beta_self'; 'beta_other'; 'alpha_self'; 'alpha_other';};
elseif   strcmp(modelID,'ms_RWPL_SO2_LR')
    params = {'beta'; 'alpha_self'; 'alpha_other'};
    
end

end

