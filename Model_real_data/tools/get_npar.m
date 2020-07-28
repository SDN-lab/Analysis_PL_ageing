function [ npar ] = get_npar( modelID)
% Lookup table to get number of free parameters per model
% MKW 2018


%%%%%
if       strcmp(modelID,'ms_RWPL'),                       npar = 2;
elseif   strcmp(modelID,'ms_RWPL_SO_LR'),                 npar = 4;
elseif   strcmp(modelID,'ms_RWPL_SO_LR_comb'),            npar = 3;
elseif   strcmp(modelID,'ms_RWPL_SON_LR_SON_beta'),       npar = 6;
elseif   strcmp(modelID,'ms_RWPL_SON_beta'),              npar = 4;
elseif   strcmp(modelID,'ms_RWPL_SO_LR_group'),           npar = 5;
elseif   strcmp(modelID,'ms_RWPL_SO_LR_SO_beta'),     npar = 4;
elseif   strcmp(modelID,'ms_RWPL_SO2_LR'),            npar = 3;
    
end

end

