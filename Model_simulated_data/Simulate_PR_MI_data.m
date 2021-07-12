%% Data simulation, PR & MI script %% Adpated from script written by Pat Lockwood & Marco Wittmann 2019 by Jo Cutler 2020
%%% simulation script for parameter recovery and  model identifiability for different
%%% reinforcement learning models for prosocial learning task
%%%

clear all;
close all;
clearvars

addpath('models');
addpath('tools');

beep off;

% Specify whether to run parameter recovery, model identifiability, or both
% -------------------------------------------- %

runPR = 1; % whether to run parameter recovery 1 = yes, 0 = no **
runMI = 0; % whether to run model identifiability 1 = yes, 0 = no **

mlePR = 2; % whether PR to run maximum likelihood = 1, or hierarchical em fit = 2 **
mleMI = 2; % whether MI to run maximum likelihood = 1, or hierarchical em fit = 2 **

% Specify model with which to generate simulated behaviour
% -------------------------------------------- %

models{1} = 'model_RWPL'; % enter model to run here **
models{2} = 'model_RWPL_SO_LR'; % enter model to run here **
models{3} = 'model_RWPL_SO_LR_comb'; % enter model to run here **
models{4} = 'model_RWPL_SON_LR_SON_beta'; % enter model to run here **

% Load in schedule
% -------------------------------------------- %

load trialorderPL.mat % specify trial order file here **
nTrls = size(stim,1);
nBlocks = 3; % specify number of blocks here **

alphabounds = [0, 1]; % enter bounds on alpha values here **
betabounds = [0, 1]; % enter bounds on beta values here **

alphamin = min(alphabounds);
alphamax = max(alphabounds);
betamin = min(betabounds);
betamax = max(betabounds);

toRun = [];
if runPR == 1
    toRun = [toRun, 1];
end
if runMI == 1
    toRun = [toRun, 2];
end

toRunOptions = {'PR', 'MI'};
mleOptions = {'mle', 'em'};

for tr = toRun
    
    rng default % resets the randomisation seed to ensure results are reproducible (MATLAB 2019b)
    
    if tr == 1 % for parameter recovery:
        type = 1; % how to simulate parameters 1 = grid of values, 2 = distribution **
        nRounds = 1; % only 1 round needed for PR
        modelsTR = 2; % enter the model number to run PR on here - numerical index in models variable
        mle_em = mlePR; % whether to run maximum likelihood = 1, or hierarchical em fit = 2
    elseif tr == 2 % for model identifiability:
        type = 2; % how to simulate parameters 1 = grid of values, 2 = distribution **
        nRounds = 10; % how many times to run MI (used in best model counts) **
        modelsTR = 1:length(models); % for MI run all models
        mle_em = mleMI; % whether to run maximum likelihood = 1, or hierarchical em fit = 2
    end
    
    if type == 2
        nSubj = 150; % how many subjects to simulate if not defined by grid **
    else
        nSubj = NaN; % if grid (type == 1) number defined by grid combinations below
    end
    
    for r = 1:nRounds
        
        for m = modelsTR % loop over model number(s) specified above
            
            clearvars -except toRun* models* type *bounds *min *max stim nTrls nBlocks nSubj tr nRounds mle* r m all_*
            
            modelID = models{m};
            s.PL.expname = 'ProsocialLearn';
            
            switch modelID % if adding new model functions also add the parameters here **
                case {'model_RWPL'}
                    params  = {'alpha','beta'};
                case {'model_RWPL_SO_LR'}
                    params  = {'alpha_self', 'alpha_other', 'alpha_noone', 'beta'};
                case {'model_RWPL_SO_LR_comb'}
                    params  = {'alpha_self', 'alpha_other', 'beta'};
                case {'model_RWPL_SON_LR_SON_beta'}
                    params  = {'alpha_self', 'alpha_other', 'alpha_noone', 'beta_self', 'beta_other', 'beta_noone'};
                otherwise
                    error(['No parameters defined for model ', modelID, '. Check modelID parameter'])
            end
            
            modelIDs = [modelID, '_simulate']; % function name to use for a model that simulates the dta
            modelIDr = [modelID, '_real']; % function name to use for a model to fit the simulated data
            nParam  = length(params);
            
            if tr == 1
                msg = ['Running parameter recovery for ', modelID, ', calculating ', num2str(nParam), ' parameters: ', char(params{1})];
                for n = 2:nParam
                    msg = [msg, ', ', char(params{n})];
                end
            elseif tr == 2
                msg = ['Running model identifiability for ', modelID, ', round ', num2str(r),' of ', num2str(nRounds)];
            end
            disp(msg) % show details in command window
            
            % Set parameters to simulate
            % -------------------------------------------- %
            
            if type == 1 % if using a grid of values
                grid.alpha  = [0:0.2:1]; % define grid values **
                grid.beta   = [0:0.2:1]; % define grid values **
                noise = 0.05; % level of noise added to grid of starting values **
                
                for ip=1:length(params)
                    thisp=params{ip};
                    if contains(thisp, 'alpha') == 1
                        grid.all{ip} = grid.alpha;
                    elseif contains(thisp, 'beta') == 1
                        grid.all{ip} = grid.beta;
                    else
                        error('Define parameter as one of above cases');
                    end
                end
                allCombs = combvec(grid.all{1:end})';
                nSubj = size(allCombs,1);
            elseif type == 2 % if using a distribution of values
                for sub = 1:nSubj
                    for ip = 1:length(params)
                        thisp=params{ip};
                        if contains(thisp, 'alpha') == 1
                            allCombs(sub,ip) = betarnd(1.1,1.1); % define distribution **
                            while norm2alpha(alpha2norm(allCombs(sub,ip))) > (alphamax) || norm2alpha(alpha2norm(allCombs(sub,ip))) < (alphamin)
                                allCombs(sub,ip) = betarnd(1.1,1.1);
                            end
                        elseif contains(thisp, 'beta') == 1
                            allCombs(sub,ip) = gamrnd(1.2,5); % define distribution **
                            while norm2beta(beta2norm(allCombs(sub,ip))) > (betamax) || norm2beta(beta2norm(allCombs(sub,ip))) < (betamin)
                                allCombs(sub,ip) = gamrnd(1.2,5);
                            end
                        else
                            error('Define param as one of above cases');
                        end
                    end
                end
                noise = 0;
            end
            
            % Transform parameters
            % -------------------------------------------- %
            
            allCombsNorm = NaN(size(allCombs,1),size(allCombs,2));
            for ip=1:length(params)
                thisp=params{ip};
                if contains(thisp, 'alpha') == 1
                    allCombsNorm(:,ip)=alpha2norm(allCombs(:,ip));
                elseif contains(thisp, 'beta') == 1
                    allCombsNorm(:,ip)=beta2norm(allCombs(:,ip));
                else
                    error(['Can`t detect whether parameter ', thisp, ' is alpha or beta']);
                end
            end
            
            % Plot the distribution of parameters we are using to simulate behaviour
            % -------------------------------------------- %
            
            if r == 1 % plot for the first round only to avoid lots of figures
                figure('color','w');
                for param=1:nParam
                    subplot(1,nParam,param);
                    thisp=params{param};
                    if contains(thisp, 'alpha') == 1
                        histogram(norm2alpha(allCombsNorm(:,param)+noise*randn(length(allCombsNorm),1)),'FaceColor',[0.5 0.5 0.5]);
                    elseif contains(thisp, 'beta') == 1
                        histogram(norm2beta(allCombsNorm(:,param)+noise*randn(length(allCombsNorm),1)),'FaceColor',[0.5 0.5 0.5]);
                    end
                    hold on;box off;title(params{param});
                end
            else
            end
            
            % Simulate all combinations of parameters
            % -------------------------------------------- %
            for simS=1:nSubj
                allbl=[];
                for iblock=1:nBlocks % add column of block number for each trial as needed for modelling
                    blorder    = [ones((nTrls/nBlocks),1)*iblock];
                    allbl = [allbl;blorder];
                end
                
                Data(simS).ID        = sprintf('Subj %i',simS);
                Data(simS).data      = nan(nTrls,1); % save choices
                Data(simS).agent     = stim(:,1);
                Data(simS).normalPE  = stim(:,2);
                Data(simS).block     = allbl;
                Data(simS).trueModel = modelIDr;
                
                for param=1:nParam % Add some noise to grid parameters
                    thisp=params{param};
                    if contains(thisp, 'alpha') == 1
                        pmin = alpha2norm(alphamin);
                        pmax = alpha2norm(alphamax);
                    elseif contains(thisp, 'beta') == 1
                        pmin = beta2norm(betamin);
                        pmax = beta2norm(betamax);
                    end
                    truep(param) = allCombsNorm(simS,param) + noise*randn(1);
                    while truep(param) < pmin || truep(param) > pmax
                        truep(param) = allCombsNorm(simS,param) + noise*randn(1);
                    end
                end
                
                Data(simS).trueParam = truep;
                
                simfunc = str2func(modelIDs);
                
                try
                    [f,allout] = simfunc(Data(simS).data, Data(simS).normalPE, Data(simS).block, Data(simS).agent, Data(simS).trueParam, alphabounds, betabounds); %%%% VARIABLES TO FEED INTO THE MODEL IN ORDER TO SIMULATE CHOICES
                catch
                    disp('Error in call to simulate - possibly argument "allout" (and maybe others) not assigned')
                end
                
                s.PL.beh{1,simS}.choice = allout.all_data';
                s.PL.beh{1,simS}.agent = allout.all_agent';
                s.PL.beh{1,simS}.outcome = allout.all_outcome';
                s.PL.beh{1,simS}.block = allbl;
                s.PL.ID{1,simS}.ID = simS;
                
                if tr == 1
                    
                    disp(['Combination ',num2str(simS) ' of ',num2str(nSubj)]);
                    
                    if mle_em == 1 % if using maximum likelihood for PR, also fit for each subject as simulate
                        
                        % start from 10 random configurations in case of local maxima - arbitrary
                        fvalPre = 10000;
                        iter = 1;
                        maxit = 1000; % if not fitted after this many iterations then stop **
                        fitted = 0;
                        while iter < 10 || fitted ~= 1 % if not fitted within 10 iterations keep going
                            for param=1:nParam
                                thisp=params{param};
                                if contains(thisp, 'alpha') == 1
                                    pmin = alpha2norm(alphamin);
                                    pmax = alpha2norm(alphamax);
                                elseif contains(thisp, 'beta') == 1
                                    pmin = beta2norm(betamin);
                                    pmax = beta2norm(betamax);
                                end
                                p(param) =.1*randn(1);
                                while p(param) < pmin || p(param) > pmax
                                    p(param) =.1*randn(1);
                                end
                            end
                            fit.objfunc = str2func(modelIDr);
                            fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'MaxFunEvals',500,'Algorithm','quasi-newton');
                            
                            inputfun = @(p)fit.objfunc(allout,Data,p,alphabounds,betabounds);
                            
                            [p,fval,alloutfit,ex] = fminunc(inputfun,p,fit.options); % GOES INTO ORIGINAL MODEL HERE FOR FITTING
                            if fval<fvalPre && all(p<100) % for smallest fval and ensuring parameters in reasonable range
                                
                                %     [X,FVAL,EXITFLAG] = fminunc(FUN,X0,...) returns an EXITFLAG that
                                %     describes the exit condition. Possible values of EXITFLAG and the
                                %     corresponding exit conditions are listed below. See the documentation
                                %     for a complete description.
                                
                                if ~any(p>10)
                                    Data(simS).fittedParam = p;
                                    fitted = 1;
                                else
                                end
                                fvalPre = fval;
                            end
                            iter = iter + 1;
                            if iter > maxit
                                fitted = 1;
                            end
                        end
                    else
                    end
                else
                end
            end
            
            if tr == 1 && mle_em == 2 % if using em for PR, fit all subjects
                
                [s, p] = em_PR(s, models(modelsTR), params);
                for simS=1:nSubj
                    Data(simS).fittedParam = p(simS,:);
                end
                
            end
            
            if tr == 1 % for PR create plots then confusion matrix & save
                
                % Plot recovery of params
                % -------------------------------------------- %
                trueParam = []; fittedParam = []; missParam = [];
                for simS=1:nSubj
                    trueParam = [trueParam;Data(simS).trueParam];
                    fittedParam = [fittedParam;Data(simS).fittedParam];
                    if isempty(Data(simS).fittedParam)
                        %disp('empty');
                        missParam = [missParam;Data(simS).trueParam'];
                        trueParam(end,:)=[];
                    end
                end
                
                fitSubj = size(trueParam,1);
                
                figure('color','w');
                for param=1:nParam % plot correlations
                    subplot(1,nParam,param);
                    thisp=params{param};
                    if contains(thisp, 'alpha') == 1
                        trueAlphaBetas(1:fitSubj,param) = norm2alpha(trueParam(:,param));
                        fittedAlphaBetas(1:fitSubj,param) = norm2alpha(fittedParam(:,param));
                        plot(trueAlphaBetas(:,param),fittedAlphaBetas(:,param),'k.','MarkerSize',12);
                        all_corr(param,:) = corr(trueAlphaBetas(:,param),fittedAlphaBetas(:,param));
                        xlim([0,1]);ylim([0,1]);
                    elseif contains(thisp, 'beta') == 1
                        trueAlphaBetas(1:fitSubj,param) = norm2beta(trueParam(:,param));
                        fittedAlphaBetas(1:fitSubj,param) = norm2beta(fittedParam(:,param));
                        plot(trueAlphaBetas(:,param),fittedAlphaBetas(:,param),'k.','MarkerSize',12);
                        all_corr(param,:) = corr(trueAlphaBetas(:,param),fittedAlphaBetas(:,param));
                    end
                    hold on;box off;title(params{param});xlabel('true param');ylabel('fitted param');
                end
                
                figure;
                for param=1:nParam % plot individal parameters
                    thisp=params{param};
                    thisp = strrep(thisp, '_', ' ');
                    if contains(thisp, 'alpha') == 1
                        subplot(nParam,2,(param*2-1))
                        plot(trueAlphaBetas(:,param))
                        title(['true ', thisp])
                        subplot(nParam,2,param*2)
                        plot(fittedAlphaBetas(:,param))
                        title(['fitted ', thisp])
                    elseif contains(thisp, 'beta') == 1
                        subplot(nParam,2,(param*2-1))
                        plot(trueAlphaBetas(:,param))
                        title(['true ', thisp])
                        subplot(nParam,2,param*2)
                        plot(fittedAlphaBetas(:,param))
                        title(['fitted ', thisp])
                    end
                end
                
                % Generate confusion matrix of all parameters correlated with eachother
                % -------------------------------------------- %
                
                row = 1;
                for param=1:nParam
                    for param2=1:nParam
                        confusion(row,1) = param;
                        confusion(row,2) = param2;
                        confusion(row,3) = corr(trueAlphaBetas(:,param), fittedAlphaBetas(:,param2));
                        row = row  + 1;
                    end
                end
                
                msg = ['Finished parameter recovery for ', modelID, ', calculated ', num2str(nParam), ' parameters.', newline, 'Correlations between true and fitted parameters are: ', newline, char(params{1}), ': ', num2str(all_corr(1))];
                for n = 2:nParam
                    msg = [msg, newline, char(params{n}), ': ', num2str(all_corr(n))];
                end
                
                if mle_em == 1
                    conftab = cell2table(num2cell(confusion), 'VariableNames', {'Simulated', 'Recovered', 'MLCorr'});
                    writetable(conftab,['../Prosocial_learning_R_code/Parameter_recovery_mle.xlsx'],'WriteVariableNames',true)
                elseif mle_em == 2
                    conftab = cell2table(num2cell(confusion), 'VariableNames', {'Simulated', 'Recovered', 'HCorr'});
                    writetable(conftab,['../Prosocial_learning_R_code/Parameter_recovery_em.xlsx'],'WriteVariableNames',true)
                end
                
            elseif tr == 2
                
                if mle_em == 1
                    
                    msg = ['Finished mle model identifiability for ', modelID, ', round ', num2str(r),' of ', num2str(nRounds)];
                    
                    [s, fits, fitMeasures] = mle_MI(s, models(modelsTR), 'aic');
                    all_s{r,m} = s;
                    all_fits{r,m} = fits;
                    MIname = ['../Prosocial_learning_R_code/Model_identifiability_mle.xlsx'];
                    
                elseif  mle_em ~= 1
                    
                    msg = ['Finished em model identifiability for ', modelID, ', round ', num2str(r),' of ', num2str(nRounds)];
                    
                    [s, fits, fitMeasures] = em_MI(s, models(modelsTR), 'xp');
                    all_s{r,m} = s;
                    all_fits{r,m} = fits;
                    MIname = ['../Prosocial_learning_R_code/Model_identifiability_em.xlsx'];
                    
                end
                
            end
            
            disp(msg)
            
        end
        
    end
    
    if tr == 2
        
        wincol = find(contains(fitMeasures, 'wins'));
        
        for mod = modelsTR
            
            endrow = length(modelsTR) * mod;
            startrow = endrow - length(modelsTR) + 1;
            
            MItosave(startrow:endrow,1) = mod;
            MItosave(startrow:endrow,2) = modelsTR;
            
            for r = 1:nRounds
                winner = all_fits{r,mod}(:,wincol);
                [~, wins(r,mod)] = max(winner);
                
                if r > 2
                    fitsLong = cat(3,fitsLong,all_fits{r,mod});
                elseif r > 1
                    fitsLong = cat(3,all_fits{1,mod}, all_fits{2,mod});
                else
                end
                
            end
            
            av_fits = mean(fitsLong,3);
            MItosave(startrow:endrow,3:(3+length(fitMeasures)-1)) = mean(fitsLong,3);
            
            for mi = modelsTR
                MItosave((startrow + mi - 1),(3+length(fitMeasures))) = sum(wins(:,mod)==mi);
            end
            
        end
        
        MItab = cell2table(num2cell(MItosave), 'VariableNames', ['Simulated', 'Estimated', fitMeasures 'best']);
        writetable(MItab,MIname,'WriteVariableNames',true)
        
    end
    
    if type == 1
        name = ['workspaces/',toRunOptions{tr},'_',mleOptions{mle_em},'_a_',num2str(grid.alpha(1)),'_',num2str(grid.alpha(end)),'_b_',num2str(grid.beta(1)),'_',num2str(grid.beta(end)),'_n_',num2str(noise),'.mat'];
    elseif type == 2
        name = ['workspaces/',toRunOptions{tr},'_',mleOptions{mle_em},'_',num2str(nSubj),'_subjects_',num2str(nRounds),'_rounds_from_distrib'];
    end
    save(name)
    
end