function [modelresults] = fit_PL_model_optimise(s, modelID, oldallmodels)

%INPUT:     - s: all behavioural data
%           - modelID: string identifying which model to run
% OUPUT:    - modelresults: fitted model including parameter values, fval,PEs etc.

% some optional settings for fminsearch
max_evals       = 1000000;
options         = optimset('MaxIter', max_evals,'MaxFunEvals', max_evals*100);
%

% How many subjects are you modelling
num_subs          = max(size(s.PL.beh));
num_blocks        = 3; % number of conditions
num_cond          = 3;
num_pic_reps      = 16; %number of times they saw each picture they had to learn
stim_props = [num_blocks;num_cond;num_pic_reps];

modelresults={}; % variable to store the results in


%%%% calculate median starting values of old fitted model
allparams = [];

for j = 1:num_subs
    param_sub = oldallmodels{j}.x;
    allparams = [allparams; param_sub];
end;


%% Loop through subjects.
for j = 1:num_subs
    %j
    %%% 0.) Load information for that subject:    % load in each subjects variables for the experiment
    choice  = s.PL.beh{1,j}.choice;  %matrix of choices stimulus in columns, repetitions in rows)
    outcome = s.PL.beh{1,j}.outcome; %matrix of outcomes (stimulus in columns, repetitions in rows)
    block   = s.PL.beh{1,j}.block;   %matrix of block number
    agent   = s.PL.beh{1,j}.agent;
    
    %%% set random starting values (e.g. around the median of the
    %%% population)
    
    %medpar      = median(allparams);
    n_free      = size(allparams,2);
   % Parameter   = medpar.*(rand(n_free,1)/2+.75)';
    Parameter = rand(n_free,1)'; % you might want to do this if the staring values get stuck still
    

    %%% I.) first fit the model:
    modelfun = str2func(['model_' modelID]);
    outtype=1;
    [out.x, out.fval, exitflag] = fminsearch(modelfun, Parameter,options,choice,outcome,block,agent,stim_props,outtype);
    out.modelID=modelID;
    
    %%% II.) Get modeled schedule:
    outtype=2;
    Parameter=out.x;
    modelout=modelfun(Parameter,choice,outcome,block,agent,stim_props,outtype);
    
    %%% III.) Now save:
    if  out.fval < oldallmodels{j}.fval,
        out.xnames = oldallmodels{j}.xnames;
        modelresults{j}=out;
        modelresults{j}.info=modelout;
        
        % just for information:
        fvaldiff = oldallmodels{j}.fval - out.fval;
        if fvaldiff > 0.1,
            disp([modelID ' : better model found :-) Fval difference: '  num2str(fvaldiff)]);
        end
    else
        modelresults{j}=oldallmodels{j};
        disp([modelID ' : no change'])

    end;


end



