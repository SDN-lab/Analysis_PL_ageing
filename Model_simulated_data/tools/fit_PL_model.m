function [modelresults] = fit_PL_model(s, modelID)

%INPUT:     - s: all behavioural data
%           - modelID: string identifying which model to run
% OUPUT:    - modelresults: fitted model including parameter values, fval,PEs etc.

% some optional settings for fminsearch
max_evals       = 1000000;
options         = optimset('MaxIter', max_evals,'MaxFunEvals', max_evals*100);
%
% 
% num_blocks=stim_props(1);%9
% num_cond=stim_props(2);%3
% num_pic_reps=stim_props(3);%16

% How many subjects are you modelling
num_subs          = max(size(s.PL.beh));
num_blocks        = 3; % number of conditions
num_cond          = 3;
num_pic_reps      = 16; %number of times they saw each picture they had to learn
stim_props = [num_blocks;num_cond;num_pic_reps];

modelresults={};


fit =1; % 1 is fitted, 2 is average, 3 is no fitting but single subject

%% Loop through subjects.
for j = 1:num_subs
    j;
    %%% 0.) Load information for that subject:    % load in each subjects variables for the experiment
    choice  = s.PL.beh{1,j}.choice; % matrix of choices 
    outcome = s.PL.beh{1,j}.outcome;% matrix of outcomes 
    block   = s.PL.beh{1,j}.block;  % matrix of block number
    agent   = s.PL.beh{1,j}.agent;  % matrix of whether self, other no one
    %start_bias = s(j).data.prop_s_f_s; % proportion of self,friend and stranger chosen on first presentations (used to intiate values in the model)
    
    if strcmp(modelID,'RWPL')
        Parameter=[0.1 0.1];                                                                                                                            % the starting values of the free parameters
        out.xnames={'beta';'learning rate'};

    elseif strcmp(modelID,'RWPL_SO_LR')
        Parameter=[0.1 0.1 0.1 0.1];                                                                                                                            % the starting values of the free parameters
        out.xnames={'beta';'self learning rate';'other learning rate'; 'no one learning rate'};  

    elseif strcmp(modelID,'RWPL_SO_LR_comb')
        Parameter=[0.1 0.1 0.1];                                                                                                                            % the starting values of the free parameters
        out.xnames={'beta';'self learning rate';'other learning rate';}; 
% 
    elseif strcmp(modelID,'RWPL_SON_LR_SON_beta')
        Parameter=[0.1 0.1 0.1 0.1 0.1 0.1];                                                                                                                            % the starting values of the free parameters
        out.xnames={'beta_self'; 'beta_other'; 'beta no one'; 'self learning rate'; 'other learning rate';'no one learning rate'};
 
%     elseif strcmp(modelID,'RWAL_SO_alpha')
%         Parameter=[0.1 0.1 0.1];                                                                                                                            % the starting values of the free parameters
%         out.xnames={'beta';'learning rate self'; 'learning rate other'};% the names of the free parameters
% 
%     elseif strcmp(modelID,'RWAL_SO_alphaBeta')
%         Parameter=[0.1 0.1 0.1 0.1];                                                                                                                  % the starting values of the free parameters
%         out.xnames={'betaSelf'; 'betaOther';'learning rate self'; 'learning rate other'};% the names of the free parameters
% 
%     elseif strcmp(modelID, 'default_model_average')
%         Parameter=[.48 .53 .40 .33 .48 .26]; % values are from file 'AIC_value_comparisons' model run on 24th June 2017
%         out.xnames={'beta self';'self learning rate';'beta friend';'friend learning rate';'stranger beta';'stranger learning rate' };
    end
    
    
    if fit==1
        %%% I.) first fit the model:
        modelfun = str2func(['model_' modelID]);
        outtype=1;
        [out.x, out.fval, exitflag] = fminsearch(modelfun, Parameter,options,choice,outcome,block,agent,stim_props,outtype);
        out.modelID=modelID;
        %p,choice,outcome,block,agent,stim_props,outtype
        %%% II.) Get modeled schedule:
        outtype=2;
        Parameter=out.x; %% NEED THIS PART; e.g [.1 .1]
        modelout=modelfun(Parameter,choice,outcome,block,agent,stim_props,outtype); %% NEED THIS PART. % another line where you have the nll
        %%% III.) Now save:
        modelresults{j}=out;
        modelresults{j}.info=modelout;
        
    elseif fit==2 % fit with average parameters
        
        modelfun = str2func(['model_' modelID]);
        outtype=2;
        modelout=modelfun(Parameter,choice,stim_props,outtype);
        %%% III.) Now save:
        out.x = Parameter;
        out.modelID=modelID;
        s.AL.ml{j}=out;
        s.AL.ml{j}.info=modelout;
        
   elseif fit==3 % fit with single subject
        
        modelfun = str2func(['model_' modelID]);
        outtype=1;
        modelout=modelfun(Parameter,choice,self_cor,fri_cho,fri_cor,str_cho,str_cor,stim_props,start_bias,outtype);keyboard;
        %%% III.) Now save:
        out.x = Parameter;
        out.modelID=modelID;
        s.AL.ml{j}=out;
        s.AL.ml{j}.info=modelout;
        
    end
end



