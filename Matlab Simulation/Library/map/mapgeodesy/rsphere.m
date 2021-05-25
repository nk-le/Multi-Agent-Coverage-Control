function r = rsphere(varargin)
%RSPHERE  Radii of auxiliary spheres
%
%   R = RSPHERE('biaxial',ELLIPSOID) computes the arithmetic mean of the
%   semimajor (a) and semiminor (b) axes of the specified ellipsoid,
%   (a + b) / 2.  ELLIPSOID is a reference ellipsoid (oblate spheroid)
%   object or a vector of the form [semimajor_axis, eccentricity].
%
%   R = RSPHERE('biaxial',ELLIPSOID, METHOD) computes the arithmetic mean
%   if METHOD is 'mean' and the geometric mean, sqrt(a*b), if METHOD is
%   'norm'.
%
%   R = RSPHERE('triaxial',ELLIPSOID) computes the triaxial arithmetic mean
%   of the semimajor (a) and semiminor (b) axes of the ellipsoid, (2a+b)/3.
%
%   R = RSPHERE('triaxial',ELLIPSOID, METHOD) computes the arithmetic mean
%   if METHOD is 'mean' and the triaxial geometric mean, (a^2 * b)^(1/3),
%   if METHOD is 'norm'.
%
%   R = RSPHERE('eqavol',ELLIPSOID) returns the radius of a sphere with a
%   volume equal to that of the ellipsoid.
%
%   R = RSPHERE('authalic',ELLIPSOID) returns the radius of a sphere with a
%   surface area equal to that of the ellipsoid.
%
%   R = RSPHERE('rectifying',ELLIPSOID) returns the radius of a sphere
%   with meridional distances equal to those of the ellipsoid.
%
%   R = RSPHERE('curve',ELLIPSOID, LAT) computes the arithmetic mean of
%   the transverse and meridional radii of curvature at the latitude LAT.
%   LAT is in degrees.
%
%   R = RSPHERE('curve',ELLIPSOID, LAT, METHOD) computes an arithmetic
%   mean if the METHOD is 'mean' and a geometric mean if METHOD is
%   'norm'.
%
%   R = RSPHERE('euler',LAT1, LON1, LAT2, LON2, ELLIPSOID) computes the
%   Euler radius of curvature at the midpoint of the geodesic arc defined
%   by the endpoints (LAT1,LON1) and (LAT2,LON2). LAT1, LON1, LAT2, and
%   LON2 are in degrees.
%
%   R = RSPHERE('curve', ..., ANGLEUNITS) and
%   R = RSPHERE('euler', ..., ANGLEUNITS) use ANGLEUNITS to specify the
%   units of the latitude and longitude inputs. ANGLEUNITS can be 'degrees'
%   or 'radians'.
%
%   See also RCURVE.

% Copyright 1996-2019 The MathWorks, Inc.

%  Reference: D. H. Maling, Coordinate Systems and Map
%             Projections, 2nd Edition Permagon Press, 1992, pp.. 77-79.

narginchk(2, Inf)

typeOfRadius = validatestring(varargin{1}, ...
    {'biaxial','triaxial','curve','eqavol','authalic','rectifying','euler'}, ...
    'RSPHERE','',1);

if ~strcmp(typeOfRadius,'euler')
    ellipsoid = map.geodesy.internal.validateEllipsoid(varargin{2},'RSPHERE','ELLIPSOID',2);
    
    switch typeOfRadius
        case 'biaxial'
            % Mean or norm for biaxial (meridian) ellipse
            
            a = ellipsoid(1);
            b = minaxis(ellipsoid);
            
            if nargin >= 3
                method = validatestring(varargin{3}, {'mean','norm'}, ...
                    'RSPHERE','METHOD',3);
            else
                method = 'mean';
            end
            
            if strcmp(method,'mean')
                r = (a + b) / 2;
            else
                r = sqrt(a * b);
            end
            
        case 'triaxial'
            % Mean or norm for triaxial ellipsoid
            
            a = ellipsoid(1);
            b = minaxis(ellipsoid);
            
            if nargin >= 3
                method = validatestring(varargin{3}, {'mean','norm'}, ...
                    'RSPHERE','METHOD',3);
            else
                method = 'mean';
            end
            
            if strcmp(method,'mean')
                r = (2*a + b) / 3;
            else
                r = (a * a * b) .^ (1/3);
            end
            
        case 'curve'
            %  Averaged radii of curvature
            
            if nargin > 2
                switch nargin
                    case 3
                        if ischar(varargin{3}) || isStringScalar(varargin{3})
                            lat = 45;
                            method = validatestring(varargin{3}, ...
                                {'mean','norm'}, 'RSPHERE','METHOD',3);
                        else
                            lat = varargin{3};
                            method = 'mean';
                        end
                        units = 'degrees';
                    case 4
                        lat = varargin{3};
                        method = validatestring(varargin{4}, ...
                            {'mean','norm'}, 'RSPHERE','METHOD',4);
                        units = 'degrees';
                    otherwise
                        lat = varargin{3};
                        method = validatestring(varargin{4}, ...
                            {'mean','norm'}, 'RSPHERE','METHOD',4);
                        units = checkangleunits(varargin{5});
                end
            else
                lat = 45;
                method = 'mean';
                units = 'degrees';
            end
            
            %  Meridional and transverse radii of curvature
            rho = rcurve('meridian',ellipsoid,lat,units);
            nu  = rcurve('transverse',ellipsoid,lat,units);
            
            %  Radius of the sphere
            if strcmp(method,'mean')
                r = (rho + nu) / 2;
            else
                r = sqrt(rho .* nu);
            end
            
        case 'eqavol'
            %  Equal Volume Sphere
            
            a = ellipsoid(1);
            f = ecc2flat(ellipsoid(2));
            r = a * (1 - f*(1/3 + f/9));
            
        case 'authalic'
            %  Equal Surface Area Sphere
            
            a = ellipsoid(1);
            e = ellipsoid(2);
            if e > 0
                f1 = a^2 / (2);
                f2 = (1 - e^2) / (2*e);
                f3 = log((1+e) / (1-e));
                r = sqrt(f1 * (1 + f2 * f3));
            else
                r = a;
            end
            
        case 'rectifying'
            %  Equal Meridian Distance Sphere
            
            a = ellipsoid(1);
            n = ecc2n(ellipsoid);
            n2 = n^2;
            r = a * (1 - n) * (1 - n2) * (1 + n2*(9/4 + n2*225/64));
    end
else
    %  Euler radius of curvature
    
    if nargin < 6
        error(message('map:validate:invalidArgCount'))
    end
    
    ellipsoid = map.geodesy.internal.validateEllipsoid(varargin{6},'RSPHERE','ELLIPSOID',6);
    
    if nargin >= 7
        units = checkangleunits(varargin{7});
    else
        units = 'degrees';
    end
    
    %  Convert inputs to radians
    
    [lat1, lon1, lat2, lon2] = toRadians(units, varargin{2:5});
    
    %  Compute the mid-latitude point
    
    latmid = lat1 + (lat2 - lat1)/2;
    
    %  Compute the azimuth
    
    [~,az] = distance('gc',lat1,lon1,lat2,lon2,ellipsoid,'radians');
    
    %  Compute the meridional and transverse radii of curvature
    
    rho = rcurve('meridian',ellipsoid,latmid,'radians');
    nu  = rcurve('transverse',ellipsoid,latmid,'radians');
    
    %  Compute the radius of the arc from point 1 to point 2
    %  Ref:  Maling, p. 76.
    
    den = rho .* sin(az).^2 + nu .* cos(az).^2;
    r = rho .* nu ./ den;
    
end
