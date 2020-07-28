function [fval,fit] = mod_ms_RWPL(behavData,q, doprior,dofit,varargin)

%[f] = mod_RWAL(p,choice,outcome,stimuli,block,stim_props,outtype)% same as in models above in same order

%%NEED TO REASSIGN BEHAVIOURAL DATA VARIABLES TO PUT INTO THE FUNCTION
% p(1) = beta
% p(2) = learning rate

% runs standard RL model
% P Lockwood modified 1 July 2019 from MK Wittmann, Oct 2018
%
% INPUT:    - behavData: behavioural input file
% OUTPUT:   - fval and fitted variables
%


% How many subjects are you modelling
% num_subs          = max(size(s.PL.beh));
% num_blocks        = 9; % number of conditions
% num_cond          = 3;
% num_pic_reps      = 16; %number of times they saw each picture they had to learn
% stim_props = [num_blocks;num_cond;num_pic_reps];

%%
% -------------------------------------------------------------------------------------
% 1 ) Define free parameters
% -------------------------------------------------------------------------------------

if nargin > 4
    prior      = varargin{1};
end

qt = norm2par('ms_RWPL',q); % transform parameters from gaussian space to model space

% Define free parameters and set unused ones to zero
beta      = qt(1);  
alpha       = qt(2);  
% wcl        = 0;                     

num_blocks=3;
num_cond=3;
num_pic_reps=16;

all_prob = [];
%

all_Va  = [];
all_Vb  = [];
all_PE  = [];

% if (beta<0.05), fval=10000000; return; end;


% Change missed trials coded as '9' to NaNs since other parts of the
% pipeline presume missed trials are NaNs

%%% 0.) Load information for that subject:    % load in each subjects variables for the experiment
choice  = behavData.choice; %matrix of choices for self (stimulus in columns, repetitions in rows)
outcome = behavData.outcome; %matrix of outcomes for self(stimulus in columns, repetitions in rows)
block   = behavData.block; %matrix of outcomes for friend (stimulus in columns, repetitions in rows)
agent   = behavData.agent;

choice(choice   == 9) = nan;
outcome(outcome == 9) = nan;
agent(agent     == 9) = nan;


for iagent=1:num_cond; %%%% loop through the 3 conditions, self, other, no one
    
    for u=1:num_blocks;
        
        % pick values for this sequence
        if iagent==1, % go for reward
            choicet = choice(agent==iagent & block==(u));                                                % choice =1 for high prob, 0 for low prob
            outcomet= outcome(agent==iagent  & block==(u));
            agentt =  agent(agent==iagent  & block==(u));% outcome= 1 for correct, 0 for incorrect
        elseif iagent==2, % no go for reward
            choicet = choice(agent==iagent  & block==(u));                                                % choice =1 for high prob, 0 for low prob
            outcomet= outcome(agent==iagent  & block==(u));
            agentt =  agent(agent==iagent  & block==(u));% outcome= 1 for correct, 0 for incorrect
        elseif iagent==3,
            choicet = choice(agent==iagent & block==(u));                                                % choice =1 for high prob, 0 for low prob
            outcomet= outcome(agent==iagent  & block==(u));
            agentt =  agent(agent==iagent  & block==(u));% outcome= 1 for correct, 0 for incorrect
        end;
        
        
        % make empty matrix for values you want to collect:
        probs_choice =nan(num_pic_reps,1);
        Va           =nan(num_pic_reps,1);      %V_self(1) =  start_bias(1);
        Vb           =nan(num_pic_reps,1);      %V_fri (1) =  start_bias(2);
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
            Va(t+1)    = Va(t);                                       % keep value of self,other no ones same at t+1
            Vb(t+1)    = Vb(t);
            PE(t)      = nan;
            
            if choicet(t)== 1, PE(t)  = outcomet(t) - Va(t);          Va(t+1) = Va(t) +  (alpha*PE(t));      end;
            if choicet(t)== 0, PE(t)  = outcomet(t) - Vb(t);          Vb(t+1) = Vb(t) +  (alpha*PE(t));       end;
            
            %%% 3. What happens if response is too slow:
            
            if isnan(choicet(t)),  probs_choice(t) = NaN;  end;
            
        end % number of pics rep 16 times each stim is presented
        
        %%% 4. now save stuff:
        all_Va     =  [all_Va Va(1:num_pic_reps)];
        all_Vb     =  [all_Vb Vb(1:num_pic_reps)];
        all_PE     =  [all_PE PE];
        all_prob   =  [all_prob; probs_choice];
        
    end % block
    
end % cond

% if any(all_Va==1) 
%     all_Va(all_Va==1)=0.999999;
% end
% if any(all_Va==0) 
%     all_Va(all_Va==0)=0.000001;
% end
% if any(all_Vb==1)
%     all_Vb(all_Vb)=0.999999;
% end
% if any(all_Vb==0)
%     all_Vb(all_Vb==0)=0.000001;
% end



% all choice probablities
ChoiceProb=all_prob';


% -------------------------------------------------------------------------------------
% 4 ) Calculate model fit:  
% -------------------------------------------------------------------------------------

nll =-nansum(log(ChoiceProb));                                                % the thing to minimize                      

if doprior == 0                                                               % NLL fit
   fval = nll;
elseif doprior == 1                                                           % EM-fit:   P(Choices | h) * P(h | O) should be maximised, therefore same as minimizing it with negative sign   
   fval = -(-nll + prior.logpdf(q));
end

% % make sure f is not just low because of Nans in prob-variable:

sumofnans=sum(sum(isnan(choice)));
if sum(isnan(ChoiceProb))~=sumofnans disp('ERROR NaNs in choice and choice prob dont agree'); keyboard; return; end               

% -------------------------------------------------------------------------------------
% 5) Calculate additional Parameters and save: 
% -------------------------------------------------------------------------------------

if dofit ==1
   %vsum = o1_val + o2_val ;
   
   fit         = struct;
   fit.xnames  = {'beta'; 'alpha';};
   
   fit.choiceprob = [ChoiceProb]; %%% NEW as choice prob 400* 1 and values stored as 25*16
   fit.mat    = [all_Va all_Vb all_PE ];
   fit.names  = {'Va';'Vb';'all_PE';};
end






