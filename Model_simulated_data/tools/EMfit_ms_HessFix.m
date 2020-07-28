function [modout]= EMfit_ms_HessFix(rootfile,modelID)
% 2017; does Expecation-maximation fitting. Originally written by Elsa
% Fouragnan, modified by MKW and Patricia Lockwood 1st July 2019
%
% INPUT:       - rootfile: file with all behavioural information necessary for fitting + outputroot
%              - modelID: ID of model to fit
% OUTPUT:      - fitted model
%
% DEPENDENCIES: - norm2par
%               - get_npar
%               - EMmc_ms
qfit = 0;
%======================================================================================================
% 1) do settings and prepare model
%======================================================================================================


fprintf([rootfile.expname ': Fitting ' modelID ' using EM.']);

% assign input variables
modout      = rootfile.em;
n_subj      = length(rootfile.beh);

%Change this later on to deal with trials where they press the wrong side
fit.ntrials=size(rootfile.beh{1,1}.agent,1);
%fit.ntrials = nan(length(rootfile.beh),1);

for is = 1:n_subj
%    fit.ntrials(is) = sum(~isnan(rootfile.beh{is}.outcome)); % if missing trials are nan
   fit.ntrials(is) = length(~find(rootfile.beh{is}.outcome ==1 | rootfile.beh{is}.outcome ==0)); % if nonmissing are 1 or 0
end


% define model and fitting params:
if qfit==1
    fit.convCrit= .5; 
else
    fit.convCrit= 1e-3; 
end
fit.maxit   = 800; 
fit.maxEvals= 400;
fit.npar    = get_npar(modelID);   
fit.objfunc = str2func(['mod_' modelID]);                                     % the function used from here downwards
fit.doprior = 1;
fit.dofit   = 0;                                                              % getting the fitted schedule
fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'Algorithm','quasi-newton'); 
if isfield(fit,'maxEvals'),  fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'MaxFunEvals', fit.maxEvals,'Algorithm','quasi-newton'); end

% initialise group-level parameter mean and variance
posterior.mu        = abs(.1.*randn(fit.npar,1));                             % start with positive values; define posterior because it is assigned to prior @ beginning of loop
posterior.sigma     = repmat(100,fit.npar,1);

% initialise transient variables:
nextbreak   = 0;
NPL         = [];                                                             % posterior likelihood                                                  
NPL_old     = -Inf;
NLL         = [] ;                                                            % NLL estimate per iteration
NLPrior     = [];                                                             % negative LogPrior estimate per iteration

%======================================================================================================
% 2) EM FITTING
%======================================================================================================
figure;
for iiter = 1:fit.maxit                         
   
   m=[];                                                                      % individual-level parameter mean estimate
   h=[];                                                                      % individual-level parameter variance estimate
   
   % build prior gaussian pdfs to calculate P(h|O):
   prior.mu       = posterior.mu;
   prior.sigma    = posterior.sigma;
   prior.logpdf  = @(x) sum(log(normpdf(x,prior.mu,sqrt(prior.sigma))));      % calculates separate normpdfs per parameter and sums their logs

   
   %======================= EXPECTATION STEP ==============================
   for is = 1:n_subj                                                          

      % fit model, calculate P(Choices | h) * P(h | O) 
      ex=-1; tmp=0;                                                           % ex : exitflag from fminunc, tmp is nr of times fminunc failed to run
      while ex<0                                                              % just to make sure the fitting is done
         q        =.1*randn(fit.npar,1);                                      % free parameters set to random
         %q = repmat(0.5,fit.npar,1);
         inputfun = @(q)fit.objfunc(rootfile.beh{is},q,fit.doprior ,fit.dofit,prior);  
         [q,fval,ex,~,~,hessian] = fminunc(inputfun,q,fit.options); % goes into ML function
         if ex<0 ; tmp=tmp+1; fprintf('didn''t converge %i times exit status %i\r',tmp,ex); end         
      end

      
      % fitted parameters and their hessians
      m(:,is)              = q;
      h(:,:,is)            = hessian;                                         % inverse of hessian estimates individual-level covariance matrix
      
      % get MAP model fit:
      NPL(is,iiter)     = fval;                                               % non-penalised a posteriori; 	
      NLPrior(is,iiter) = -prior.logpdf(q);    
      
      
      
   end
   %keyboard
    %mean(m)

   %======================= MAXIMISATION STEP ==============================
   
   [curmu,cursigma,flagcov,~] = compGauss_ms(m,h);                            % compute gaussians and sigmas per parameter
   if flagcov==1, posterior.mu = curmu; posterior.sigma = cursigma; end       % update only if hessians okay
   % check wehther fit has converged
   fprintf(['.']);
   if abs(sum(NPL(:,iiter))-NPL_old) < fit.convCrit  && flagcov==1            % if  MAP estimate does not improve and covariances were properly computed
      fprintf('...converged!!!!! \n');  nextbreak=1;                          % stops at end of this loop iteration                                                        
   end
   NPL_old = sum(NPL(:,iiter));
   
   
   % ============== Plot progress (for visualisation only ===================
   
%    NLL(iiter) = sum(NPL(:,iiter)) - sum(NLPrior(:,iiter));                    % compute NLL manually, just for visualisation
%    subplot(2,1,1);
%    plot(sum(NPL(:,1:iiter)),'b'); hold all;
%    plot(NLL(1:iiter),'r'); 
%    if iiter==1, leg = legend({'NPL','NLL'},'Autoupdate','off'); end
%    title([rootfile.expname ' - ' strrep(modelID,'_',' ')]);    xlabel('EM iteration');
%    setfp(gcf)
%    drawnow; 
   
   % execute break if desired
   if nextbreak ==1 
      break 
   end
end
[~,~,~,covmat_out] = compGauss_ms(m,h,2);% get covariance matrix to save it below; use method 2 to do that %THIS MIGHT STILL BE DODGY IN PEOPLE WITH BAD HESSIANS BUT ONLY SAVED NOT USED

% say if fit was because of that
if iiter == fit.maxit 
    fprintf('...maximum number of iterations reached');
end




%======================================================================================================
%%% 3) Get values for best fitting model
%====================================================================================================== 


% fill in general information
modout.(modelID) = {}; % clear field;
modout.(modelID).date            = date;
modout.(modelID).behaviour       = rootfile.beh;                                          % copy behaviour here, just in case
modout.(modelID).q               = m';
modout.(modelID).qnames          = {};                                                    % fill in below
modout.(modelID).hess            = h;
modout.(modelID).gauss.mu        = posterior.mu;
modout.(modelID).gauss.sigma     = posterior.sigma;
modout.(modelID).gauss.cov       = covmat_out;
modout.(modelID).gauss.corr      = corrcov(covmat_out);
modout.(modelID).fit.npl         = NPL(:,iiter);                                          % note: this is the negative joint posterior likelihood
modout.(modelID).fit.NLPrior     = NLPrior(:,iiter);
modout.(modelID).fit.nll         = NPL(:,iiter) - NLPrior(:,iiter); 
[modout.(modelID).fit.aic,modout.(modelID).fit.bic] = aicbic(-modout.(modelID).fit.nll,fit.npar,fit.ntrials); 
modout.(modelID).fit.lme         = [];
modout.(modelID).fit.convCrit    = fit.convCrit;
modout.(modelID).ntrials         = fit.ntrials;

% make sure you know if BIC is positive or negative! and replace lme with
% bic if covariance in negative.
% error check that BICs are in similar range

% get subject specifics
fit.dofit   = 1;
fit.doprior = 0;


% ==================== %
% Inserted this Jan 2020: Pat & Miriam from mfit_optimize_hierarchical.m from Sam Gershman
for is = 1:n_subj
       
   try
       hHere = logdet(h(:,:,is) ,'chol');
       L(is)= -NPL(is,iiter) - 1/2*log(det(h(:,:,is))) + (fit.npar/2)*log(2*pi); % La Place approximation computed log model evidence - log posterior prob  
       %L(s) = results.logpost(s) + 0.5*(results.K*log(2*pi) - h);
       goodHessian(is) = 1;
   catch
       warning('Hessian is not positive definite');
       try
           hHere = logdet(h(:,:,is));
           L(is) = -NPL(is,iiter) - 1/2*log(det(h(:,:,is))) + (fit.npar/2)*log(2*pi);
           goodHessian(is) = 0;
       catch
           warning('could not calculate');
           goodHessian(is) = -1;
           L(is) = nan;
       end
   end
end
L(isnan(L)) = nanmean(L);
modout.(modelID).fit.lme = L;
modout.(modelID).fit.goodHessian = goodHessian; 
% ==================== %


for is = 1:n_subj
    
   [nll_check,subfit]            = fit.objfunc(rootfile.beh{is},m(:,is),fit.doprior,fit.dofit); 
   % group values
   modout.(modelID).qnames       = subfit.xnames;  
   
   % This used to be here in Marco's version but is now dealt with further
   % up so that noone has bad LME values, those with bad hessians are set
   % to mean LME of all other (working) subjects
   %modout.(modelID).fit.lme(is,1)= -NPL(is,iiter) - 1/2*log(det(h(:,:,is))) + (fit.npar/2)*log(2*pi); % La Place approximation computed log model evidence - log posterior prob  
   % subj values
   modout.(modelID).sub{is}.mat       = subfit.mat;
   modout.(modelID).sub{is}.names     = subfit.names;
   modout.(modelID).sub{is}.choiceprob= subfit.choiceprob;
   
   
   % errorchecks:
  % if real(modout.(modelID).fit.lme(is)) ~= modout.(modelID).fit.lme(is); disp('LME not a real number.'); dbstop if error; error('LME is not a real number (subject %d)', is); end
   if abs(modout.(modelID).fit.nll(is)-nll_check) >.0000000001, disp('ERROR'); keyboard; end % check nll calculation
   
% from quentins script
   
       % from quentins script about negativ hessians
    
%   if any(diag(stats.groupmeancovariance)<0); 
% 	warning('Negative Hessian, i.e. not at maximum - try running again, increase MAXIT if limit reached')
% 	stats.ex=-2; 
% 	saddlepoint=1

% from Vincents script
% 
% data_block=data_temp;
%     data_block(find(data_block(:,2)~=i_block),:)=[]; %remove all the pairs we are not interested in for the current block
%     param=param;prior=prior;
%     if ~(isempty(prior))
%         % Calculate Summary Statistics for priors in each parameter/condition
%         m(1,1)=mu(param(:,1)');b(1,1)=us(param(:,1)');
%         m(1,2)=mu(param(:,2)');b(1,2)=us(param(:,2)');
%         m(1,3)=mu(param(:,4)');b(1,3)=us(param(:,4)');
%         m(1,4)=mu(param(:,5)');b(1,4)=us(param(:,5)');
%         m(1,5)=mu(param(:,7)');b(1,5)=us(param(:,7)');
%         m(1,6)=mu(param(:,8)');b(1,6)=us(param(:,8)');
%         
%         prior_alpha=(np(params(1,1),at(m,[1:2:5],cond),at(b,[1:2:5],cond)));
%         prior_beta=(np(params(1,2),at(m,[2:2:6],cond),at(b,[2:2:6],cond)));
%         
%         % Prevent crash due to infinity in log-space
%         if prior_alpha==0
%             prior_alpha=eps;
%         end
%         if prior_beta==0
%             prior_beta=eps;
%         end
%         lp=log(prior_alpha)+log(prior_beta);
%     else
%         lp=eps;
%     end

end

%======================================================================================================
%%% 4)  plot correlation between parameters:
%====================================================================================================== 


subplot(2,1,2);
imagesc(modout.(modelID).gauss.corr)
colorbar
colormap jet
caxis([-1 1])
title('Parameter Correlation Matrix');
set(gca,'Xtick',1:fit.npar,'XTickLabel',modout.(modelID).qnames)
set(gca,'Ytick',1:fit.npar,'YTickLabel',modout.(modelID).qnames)
%set_default_fig_properties(gca,gcf)

figpath=['figs/'];
% save:
if ~isdir(figpath), mkdir(figpath); end;
figname=[figpath modelID '_' date  ];
saveas(gcf,figname); close all;








end
   