function [latlim, lonlim] = gratbounds(mstruct)
%GRATBOUNDS Geographic limits for latitude-longitude graticule
%
%   [LATLIM, LONLIM] = GRATBOUNDS(MSTRUCT) computes limits that are
%   sufficient for displaying a graticule on map defined by the map
%   projection structure MSTRUCT.  The limits should be as tight as
%   possible without causing any part of the graticule to be missing.
%   For maps that are framed exactly by geographic quadrangles --
%   cylindrical projections with their origin on the equator, for
%   example -- it is possible to provide an exact fit.  In other cases
%   -- projections with arbitrary obliquity, for example -- the limits
%   are set to cover the entire planet.

% Copyright 2008-2010 The MathWorks, Inc.

D90  = fromDegrees(mstruct.angleunits, 90);
D180 = 2 * D90;

if mprojIsAzimuthal(mstruct.mapprojection)
    if mstruct.origin(1) == -D90
        % South polar azimuthal
        latlim = -D90 + [0 mstruct.flatlimit(2)];
    elseif mstruct.origin(1) == D90
        % North polar azimuthal
        latlim = D90 - [mstruct.flatlimit(2) 0];
    else
        % General azimuthal; origin at neither pole
        latlim = [-D90 D90];
    end
    lonlim = [-D180 D180];
else
    longitudeShiftOnly ...
        = (mstruct.origin(1) == 0) && (mstruct.origin(3) == 0);
    if longitudeShiftOnly || projectionIsNonRotational(mstruct)
        latlim = mstruct.flatlimit;
        lonlim = mstruct.flonlimit + mstruct.origin(2);
    else
        latlim = [ -D90  D90];
        lonlim = [-D180 D180];
    end
end

%-----------------------------------------------------------------------

function tf = projectionIsNonRotational(mstruct)

tf = (mstruct.origin(3) == 0) ...
    && any(strcmp(mstruct.mapprojection, ...
          {'utm', 'tranmerc', 'lambertstd', 'cassinistd', ...
           'eqaconicstd', 'eqdconicstd', 'polyconicstd'}));
