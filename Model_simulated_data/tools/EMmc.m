function [ BMS ] = EMmc(rootfile,doplot,fprint,modnames)
% Model comparison for EM fitted models
% MK Wittmann, Nov 2017
%
% INPUT:        - rootfile: root of a specific experiment
%               - fprint: decide whether to print
%               - modnames: which model to looks at
%               - show BICint
% PARAMETER:    - doplot: defines which things to plot:
%                   1. Show model parameters


%
%%


if nargin <4,
   modnames = {'RL'};
end

% fig save location
expname = rootfile.expname;
figpath=['figs/' expname '/mc/']; if ~isdir(figpath), mkdir(figpath); end;

% make as many colors as there are monkeys or models:
moncolset = cbrewer('qual','Set1',numel(unique(rootfile.ID)));
modcolset = cbrewer('qual','Set2',max([3,(numel(modnames)+1)]));
%----------------------------------------------------------------------------------------------------------------
%% 1. Show model parameters
%----------------------------------------------------------------------------------------------------------------
if doplot(1)==1,
       
   extended_fig = 0;
   
   %
    mat        = cell(numel(modnames),1);
    pnames     = cell(numel(modnames),1);
    pnorm      = cell(numel(modnames),1);    % mapping function/information from gaussian to parameter space
    
    max_free   = 0;
    
    %%%%%%%%%%%%%% loop through all models, get information & check max number of free param
    for im = 1:numel(modnames),
       
       %%% get  general variables
       mat{im}       = norm2par(modnames{im},rootfile.em.(modnames{im}).q);        % transform from gaussian space to param space
       pnames{im}    = rootfile.em.(modnames{im}).qnames;
       npar          = size(mat{im},2);
       max_free      = max([max_free npar]);
       
       %%% re-build normpdf, then transform to parameter space:
       nrep          = 1000;
       x             = repmat(linspace(-8,8,nrep),npar,1);                     % values of free parameters in gaussian space
      
       mu            = rootfile.em.(modnames{im}).gauss.mu;
       sigma         = rootfile.em.(modnames{im}).gauss.sigma; 
       pnorm{im}.y   = (normpdf(x,repmat(mu,1,nrep), repmat(sqrt(sigma),1,nrep)))';  % each row is normal distribution over one free parameter       
       [pnorm{im}.xpar,pnorm{im}.xparbounds] = norm2par(modnames{im},x');                               % transform to parameter space
       pnorm{im}.x   = x';  
       pnorm{im}.qraw = rootfile.em.(modnames{im}).q;
       %%%
       %%%
       %%% IMPORTANT NOTE: Sum of normpdf not 1, but 1/binsize (binsize is diff(x))
       %%%                 That is why also values bigger than 1 can come out of normpdf
       %%%                 Possible to normalize by multiplying with binsize
       %%%
       %%%
    end;

    %%%%%%%%%%%%%% 1) loop 2 plot - same as ML plot:
    figure('Name',[expname ' model parameters'])
    for im = 1:numel(modnames)
       for iv = 1:size(mat{im},2),
          subplot(numel(mat),max_free,(im-1)*max_free+iv);
          mat2plot = mat{im}(:,iv);
          monkId   = rootfile.ID;
          
          h=bar(1,mean(mat2plot)); hold all;
          set(h,'Facecolor','w');
          errorbar(1,mean(mat2plot),getSE(mat2plot),'.k','Linewidth',2);
          for imon = 1:numel(monkId),
             plot(1,mat2plot(imon),'k.');%,'Color',moncolset(imon,:));
          end;
          if iv == 1, title([expname ' EM-fit - ' modnames{im}],'interpreter','none'); end
          set(gca,'xtick',1,'xticklabel',[(pnames{im}{iv}) ' med = ' num2str(median(mat2plot))] ); 
          ylim(pnorm{im}.xparbounds(:,iv));
       end;
    end;
    setfp(gcf);
    

    if fprint==1,
        disp('printing Model parameters ...');
        figname=[figpath 'EM_MparsClassic_' date];
        saveas(gcf,figname);  %close all;
    end    

    %%%%%%%%%%%%%% 2) loop 2 plot - distribution plots, comparing models:
    
    figure('Name',[expname ' model parameters'])
    for im = 1:numel(modnames)
       for iv = 1:size(mat{im},2),
          subplot(numel(mat),max_free,(im-1)*max_free+iv);
          indok1 = pnorm{im}.xpar(:,iv) > pnorm{im}.xparbounds(1,iv);       % make sure what you plot is within bounds
          indok2 = pnorm{im}.xpar(:,iv) < pnorm{im}.xparbounds(2,iv);       % make sure what you plot is within bounds
          indok = (indok1+indok2==2);
          
          plot(pnorm{im}.xpar(indok,iv),pnorm{im}.y(indok,iv),'k','Linewidth',2); hold all;
          if iv == 1, title([expname ' EM-fit - ' modnames{im}],'interpreter','none'); end
          xlabel(pnames{im}{iv}); ylabel('Pdf');
          for imon = 1:numel(rootfile.ID), % plot individual monkeys
             xmonk      = mat{im}(imon,iv); 
             plot(xmonk,.01*imon,'k.');%,'Color',moncolset(imon,:));
          end;
         
       end
    end;
   setfp(gcf);
    if fprint==1,
       disp('printing Model parameters ...');
       figname=[figpath 'EM_MparsDist_' date];
       saveas(gcf,figname);
       %close all;
    end
 
    
    %%%%%%%%%%%%%% 3) loop 2 plot - distribution plots, detailing each model:
    if extended_fig ==1,
    for im = 1:numel(modnames)
       figure('Name',[expname ' EM-fit - ' modnames{im}])
       
       % mapping functions
       for iv = 1:size(pnorm{im}.x,2),
          subplot(3,max_free,iv);
          plot(pnorm{im}.x(:,iv),pnorm{im}.xpar(:,iv),'k','Linewidth',2);
          
          if iv == 1, title([expname ' EM-fit - ' modnames{im}]);  end;
          xlabel('gaussian space'); ylabel('parameter space');       
       end;
       
       % parameter dist in gauss space
       for iv = 1:size(pnorm{im}.x,2),
          subplot(3,max_free,max_free+iv);
          plot(pnorm{im}.x(:,iv),pnorm{im}.y(:,iv),'k','Linewidth',2); hold all;
          title([pnames{im}{iv}]);
          xlabel('gaussian space'); ylabel('Pdf');
          for imon = 1:numel(rootfile.ID), % plot individual monkeys
             xmonk      = pnorm{im}.qraw(imon,iv);
             plot(xmonk ,.1*rootfile.ID(imon),'kx','Linewidth',3);%,'Color',moncolset(rootfile.ID(imon),:));
          end;
       end;
       
       % parameter dist in parameter space
       for iv = 1:size(pnorm{im}.x,2),
          subplot(3,max_free,2*max_free+iv);
          
          indok1 = pnorm{im}.xpar(:,iv) > pnorm{im}.xparbounds(1,iv);       % make sure what you plot is within bounds
          indok2 = pnorm{im}.xpar(:,iv) < pnorm{im}.xparbounds(2,iv);       % make sure what you plot is within bounds
          indok = (indok1+indok2==2);
          
          plot(pnorm{im}.xpar(indok,iv),pnorm{im}.y(indok,iv),'k','Linewidth',2); hold all;
          title([pnames{im}{iv}],'interpreter','none');
          xlabel('parameter space'); ylabel('Pdf');
          for imon = 1:numel(rootfile.ID), % plot individual monkeys
             xmonk      = mat{im}(imon,iv);
             plot(xmonk ,.1*rootfile.ID(imon),'x','Linewidth',3,'Color',moncolset(rootfile.ID(imon),:));
          end;
       end;
    
       setfp(gcf);
       if fprint==1,
          disp('printing Model parameters ...');
          figpath_ext=['figs/' expname '/mc/pDist/']; if ~isdir(figpath_ext), mkdir(figpath_ext); end;
          figname=[figpath_ext 'EM_MparsDistsupp_' modnames{im} '_'  date];
          saveas(gcf,figname);
          %close all;
       end
    end;
    end
end;

%----------------------------------------------------------------------------------------------------------------
%% 2. Show model parameters
%----------------------------------------------------------------------------------------------------------------
if doplot(2)==1,   
      
   xtickrot = 25;
   
   %%%% get info
   for imod=1:numel(modnames),
      lme(:,imod)    = rootfile.em.(modnames{imod}).fit.lme; 
      if isfield(rootfile.em.(modnames{imod}).fit,'bicint');
         bicint(imod)   = rootfile.em.(modnames{imod}).fit.bicint; 
      else
         bicint(imod) = 0;
      end;
   end

   % error check
    ix = isnan(lme)|isinf(lme)|imag(lme)~=0; % check if any Hessians are degenerate - from Gershamn mfit toolbox mfit_bms script ~line 42
    if any(ix(:))
        disp('Hessians are degenerate. Use BIC instead'); keyboard;
    end
   
   % exp_r is the posterior probability that model k has generated the data
   % xp is exceedance probability i.e. our belief that model k is more likely
   % than any other model (of the k models tested) given the group data

   % this is coming from SPM you need to have it somewhere in your paths
   [~,~,xptest] = spm_BMS(lme);                               % log model evidence (i.e. result of LaPlace) input for postprob and exceedence prob
   [BMS.alpha,BMS.exp_r,BMS.xp,BMS.pxp] = spm_BMS_v12(lme); % using SPM12; only that one gives protected XP
   if sum(abs(xptest-BMS.xp))>.005, disp('ERROR'); keyboard; end;

   % plot stuff:
   
   % 1) LME sum
   h=figure('name', expname);
   suptitle('Bayesian Model Comparison'); 
   
   subplot(2,3,1);   bar(sum(lme));
   set(gca,'XTick',1:numel(modnames),'XTickLabel',modnames,'XTickLabelRotation',xtickrot);
   ylabel('Summed log evidence (more is better)','FontWeight','bold');

   % 2) BICint
   subplot(2,3,2);
   bar(bicint);
   set(gca,'XTick',1:numel(modnames),'XTickLabel',modnames);
   set(gca,'XTickLabel',modnames,'XTickLabelRotation',xtickrot);
   ylabel('BICint (less is better)','FontWeight','bold');


   % plot protected and unprotected and exceedance prob:
   subplot(2,3,4)
   bar(BMS.pxp);
   set(gca,'XTick',1:numel(modnames),'XTickLabel',modnames,'XTickLabelRotation',xtickrot);
   rl1 = refline(0,.95);     set(rl1,'linestyle','--','Color','r');
   ylabel('Protected Exceedance Probability','FontWeight','bold');
   
   subplot(2,3,5)
   bar(BMS.xp);
   set(gca,'XTick',1:numel(modnames),'XTickLabel',modnames,'XTickLabelRotation',xtickrot);
   rl1 = refline(0,.95);     set(rl1,'linestyle','--','Color','r');
   ylabel('Exceedence Probability','FontWeight','bold');   
   
   
   saveadd = 'all';
   % Bayes factor if numel(mod) ==2
   if numel(modnames) == 2
      subplot(2,3,6);
      lmediff = lme(:,2) - lme(:,1);      % more positive lme values mean better model fit; other way around than BIC
      [lmediffsort,scode] = sort(lmediff);           
      for imon = 1:numel(unique(rootfile.ID)), 
         indmon = imon; %find(rootfile.ID(scode) == imon);
         plotlmes = zeros(numel(rootfile.ID),1); plotlmes(indmon) = lmediffsort(indmon); 
         hbar = barh(1:numel(rootfile.ID), plotlmes); hold all;          
         set(hbar,'Facecolor',moncolset(imon,:)); %keyboard;
      end;
      set(gca,'ytick',1:numel(rootfile.ID));
      ylabel('Subjects (sorted)');
      xlabel([modnames{1} ' vs. ' modnames{2} ]);
      title('Log Evidence Differences / Log Bayes factor'); % bayes factor is just difference in LME      

      % for savename:
      saveadd = [strrep(modnames{1},'_','') '_vs_' strrep(modnames{2},'_','')];
   end
   setfp(gcf); 
   if fprint==1,
      disp('printing Model parameters ...');
      figname=[figpath 'EM_BMC_' saveadd '_'  date];
      saveas(gcf,figname);
      %close all;
   end
end
end


