function latout = doLatitudeConversion(function_name,from,to,varargin)
% DOLATITUDECONVERSION  Compute engine for old latitude conversion functions.
%
%   See also:  AUT2GEOD, CEN2GEOD, CNF2GEOD, ISO2GEOD, GEOD2AUT,
%              GEOD2CEN, GEOD2CNF, GEOD2ISO, GEOD2PAR, GEOD2REC,
%              PAR2GEOD, REC2GEOD.

% Copyright 1996-2017 The MathWorks, Inc.

try
    if numel(varargin) < 1
        error(message('MATLAB:narginchk:notEnoughInputs'));
    elseif numel(varargin) > 3
        error(message('MATLAB:narginchk:tooManyInputs'));
    end
catch exception
    exception.throwAsCaller
end

[latin,ellipsoid,units] = parseLatConvInputs(function_name,varargin{:});
latin = toRadians(units, latin);
latout = convertlat(ellipsoid,latin,from,to,'nocheck');
latout = fromRadians(units, latout);

%--------------------------------------------------------------------------

function [latin,ellipsoid,units] = parseLatConvInputs(function_name,varargin)

latin = varargin{1};
switch(numel(varargin))
    case 1
        ellipsoid = referenceEllipsoid('grs80','km');
        units = 'degrees';
    case 2
        if ischar(varargin{2}) || isStringScalar(varargin{2})
            ellipsoid = referenceEllipsoid('grs80','km');
            units = varargin{2};
        else
            ellipsoid = checkellipsoid( ...
                varargin{2},function_name,'ELLIPSOID',2);
            units = 'degrees';
        end
    case 3
        ellipsoid = checkellipsoid(varargin{2},function_name,'ELLIPSOID',2);
        units = varargin{3};
end
