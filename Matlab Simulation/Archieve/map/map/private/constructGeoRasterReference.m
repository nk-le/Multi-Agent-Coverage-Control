function R = constructGeoRasterReference( ...
    rasterSize, rasterInterpretation, firstCornerLat, firstCornerLon, ...
    deltaLatNumerator, deltaLatDenominator, ...
    deltaLonNumerator, deltaLonDenominator)
% Try to construct a geographic raster reference object, catch
% any errors that are thrown, and issue a new error to provide a
% user-oriented explanation of what went wrong. But, if
% rasterInterpretation is 'cells', try converting to 'postings' and
% adjusting the raster limits inward before throwing the error.

% Copyright 2010-2013 The MathWorks, Inc.

try
    % Individually, we expect the inputs to be valid, but in combination
    % they might imply out-of-range latitude or longitude limits.
    R = map.rasterref.internal.constructGeographicRasterReference( ...
        rasterSize, rasterInterpretation, ...
        firstCornerLat, firstCornerLon, ...
        deltaLatNumerator, deltaLatDenominator, ...
        deltaLonNumerator, deltaLonDenominator);
catch e
    if strcmp(rasterInterpretation,'cells')
        % Try again using 'postings'
        firstCornerLat = firstCornerLat + 0.5 * deltaLatNumerator/deltaLatDenominator;
        firstCornerLon = firstCornerLon + 0.5 * deltaLonNumerator/deltaLonDenominator;
        try
            R = map.rasterref.GeographicPostingsReference( ...
                rasterSize, firstCornerLat, firstCornerLon, ...
                deltaLatNumerator, deltaLatDenominator, ...
                deltaLonNumerator, deltaLonDenominator);
            okWithPostings = true;
        catch e
            okWithPostings = false;
        end
    else
        okWithPostings = false;
    end
    
    if ~okWithPostings
        % Indicate that invalid or inconsistent defining parameters have
        % been encountered through a user-oriented error message that
        % avoids exposing hidden properties of the geographic raster
        % reference class.
        if strcmp(e.identifier,'map:spatialref:invalidLatProps')
            error('map:convertspatialref:invalidLatProps', ...
                ['In combination with the number of rows in the', ...
                ' raster grid, %d, the input referencing vector', ...
                ' or matrix implies latitude limits that extend', ...
                ' outside the interval [-90 90] degrees.'], ...
                rasterSize(1));
        else
            throwAsCaller(e)
        end
    end
end
