% M1 = 'RWPL' beta, alpha
%    simple RL model with one beta and one learning rate

function [f, alloutfit] = model_RWPL_real(allout,Data,p,alphabounds,betabounds)

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

choice = allout.all_data';
outcome = allout.all_outcome';
block = Data.block;
agent = allout.all_agent';

all_prob = [];
all_Va  = [];
all_Vb  = [];
all_PE  = [];

%%% constrain learning rates:
if (alpha<alphamin || alpha>alphamax), f=1000000000; return; end;
if (beta<betamin  || beta>betamax),  f=10000000; return; end;

for u=1:num_blocks;
    
    for iagent=1:num_cond; %%%% loop through the 3 conditions, self, other, no one
        
        % pick values for this sequence
        choicet = choice(agent==iagent & block==(u)); % choice = 1 for high prob, 0 for low prob
        outcomet= outcome(agent==iagent  & block==(u)); % outcome = 1 for rewarded, 0 for not rewarded
        agentt =  agent(agent==iagent  & block==(u));
          
        % make empty matrix for values you want to collect:
        probs_choice =nan(num_pic_reps,1);
        Va           =nan(num_pic_reps,1);
        Vb           =nan(num_pic_reps,1);
        PE           =nan(num_pic_reps,1);
        
        Va(1)=0.5;
        Vb(1)=0.5;
        
        for t=1:num_pic_reps,  % for the 16 reps of the stimuli                                               % loop through every presentation of the same stimulus
            
            %%% 1. DECISION/CUE PHASE
            
            % first calculate parts of softmax:
            
            if choicet(t)  ==1, softmax_num=exp(Va(t)/beta); end;
            if choicet(t)  ==0, softmax_num=exp(Vb(t)/beta); end;
            
            softmax_denom =    (exp(Va(t)/beta) +  exp(Vb(t)/beta));
            
            % apply softmax to get choice probability for current trial:
            
            if ~isnan(choicet(t)), probs_choice(t)=softmax_num/softmax_denom; end;
            
            %%% 2. FB PHASE
            
            % set defaults for (next) trial, then calculate PEs and update:
            Va(t+1)    = Va(t);
            Vb(t+1)    = Vb(t);
            PE(t)      = nan;
            
            if choicet(t)== 1, PE(t)  = outcomet(t) - Va(t);          Va(t+1) = Va(t) +  (alpha*PE(t));     end;
            if choicet(t)== 0, PE(t)  = outcomet(t) - Vb(t);          Vb(t+1) = Vb(t) +  (alpha*PE(t));     end;
            
            %%% 3. What happens if response is too slow:
            
            if isnan(choicet(t)),  probs_choice(t) = NaN;  end;
            
        end % number of pics rep 16 times each stim is presented
        
        %%% 4. now save stuff:
        all_Va     =  [all_Va Va(1:num_pic_reps)];
        all_Vb     =  [all_Vb Vb(1:num_pic_reps)];
        all_PE     =  [all_PE PE];
        all_prob   =  [all_prob; probs_choice];
        
    end % cond
    
end % block

% all choice probablities
prob=all_prob';

%keyboard;
% make sure f is not just low because of Nans in prob-variable:
sumofnans=sum(sum(isnan(choice)));  % calculate number of "too slow" responses, as they are set to "nan" in the "prob"-variable
if sum(isnan(prob))~=sumofnans, f=10000000; return; end;                    % choice prob can only be nan if it was a "too slow" response, not otherwise

% now calculate f:
f=-nansum(log(prob));

    alloutfit.all_Va       = all_Va;
    alloutfit.all_Vb       = all_Vb;
    alloutfit.all_PE       = all_PE;
    alloutfit.prob         = prob;
    alloutfit.nll          = f;
    %f=allout;
end