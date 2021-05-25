function mustBeNondecreasingLimits(limits)
% Argument validation function for geographic and map limit inputs
%
% Validate xlimits or ylimits. Assume 1-by-2 numeric input.

% Copyright 2019 The MathWorks, Inc.

    if limits(2) < limits(1)
        error(message('map:validators:mustBeNondecreasingLimits'))
    end
end
