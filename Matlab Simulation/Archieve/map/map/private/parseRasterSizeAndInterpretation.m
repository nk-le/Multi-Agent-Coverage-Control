function [rasterSize, rasterInterpretation] ...
    = parseRasterSizeAndInterpretation(inputs, func_name)
% Parse and validate rasterSize and rasterInterpretation inputs for the
% following syntaxes:
%
%    R = georasterref(W, rasterSize);
%    R = georasterref(W, rasterSize, rasterInterpretation);
%    R = maprasterref(W, rasterSize);
%    R = maprasterref(W, rasterSize, rasterInterpretation);

% Copyright 2010 The MathWorks, Inc.

nIn = numel(inputs);

% Check that the cell array inputs has either 1 or 2 elements.
assert(nIn >= 1, ...
    'map:rasterref:tooFewInputs', ...
    'When a world file matrix is used, function %s requires at least %d inputs.', ...
    func_name, 2)
assert(nIn <= 2, ...
    'map:rasterref:tooManyInputs', ...
    'When a world file matrix is used, function %s accepts at most %d inputs.', ...
    func_name, 3)

% Validate rasterSize, input 2
rasterSize = inputs{1};
validateattributes(rasterSize, {'double'}, ...
    {'row', 'nonnegative', 'integer', 'finite'}, ...
    func_name, 'rasterSize', 2)
assert(numel(rasterSize) >= 2, ...
    'map:rasterref:invalidRasterSize', ...
    '%s must have at least %d elements.', 'rasterSize', 2)

% Validate input 3, rasterInterpretation, if present. Otherwise use the
% default value of 'cells'.
if nIn > 1
    rasterInterpretation = inputs{2};
    rasterInterpretation = validatestring(rasterInterpretation, ...
        {'cells','postings'}, func_name, 'rasterInterpretation', 3);
else
    rasterInterpretation = 'cells';
end
