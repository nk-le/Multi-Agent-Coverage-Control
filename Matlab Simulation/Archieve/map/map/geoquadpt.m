function [latlim, lonlim] = geoquadpt(lat, lon)
%GEOQUADPT Geographic quadrangle bounding scattered points
%
%   [LATLIM, LONLIM] = GEOQUADPT(LAT, LON) returns the limits of the
%   tightest possible quadrangle that bounds a set of points with
%   geographic coordinates LAT and LON. LATLIM is a latitude limit vector
%   of the form [southern_limit northern_limit].  LONLIM is a longitude
%   limit vector of the form [western_limit eastern_limit].  The elements of
%   LONLIM are wrapped to the interval [-180 180] and are not necessarily
%   in ascending order.  All angles are in degrees.
%
%   In most cases, TF = ingeoquad(LAT, LON, LATLIM, LONLIM) will return
%   true, but TF may be false for points on the edges of the quadrangle,
%   due to round off.  TF will also be false for elements of LAT that fall
%   outside the interval [-90 90] and elements of LON that are not finite.
%
%   See also BUFGEOQUAD, GEOQUADLINE, INGEOQUAD, OUTLINEGEOQUAD

% Copyright 2012 The MathWorks, Inc.

% Work with row vectors.
lon = lon(:)';
lat = lat(:)';

% Keep only points for which both coordinates have finite values.
discard = isnan(lon) | isinf(lon) | isnan(lat) | isinf(lat);
lat(discard) = [];
lon(discard) = [];

if isempty(lat)
    % No points were provided; meaningful limits cannot be computed.
    latlim = [];
    lonlim = [];
else
    % There's at least one point.
    
    % Latitude limits are easy.
    % We expect -90 <= lat <= 90, but clamp latlim just in case.
    latlim = [max(min(lat),-90) min(max(lat),90)];
    
    % Remove polar points before computing longitude limits.
    lon(lat <= -90 | lat >= 90) = [];
    
    if isempty(lon)
        % All points are polar. Cover all longitudes so that subsequent
        % calls to intersectgeoquad work as expected.
        lonlim = [-180 180];
    else
        % There's at least one non-polar point.
        
        % Wrap to the half open interval [-180 180).
        lon = mod(lon + 180, 360) - 180;
        
        % Remove non-unique longitudes.
        lon = unique(lon);
        
        if isscalar(lon)
            % There's only one unique longitude among the non-polar points,
            % resulting in degenerate limits.
            lonlim = lon([1 1]);
        else
            % We can think of the unique longitudes as points scattered
            % along a circle. Between each pair of adjacent points, there's
            % a gap (an interval, modulo 360). In longitude, our bounding
            % quadrangle should span the complement of the largest gap.
            %
            % 1. Prepare to include all intervals in a sequential
            %    difference sorting the non-unique longitudes and
            %    appending (360 + the first longitude) to the end.
            %
            % 2. Compute the difference between each longitude and the
            %    next, modulo 360.
            %
            % 3. Find the largest difference (the largest gap, that is).
            %    Select the first one in the event of a tie).
            %
            % 4. Assign the _eastern_ limit of this gap to lonlim(1).
            %
            % 5. Assign the _western_ limit of the gap to lonlim(2).
            
            lon = sort(lon);
            lon(end+1) = lon(1) + 360;
            delta = mod(diff(lon), 360);
            k = find(delta == max(delta), 1);
            lonlim = wrapTo180(lon([k+1, k]));
            if lonlim(1) == 180
                lonlim(1) = -180;
            end
            if lonlim(2) == -180
                lonlim(2) = 180;
            end
        end
    end
end
