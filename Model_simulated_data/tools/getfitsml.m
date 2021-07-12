function [fits, fitstab] = getfitsml(rootfile,names,models)
% Function to extract the measures of model fit for multiple models
%   Written by Jo Cutler April 2020

% INPUT:       - rootfile: file with multiple models and fit measures
%              - names: cell array with the names of measures to extract as
%              they are named in the rootfile structure
%              - models: cell array with the names of the models as they
%              are named in the rootfile structure
% OUTPUT:      - fits: table of fits
%
% DEPENDENCIES: - none

for f = 1:length(names)
    for im = 1:numel(models)
        name = names{f};
        fit = rootfile.ml.fit.(models{im}).(name);
        if length(fit) > 1
        fits(im,f) = sum(fit);
        else
        fits(im,f) = fit;    
        end
    end
end

fitstab = array2table(fits, 'RowNames', models, 'VariableNames', names);

