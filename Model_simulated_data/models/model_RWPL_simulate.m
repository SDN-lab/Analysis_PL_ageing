% M1 = 'RWPL' beta, alpha
%    simple RL model with one beta and one learning rate

function [f, allout] = model_RWPL_simulate(data,normalPE,block,agent,p,alphabounds,betabounds)

%%%%% 1. Assign free parameters and other stuff:

% use norm2alpha and norm2beta to get them in a sensible range

alpha=norm2alpha(p(1));
beta=norm2beta(p(2));

alphamin = min(alphabounds);
alphamax = max(alphabounds);
betamin = min(betabounds);
betamax = max(betabounds);

num_blocks=3;
num_cond=3;
num_pic_reps=16;

all_prob = [];
all_Va  = [];
all_Vb  = [];
all_PE  = [];

all_data    = [];
all_outcome = [];
all_agent   = [];
all_stimuli = [];

%%% constrain learning rates:
if (alpha<alphamin || alpha>alphamax), f=1000000000; return; end;
if (beta<betamin  || beta>betamax),  f=10000000; return; end;

for u=1:num_blocks;
    
    for iagent=1:num_cond; %%%% loop through the 3 conditions, self, other, no one
        
        % pick values for this sequence
        normalPEt= normalPE(agent==iagent  & block==(u)); % normalPE = 1 for normal, 0 for PE trial (correct not rewarded, incorrect rewarded)
        agentt =  agent(agent==iagent  & block==(u));
        
        % make empty matrix for values you want to collect:
        probs_choice =nan(num_pic_reps,1);
        Va           =nan(num_pic_reps,1);
        Vb           =nan(num_pic_reps,1);
        PE           =nan(num_pic_reps,1);
        outcomet     =nan(num_pic_reps,1);
        choicet      =nan(num_pic_reps,1);
        
        Va(1)=0.5;
        Vb(1)=0.5;
        
        for t=1:num_pic_reps,  % for the 16 reps of the stimuli                                               % loop through every presentation of the same stimulus
            
            %%% 1. DECISION/CUE PHASE
            
            % first calculate parts of softmax:
            
            %             if choicet(t)  ==1, softmax_num=exp(Va(t)/beta); end;
            %             if choicet(t)  ==0, softmax_num=exp(Vb(t)/beta); end;
            %
            %             softmax_denom =    (exp(Va(t)/beta) +  exp(Vb(t)/beta));
            %
            %             % apply softmax to get choice probability for current trial:
            %
            %             if ~isnan(choicet(t)), probs_choice(t)=softmax_num/softmax_denom; end;
            
            probs_choice(t) = exp(Va(t)/beta)/(exp(Va(t)/beta)+exp(Vb(t)/beta));
            
            choicet(t) = double(rand < (probs_choice(t)));
            
            %%% 2. FB PHASE
            
            % set defaults for (next) trial, then calculate PEs and update:
            Va(t+1)    = Va(t);
            Vb(t+1)    = Vb(t);
            PE(t)      = nan;
            
            if choicet(t)== 1 % if choose the high reward option
                if normalPEt(t) == 1 % if the trial is normal so high reward is rewarded
                    outcomet(t) = 1;
                elseif normalPEt(t) == 0
                    outcomet(t) = 0;
                end
                PE(t)  = outcomet(t) - Va(t);
                Va(t+1) = Va(t) +  (alpha*PE(t));
            end
            
            if choicet(t)== 0 % if choose the low reward option
                if normalPEt(t) == 1 % if the trial is normal so low reward is not rewarded
                    outcomet(t) = 0;
                elseif normalPEt(t) == 0
                    outcomet(t) = 1;
                end
                PE(t)  = outcomet(t) - Vb(t);
                Vb(t+1) = Vb(t) +  (alpha*PE(t));
            end
            
        end % number of pics rep 16 times each stim is presented
        
        %%% 4. now save stuff:
        all_Va     =  [all_Va Va(1:num_pic_reps)];
        all_Vb     =  [all_Vb Vb(1:num_pic_reps)];
        all_PE     =  [all_PE PE];
        all_prob   =  [all_prob; probs_choice];
        all_data    =  [all_data choicet'];
        all_outcome =  [all_outcome outcomet'];
        all_agent   =  [all_agent agentt'] ;
        
    end % cond
    
end % block

% all choice probablities
prob=all_prob';

%keyboard;
% make sure f is not just low because of Nans in prob-variable:
sumofnans=sum(sum(isnan(all_data)));  % calculate number of "too slow" responses, as they are set to "nan" in the "prob"-variable
if sum(isnan(prob))~=sumofnans, f=10000000; return; end;                    % choice prob can only be nan if it was a "too slow" response, not otherwise

% now calculate f:
f=-nansum(log(prob));

allout.all_Va       = all_Va;
allout.all_Vb       = all_Vb;
allout.all_PE       = all_PE;
allout.prob         = prob;
allout.nll          = f;
allout.all_data     = all_data ;
allout.all_outcome  = all_outcome;
allout.all_agent    = all_agent;
f=allout;

end