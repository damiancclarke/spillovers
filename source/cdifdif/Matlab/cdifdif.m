function [betas,ses,RMSEmin,distopt] = cdifdif(y,X,dist,maxDist,varargin)
%--------------------------------------------------------------------------------
% PURPOSE: Tests up until marginal spillover is insignificant
%--------------------------------------------------------------------------------
% INPUTS:  y    = N-by-1 dependent variable
%          X    = N-by-k baseline independent variables
%          dist = N-by-1 distance to treatment
%          step = scalar distance step size
%--------------------------------------------------------------------------------
% OUTPUTS: Xdist   = N-by-(k+ndist) independent variables with new distance dummies
%          ndist   = Number of distance variables
%          maxdist = Maximum spillover distance
%--------------------------------------------------------------------------------

%--------------------------------------------------------------------------------
%--- (1) unpack arguments
%--------------------------------------------------------------------------------  
numvarargs = length(varargin);
if numvarargs > 4
  error('myfuns:cdifdif:TooManyInputs', ...
	'requires at most 4 optional inputs');
end
if length(y)~=length(X)
  error('myfuns:cdifdif:inconsistentMatrices', ...
	'y and X matrices must be of the same length');
end  
optargs = {1 1.96 'kfoldcv' 10};
optargs(1:numvarargs) = varargin;

optargsA = {1 1.96 'kfoldcv' 10};
for i = 1:4
  if isempty(optargs{i})
    optargs{i} = optargsA{i} 
  end
end
[delta, tlimit, CVtype, kfolds] = optargs{:};

%--------------------------------------------------------------------------------
%--- (2) Iterate over potential models
%--------------------------------------------------------------------------------
Xprop     = [ones(length(y),1),X];
RMSEmin   = Inf;
distopt   = 0;
rmseVal   = Inf;
nspillopt = 0;

RMSEcomp  = NaN(round(maxDist/delta),2);
iter = 1;
for i = linspace(delta,maxDist,round(maxDist/delta))
  sprintf('Iteration %d, Distance %d',iter,i)
  [Xspill,nspill,mdist] = marginalDist(y,Xprop,dist,i,tlimit);
  if strcmpi(CVtype,'loocv')
    RMSE = loocv(y,Xspill);
  elseif strcmpi(CVtype,'kfoldcv')
    regf=@(XTRAIN,ytrain,XTEST)(XTEST*regress(ytrain,XTRAIN));
    RMSE = crossval('mse',Xspill,y,'predfun',regf,'kfold',kfolds);
  else
    error('myfuns:cdifdif:invalidOption', ...
	  'Cross-Validation type can either be kfoldcv or loocv. Currently set as %s',...
	  CVtype);
  end
  RMSEcomp(iter,1)=i;
  RMSEcomp(iter,2)=RMSE;
  RMSEcomp
  
  if RMSE < RMSEmin
    RMSEmin   = RMSE;
    distopt   = mdist;
    nspillopt = nspill;
    Xest      = Xspill;
  end

  iter=iter+1;
end

%--------------------------------------------------------------------------------
%--- (3) Estimate Optimal Model
%--------------------------------------------------------------------------------
betas = (Xdist'*Xdist)\(Xdist'*y);
uhat  = Xdist*betas-y;
ses   = diag(sqrt((uhat'*uhat)/(N-length(betas))*inv(Xdist'*Xdist)));

[betas ses]


%--------------------------------------------------------------------------------
%--- (4) Export RMSE graph
%--------------------------------------------------------------------------------
h2 = plot(RMSEcomp(:,1),RMSEcomp(:,2),'-o','LineWidth',3,'MarkerSize',8,'Color',...
	  [0.2 0.6 0.6]);
hXLabel = xlabel('Bandwidth ($h$)','Interpreter','latex','FontSize',12);
hYLabel = ylabel('RMSE $CV(h)$'   ,'Interpreter','latex','FontSize',12);
set(gca, ...
    'Box'         , 'off'     , ...
    'TickDir'     , 'out'     , ...
    'XMinorTick'  , 'on'      , ...
    'YMinorTick'  , 'on'      , ...
    'XColor'      , [.3 .3 .3], ...
    'YColor'      , [.3 .3 .3], ...
    'LineWidth'   , 1         );
str1 = sprintf('$$\\min_{ h}$$ RMSE $CV(h) =$ %3.5g',RMSEmin);
str2 = sprintf('arg$$\\min_{ h}$$ RMSE $CV(h) =$ %3.2g',distopt);
str  =  {str1,str2}
DataX = interp1( [0 1], xlim(), 0.1);
DataY = interp1( [0 1], ylim(), 0.9);
text(DataX,DataY,str,'Interpreter','latex','FontSize',12);

return
