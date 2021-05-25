function tf = ingeoquad(lat, lon, latlim, lonlim)
%INGEOQUAD True for points inside or on lat-lon quadrangle
%
%   TF = INGEOQUAD(LAT, LON, LATLIM, LONLIM) returns an array TF that
%   has the same size as LAT and LON.  TF(k) is true if and only if the
%   point LAT(k), LON(k) falls within or on the edge of the geographic
%   quadrangle defined by LATLIM and LONLIM.  LATLIM is a vector of the
%   form [southern-limit northern-limit] and LONLIM is a vector of the
%   form [western-limit eastern-limit].  All angles are in units of
%   degrees.
%
%   Example
%   -------
%   % Load and display a DEM including the Korean Peninsula
%   load korea5c
%   R = korea5cR;
%   figure('Color','white')
%   worldmap([20 50],[90 150])
%   geoshow(korea5c,R,'DisplayType','texturemap')
%   demcmap(korea5c)
%
%   % Outline the quadrangle containing the DEM
%   [outlineLat, outlineLon] = outlinegeoquad( ...
%       R.LatitudeLimits, R.LongitudeLimits, 90, 5);
%   geoshow(outlineLat,outlineLon,'DisplayType','line','Color','black')
%
%   % Generate a track that crosses the DEM
%   [lat,lon] = track2(23,110,48,149,[1 0],'degrees',20);
%   geoshow(lat,lon,'DisplayType','line')
%
%   % Identify and mark points on the track that fall within
%   % the quadrangle outlining the DEM
%   tf = ingeoquad(lat,lon,R.LatitudeLimits,R.LongitudeLimits);
%   geoshow(lat(tf),lon(tf),'DisplayType','point')
%
%   See also INPOLYGON, INTERSECTGEOQUAD, OUTLINEGEOQUAD

% Copyright 2007-2020 The MathWorks, Inc.

% Initialize to include all points.
tf = true(size(lat));

% Eliminate points that fall outside the latitude limits.
inlatzone = (latlim(1) <= lat) & (lat <= latlim(2));
tf(~inlatzone) = false;

% Eliminate points that fall outside the longitude limits.
londiff = wrapTo360(lonlim(2) - lonlim(1));
inlonzone = (wrapTo360(lon - lonlim(1)) <= londiff);
tf(~inlonzone) = false;
