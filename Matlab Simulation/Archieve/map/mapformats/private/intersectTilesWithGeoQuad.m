function tileNames = intersectTilesWithGeoQuad( ...
    latlim, lonlim, tileNames, lonlimW, lonlimE, latlimS, latlimN)
%INTERSECTTILESWITHGEOQUAD Intersect tiles with latitude-longitude quadrangle
%
%    tileNames = intersectTilesWithGeoQuad(latlim, lonlim, tileNames, ...
%    lonlimW, lonlimE, latlimS, latlimN) trims the input list of all tile
%    names, found in the cell array, tileNames, to match only those that
%    intersect the requested quadrangle limits, defined by the two-element
%    vectors, latlim and lonlim. Each tile's quadrangle is defined by the
%    double arrays latlimS (southern limits) and latlimN (northern limits),
%    and the longitude coordinates in the double arrays, lonlimW (western
%    limits) and lonlimE (eastern limits). tileNames is {} if there is no
%    intersection.

%   Copyright 2011-2020 The MathWorks, Inc.

if lonlim(1) < lonlim(2)
    % case where dateline is not crossed: lonlim(1) < lonlim(2)
    tf = findMatchingTiles(latlim, lonlim, lonlimW, lonlimE, latlimS, latlimN);
else
    % case where the dateline is crossed: lonlim(1) >= lonlim(2)
    lmax = lonlim(2);
    lonlim(2) = 180;
    
    % do eastern side of the dateline first
    tfEast = findMatchingTiles(latlim, lonlim, lonlimW, lonlimE, latlimS, latlimN);
    
    % do western side of the dateline second
    lonlim(1) = -180; 
    lonlim(2) = lmax;
    tfWest = findMatchingTiles(latlim, lonlim, lonlimW, lonlimE, latlimS, latlimN);
    
    % Merge the indices.
    tf = tfEast | tfWest;
end

% Set tileNames to include only tiles that intersect.
tileNames = tileNames(tf);

%--------------------------------------------------------------------------

function tf = findMatchingTiles( ...
    latlim, lonlim, lonlimW, lonlimE, latlimS, latlimN)
% Return a logical array that is true if the quadrangle defined by latlim
% and lonlim lies within the quadrangle defined by the elements in the X
% and Y MIN/MAX variables.

a = latlim(1);
b = latlim(2);
c = latlimS;
d = latlimN;
latMatchingTiles = ~((a >= d) | (b <= c));

a = lonlim(1);
b = lonlim(2);
c = lonlimW;
d = lonlimE;
lonMatchingTiles = ~((a >= d) | (b <= c));

tf = latMatchingTiles & lonMatchingTiles;
