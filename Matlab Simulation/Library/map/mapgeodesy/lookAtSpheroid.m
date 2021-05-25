function [lat,lon,slantRange] = lookAtSpheroid(lat0,lon0,h0,az,tilt,s)
%lookAtSpheroid Line of sight intersection with oblate spheroid
%
%   [LAT,LON,SLANTRANGE] = lookAtSpheroid(LAT0,LON0,H0,AZ,TILT,SPHEROID)
%   computes the latitude and longitude (LAT and LON) of the intersection
%   of the line of sight from a viewpoint in space with the surface of an
%   oblate spheroid. The geodetic coordinates of the viewpoint are given by
%   LAT0, LON0, and H0. The geodetic coordinates refer to the reference
%   body specified by the spheroid object, SPHEROID. The direction of sight
%   is indicated by an AZIMUTH angle, clockwise from North, and a TILT
%   angle with respect to the local vertical. The "slant range" (3D
%   Euclidean) distance from the viewpoint to the intersection is
%   optionally returned as the third output. All angles are in degrees.
%   H0 must be in units that match the spheroid input.
%
%   Example
%   -------
%   % Viewpoint in geostationary orbit
%   spheroid = wgs84Ellipsoid('km');
%   lat0 = 0;
%   lon0 = -100;
%   h0 = 35786; % km -- matches units of spheroid
%   az = 45;
%   tilt = 6;
%   [lat,lon,slantrange] = lookAtSpheroid(lat0,lon0,h0,az,tilt,spheroid)
%
% See also GEODETIC2AER.

% Copyright 2016-2019 The MathWorks, Inc.

    validateattributes(lat0,{'single','double'},{'real','>=',-90,'<=',90},'','lat0')
    validateattributes(lon0,{'single','double'},{'real','finite'},'','lon0')
    validateattributes(h0,{'single','double'},{'real','nonnegative','finite'},'','h0')
    validateattributes(az,{'single','double'},{'real','finite'},'','az')
    validateattributes(tilt,{'single','double'},{'real','nonnegative','<=',180},'','tilt')
    if ~isscalar(s) || ~isa(s,'map.geodesy.Spheroid')
        error(message('map:geodesy:expectedScalarSpheroid',upper('spheroid')))
    end
    
    % Convert angles to direction cosines in the local NED system.
    [uNorth, vEast, wDown] = aztilt2nedv(az, tilt);
    
    % North-east-down directions rotated to spheroid-centric Cartesian system.
    [ux, uy, uz] = ned2ecefv(uNorth, vEast, wDown, lat0, lon0);
    
    % Length of the direction vector
    u = hypot(hypot(ux,uy),uz);
    
    % Convert direction vector to a unit vector.
    ux = ux ./ u;
    uy = uy ./ u;
    uz = uz ./ u;
    
    % Observer location in spheroid-centric Cartesian system
    [X0,Y0,Z0] = geodetic2ecef(s,lat0,lon0,h0);
    
    % Axes of oblate spheroid
    a = s.SemimajorAxis;
    b = s.SemiminorAxis;
    
    % Normalize observer locations, and adjust direction vector, and find
    % normalized intersection points.
    [x,y,z,t] = intersectInNormalizedSystem(X0/a, Y0/a, Z0/b, ux, uy, (a/b)*uz);
    
    % Rescale the intersection to the spheroid-centric system and convert to
    % geodetic coordinates. No need for ecef2geodetic to return a third output
    % because the height should be zero to within computational precision.
    [lat,lon] = ecef2geodetic(s, a*x, a*y, b*z);
    
    % Rescale the parameter, t, converting to absolute length.
    slantRange = a*t;
end


function [x,y,z,t] = intersectInNormalizedSystem(xn, yn, zn, vx, vy, vz)
% Compute the intersection points, if they exist, in system in which x and
% y are normalized have been normalized by the semimajor axis a, z has
% been normalized by the semiminor axis, and the z-component of the
% direction vector has been adjusted accordingly.

    % Solve the following for the scaled parameter t:
    %
    %    (xn + vx.*t).^2 + (yn + vy.*t).^2 + (zn + vz.*t).^2 = 1
    %
    % which is equivalent to the quadratic:
    %
    %      A.*t.*2 + B.*t + C = 0,
    %
    % where:
    %
    %      A = vx.^2 + vy.^2 + vz.^2
    %      B = 2*(vx.*xn + vy.yn + vz.*zn)
    %      C = xn.*2 + yn.*2 + zn.*2 - 1
    
    A = vx.^2 + vy.^2 + vz.^2;
    
    % The following will be negative because (xn,yn,zn) and (vx,vy,vz) are
    % roughly opposing in direction.
    halfB = vx.*xn + vy.*yn + vz.*zn;
    
    % One quarter of the discriminant: D/4 = (B/2).^2 - A.*C
    % ... after expanding, canceling terms, and factoring:
    quarterD = A - ( ...
        + (vx.*yn - vy.*xn).^2 ...
        + (vy.*zn - vz.*yn).^2 ...
        + (vz.*xn - vx.*zn).^2);
    
    % Return NaN when the discriminant is negative.
    q = (quarterD >= 0);
    t = NaN(size(q));
    
    % Otherwise take the smaller of the two real roots:
    %
    %        t = (-B - sqrt(D)) ./ (2*A)
    %          = -(B/2 + sqrt(D/4)) ./ A
    %
    % We know that halfB and quarterD are fully expanded, because both are
    % computed from arithmetic operations that involve all 6 inputs. But A
    % is computed from only 3 of the inputs, so it may need deliberate
    % expansion in order to match halfB, quarterD, and q in size.
    A = expandSize(A, size(q)); 
    t(q) = -(halfB(q) + sqrt(quarterD(q))) ./ A(q);
    
    % When looking in the opposite direction of a point on the spheroid,
    % t will be negative, because flipping the sign is essentially the same as
    % flipping the direction of the vector (vx, vy, vz). Return NaN in such
    % cases.
    t(t < 0) = NaN;
    
    % Subsitute the result into the parametric equations.
    x = xn + vx.*t;  % X/a
    y = yn + vy.*t;  % Y/a
    z = zn + vz.*t;  % Z/b
end


function A = expandSize(A, sz)
% Assume that size(A) matches the size vector sz except in certain
% dimensions for which size(A,dim) is 1. Replicate A within those
% dimensions to make its size equal to sz.
    sizeA = size(A);
    if ~isequal(sizeA, sz)
        % Ensure that sizeA and sz have the same length.
        sizeA(end:length(sz)) = 1;
        A = repmat(A, sz - sizeA + 1);
    end
end
