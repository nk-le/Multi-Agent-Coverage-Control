function validateStaticEmptyArguments(inputs, classname)
%validateStaticEmptyArguments Validate input arguments for empty method
%
%   validateStaticEmptyArguments(INPUTS, CLASSNAME) validates arguments for
%   a static empty method of a class, such as geopoint.empty(). INPUTS is a
%   cell array with empty or numeric input values. If INPUTS is not empty,
%   at least one of the values must be zero. CLASSNAME is the name of the
%   calling function.

% Copyright 2012 The MathWorks, Inc.

% Use try/catch to prevent any errors from being issued by this helper
% function.
try
    % Validate the inputs.
    for k = 1:length(inputs)
        validateattributes(inputs{k}, {'numeric'}, ...
            {'integer', 'finite', 'real', 'nonnegative'})
    end
    
    sizeOut = size(zeros(inputs{:}));
    if prod(sizeOut) ~= 0
        error(message('map:validate:expectedZeroLengthDimension'));
    elseif length(sizeOut) > 2
        error(message('map:validate:expected0by1Size', classname));
    elseif length(inputs) > 1 && sizeOut(2) ~= 1
        warning(message('map:validate:expected0by1Size', classname));
    end
catch e
    throwAsCaller(e);
end
