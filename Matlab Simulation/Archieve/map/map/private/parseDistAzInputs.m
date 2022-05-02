function [useGeodesic, lat1, lon1, lat2, lon2, ellipsoid, ...
    units, insize, useAngularDistance] = parseDistAzInputs(varargin)

% Adapted from procedures originally replicated in DISTANCE and AZIMUTH.

% Copyright 1996-2017 The MathWorks, Inc.

% Handle optional first input argument
if (nargin >= 1) && (ischar(varargin{1}) || ...
        isstring(varargin{1}) || iscellstr(varargin{1}))
    trackstr = validatestring(varargin{1}, {'gc','rh'}, 1);
    varargin(1) = [];
    useGeodesic = strcmp(trackstr,'gc');
else
    useGeodesic = true;
end

in1 = varargin{1};
in2 = varargin{2};

n = numel(varargin);
if (n > 2)
    in3 = varargin{3};
end
if (n > 3)
    in4  = varargin{4};
end
if (n > 4)
    in5  = varargin{5};
end
if (n > 5)
    in6  = varargin{6};
end

ellipsoid = [];
units = 'degrees';
useAngularDistance = false;

if (n == 2) || (n == 3) || ...
        ((n == 4) && (ischar(in4) || isstring(in4) || iscellstr(in4)))
    if size(in1,2) == 2 && ndims(in1) == 2 && ...
	   size(in2,2) == 2 && ndims(in2) == 2
        lat1 = in1(:,1);
        lon1 = in1(:,2);
        lat2 = in2(:,1);
        lon2 = in2(:,2);
    else
        error(['map:' mfilename ':mapError'], ...
            'Incorrect latitude and longitude data matrices');
    end

    if (n == 3)
        if ischar(in3) || isstring(in3) || iscellstr(in3)
	        units  = in3;
        else
            ellipsoid = in3;
        end
    end

    if (n == 4)
	    ellipsoid = in3;
	    units     = in4;
    end

else % (n == 4) || (n == 5) || (n == 6)

    lat1 = in1;
    lon1 = in2;
    lat2 = in3;
    lon2 = in4;
    
    if (n == 5)
        if ischar(in5) || isstring(in5) || iscellstr(in5)
	        units = in5;
        else
            ellipsoid = in5;
        end
    end
    
    if (n == 6)
	    ellipsoid = in5;
	    units     = in6;
    end
end

if isempty(ellipsoid)
    % If ELLIPSOID was omitted, use a unit sphere and express
    % distance as an angle
    ellipsoid = [1 0];
    useAngularDistance = true;
else
    ellipsoid = checkellipsoid(ellipsoid, 'DISTANCE', 'ELLIPSOID');
end

% Check for matching lat-lon sizes and expand scalar inputs if necessary.
[lat1, lon1, lat2, lon2, insize] = expandScalarInputs(lat1, lon1, lat2, lon2);
if isempty(insize)
    % Non-scalar arguments have inconsistent sizes.
    error(['map:' mfilename ':inconsistentLatLonSizes'], ...
        'Inconsistent dimensions for latitude and longitude')
end

% Make sure input angles are real
lat1 = real(lat1);
lon1 = real(lon1);
lat2 = real(lat2);
lon2 = real(lon2);

% Make sure angles are in radians and convert the
% input coordinates to column vectors
[lat1, lon1, lat2, lon2] ...
    = toRadians(units, lat1(:), lon1(:), lat2(:), lon2(:));
