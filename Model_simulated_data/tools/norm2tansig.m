function [ alpha_out ] = norm2tansig(alpha)
% transformation from gaussian space to alpha space, as suggested in Daw 2009 Tutorial
% MKW October 2017

alpha_out = tansig(alpha)./2;%+.01; %.02 

end

