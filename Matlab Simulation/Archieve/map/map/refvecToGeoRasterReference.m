function R = refvecToGeoRasterReference( ...
    refvec, rasterSize, func_name, var_name, arg_pos)
%refvecToGeoRasterReference Referencing vector to geographic raster reference object
%
%   R = refvecToGeoRasterReference(REFVEC, rasterSize) constructs a
%   geographic raster reference object, R, from a referencing vector,
%   REFVEC, and size vector, rasterSize. REFVEC may be any valid 1-by-3
%   referencing vector, as long as the cell size 1/REFVEC(1), northwest
%   corner latitude REFVEC(2), and northwest corner longitude REFVEC(3)
%   lead to valid latitude and longitude limits when combined with the
%   rasterSize vector. rasterSize is a size vector [M N ...] specifying the
%   number of rows (M) and columns (N) in the raster or image to be
%   associated with the geographic raster reference object, R.
%
%   R = refvecToGeoRasterReference(REFVEC, rasterSize, FUNC_NAME, VAR_NAME, ARG_POS)
%   uses up to three optional arguments to provide additional
%   information. This information is used to construct error messages if
%   either the REFVEC or rasterSize inputs turn out to be invalid. Thus,
%   you can use refvecToGeoRasterReference for both validating and
%   converting a referencing vector. The optional inputs work just like
%   their counterparts in the MATLAB function VALIDATEATTRIBUTES:
%
%      FUNC_NAME specifies the name used in the formatted error message to
%      identify the function checking the input.
%
%      VAR_NAME specifies the name used in the formatted error message to
%      identify the referencing vector.
%
%      ARG_POS is a positive integer that indicates the position of the
%      referencing vector checked in the function argument list.
%      refvecToGeoRasterReference includes this information in the
%      formatted error message.
%
%   R = refvecToGeoRasterReference(Rin, rasterSize, ...), where Rin is a
%   geographic raster reference object, verifies that Rin.RasterSize is
%   consistent with rasterSize, then copies Rin to R.
%
%   Example
%   -------
%   % Construct a referencing vector for a regular 180-by-240 grid covering
%   % a quadrangle with latitude limits [30 45] and longitude limits [115 135]
%   % that includes the Korean Peninsula, with 12 cells per degree.
%   refvec = [12  45  115];
%
%   % Convert to a geographic raster reference object.
%   rasterSize = [180 240];
%   R = refvecToGeoRasterReference(refvec, rasterSize)
%
%   % For comparison, construct a referencing object directly.
%   georasterref('RasterSize', rasterSize, ...
%       'LatitudeLimits', [30 45], 'LongitudeLimits', [115 135])
%
%   See also georasterref, refmatToGeoRasterReference

% Copyright 2010-2017 The MathWorks, Inc.

if nargin < 3
    func_name = 'refvecToGeoRasterReference';
end

if nargin < 4
    var_name = 'REFVEC';
end

if nargin < 5
    arg_pos = 1;
end

%Validate raster size.
validateattributes(rasterSize, ...
    {'double'}, {'row','positive','integer'}, func_name)

assert(numel(rasterSize) >= 2, ...
    'map:convertspatialref:invalidRasterSize', ...
    'The raster size vector provided to function %s must have at least two elements.', ...
    func_name)

if isobject(refvec) && strcmp(refvec.CoordinateSystemType,'geographic')
    R = refvec;
    
    assert(isequal(R.RasterSize, rasterSize(1, 1:2)), ...
        'map:convertspatialref:inconsistentRasterSize', ...
        'A %s object was provided to function %s., but its % value is not consistent with the raster size vector.', ...
        class(R), func_name, 'RasterSize')
else
    % Validate referencing vector. It must be a a 1-by-3 vector of
    % real-valued doubles and the first element must positive.
    validateattributes(...
        refvec, {'double'}, {'real','finite','nonempty','vector'}, ...
        func_name, var_name, arg_pos);
    
    assert(numel(refvec) == 3, ...
        'map:convertspatialref:refvecNumelNot3', ...
        'Function %s expected input argument %d, %s, to have 3 elements.', ...
        func_name, arg_pos, var_name)
    
    % The first element of REFVEC (cells/angleunit) must be positive.
    assert(refvec(1) > 0, ...
        'map:convertspatialref:cellsPerAngleUnitNotPositive', ...
        'Function %s expected the first element of %s to be positive.', ...
        func_name, var_name)
    
    % Assume 'cells'.
    rasterInterpretation = 'cells';
    
    % Compute other defining properties from inputs.
    firstCornerLat = firstCornerLatitude(refvec(2), refvec(1), rasterSize(1));
    firstCornerLon = refvec(3);
    
    deltaLatDenominator = refvec(1);
    deltaLonDenominator = refvec(1);
    
    % Invoke constructor and interpret errors in the case of inconsistent
    % combinations of property values.
    R = constructGeoRasterReference(rasterSize, rasterInterpretation, ...
        firstCornerLat, firstCornerLon, ...
        1, deltaLatDenominator, 1, deltaLonDenominator);
end

%--------------------------------------------------------------------------

function corner = firstCornerLatitude(northernLimit, sampleDensity, nrows)
% This function uses the same computational strategy as:
%            map/private/firstCorner.m
% Positive sampleDensity is assumed.

northernLimitOverDelta = northernLimit * sampleDensity;
N = round(northernLimitOverDelta);
if abs(northernLimitOverDelta - N) <= 2*eps(N)
    % In many cases the corner position is an integer multiple of the
    % sample spacing (delta = 1/sampleDensity).  If that's not quite the
    % case, but their ratio is within 2*eps of the nearest integer, snap
    % the ratio to that integer value. Moreover, if it's also true that the
    % sample density can be exactly represented as a "nice" ratio of two
    % integers, use that representation in the corner computation.
    [deltaNumerator, deltaDenominator] ...
        = map.rasterref.internal.simplifyRatio(1,sampleDensity);
    corner = deltaNumerator * (N - nrows) / deltaDenominator;
else
    wholeNumberOffset = fix(northernLimit);
    [oNum, oDen] = rat(northernLimit - wholeNumberOffset);
    [dDen, dNum] = rat(sampleDensity);
    if abs(wholeNumberOffset + (oNum / oDen) - northernLimit) ...
            < 5*eps(northernLimit) && sampleDensity == dDen / dNum
        % Try an alternate rational approximation, as long as it is
        % reasonable with respect to machine precision.
        
        % Least common multiple of center denominator and
        % 1/sampleDensity denominator
        lcmDen = lcm(oDen, dDen);
        
        corner = wholeNumberOffset ...
            + (oNum * (lcmDen/oDen) - nrows * dNum * (lcmDen/dDen)) / lcmDen;
    else
        % Use naive formula.
        corner = northernLimit - nrows/sampleDensity;
    end
end
