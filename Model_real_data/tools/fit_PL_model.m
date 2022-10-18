function [modelresults] = fit_PL_model(s, modelID, iteration)

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
        %%% I.) First fit the model:
        modelfun = str2func(['model_' modelID]);
        outtype=1;
        [out.x, out.fval, exitflag] = fminsearch(modelfun, Parameter,options,choice,outcome,block,agent,stim_props,outtype);
        out.modelID=modelID;
        % p,choice,outcome,block,agent,stim_props,outtype
        
        %%% II.) Get modeled schedule:
        outtype=2;
        Parameter=out.x; %% NEED THIS PART; e.g [.1 .1]
        modelout=modelfun(Parameter,choice,outcome,block,agent,stim_props,outtype); %% NEED THIS PART. % another line where you have the nll UNCLEAR about these comments? 
        
        %%% III.) Now save:
        
        if  iteration == 1 % if the first run, save output
            modelresults{j}=out;
            modelresults{j}.info=modelout;
        else % if not the first run then check whether fit is better
            if out.fval < s.PL.ml.(modelID){j}.fval % if new fval lower (better) then update
                out.xnames = s.PL.ml.(modelID){j}.xnames;
                modelresults{j}=out;
                modelresults{j}.info=modelout;
                
                % just for information:
                fvaldiff = s.PL.ml.(modelID){j}.fval - out.fval;
                %             if fvaldiff > 0.1
                disp([modelID ' : better model found :-) Fval difference: '  num2str(fvaldiff)]);
                %             end
            else % if new fval not better then don't update
                modelresults{j}=s.PL.ml.(modelID){j};
                %             disp([modelID ' : no change'])
            end
        end
        
    end
end



