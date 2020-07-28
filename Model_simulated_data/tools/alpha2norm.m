function [alphaT]=alpha2norm(alphaS)
% given values between 0-1 make them normally distributed
alphaT=-log(1./alphaS - 1);