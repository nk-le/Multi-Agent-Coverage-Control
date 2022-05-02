function R = constructMapRasterReference(rasterSize, rasterInterpretation, ...
    firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator)
% Construct a scalar instance of one of the following, depending on the
% value of rasterInterpretation:
%
%     map.rasterref.MapCellsReference
%     map.rasterref.MapPostingsReference

% Copyright 2013-2018 The MathWorks, Inc.

rasterInterpretation = lower(rasterInterpretation);
if startsWith("cells", rasterInterpretation)
    R = map.rasterref.MapCellsReference(rasterSize, ...
        firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator);
elseif startsWith("postings", rasterInterpretation)
    R = map.rasterref.MapPostingsReference(rasterSize, ...
        firstCornerX, firstCornerY, jacobianNumerator, jacobianDenominator);
else
    % Invalid rasterInterpretation: validatestring will throw an error.
    validatestring(rasterInterpretation,{'cells','postings'})
end
