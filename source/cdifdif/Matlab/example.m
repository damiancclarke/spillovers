rng(2727)
%dat = dlmread('countyAccidents10pc.csv');
[N,K] = size(dat)

y    = dat(:,1);
X    = dat(:,2:K-3);
dist = dat(:,K-1);
wt   = dat(:,K-2);
wt   = 1/wt;

%disp('Baseline Regression')
%(X'*X)\(X'*y)
%disp('Baseline Regression (weighted)')
%lscov(X,y,wt)


cdifdif(y,X,dist,10,1,1.64,'kfoldcv',5)
