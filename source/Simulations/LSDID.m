function [Y,D,R,t] = LSDID(params,N)
% [est,X]=LSDID(params,N) takes the input parameters defined in params
% and simulates outcome for N individuals of the form:
%    y(i,t)= mu + tau*D(i,1) + delta*t + alpha D(i,t) + beta R(i,t) + u(i,t)
%
% the arguments params should be a 1 by 5 vector [mu,tau,delta,alpha,beta]

D = rand(N,1);
D(D>0.7) = 1;
D(D~=1)  = 0;
t = zeros(N,1);
t(round(N/2):N)=1;
R = rand(N,1);
R(R>0.7) = 1;
R(R~=1)  = 0;
R=R.*D;

Y = params(1)+params(2)*D+params(3)*t+params(4)*D.*t+params(5)*R.*t+randn(N,1);

mean(Y)
return