function dist = distdim(dist,from,to,sphere)
%DISTDIM  Convert length units
%
%   DISTDIM has been replaced by UNITSRATIO, but will be maintained for
%   backward compatibility.
%
%   distOut = DISTDIM(distIn, FROM, TO) converts distIn from the units
%   specified by FROM to the units specified by TO.  FROM and TO are
%   case-insensitive, and may equal any of the following:
%
%        'meters' or 'm'
%        'feet'   or 'ft'              <== U.S. survey feet
%        'kilometers'    or 'km'
%        'nauticalmiles' or 'nm'
%        'miles', 'statutemiles', 'mi', or 'sm'       <== statute miles
%        'degrees' or 'deg'
%        'radians' or 'rad'
%
%   If either FROM or TO indicates angular units ('degrees' or
%   'radians'), the conversion to or from linear distance is made along
%   a great circle arc on a sphere with a radius of 6371 km, the mean
%   radius of the Earth.
%
%   distOut = DISTDIM(distIn, FROM, TO, RADIUS), where one of the units,
%   either FROM or TO, indicates angular units and the other unit indicates
%   length units, uses a great circle arc on a sphere of the given radius.
%   The specified length units must apply to RADIUS as well as to the input
%   distance (when FROM indicates length) or output distance (when TO
%   indicates length).  If neither FROM nor TO indicates angular units, or
%   if both do, then the value of RADIUS is ignored.
%
%   distOut = DISTDIM(distIn, FROM, TO, SPHERE), where either FROM or TO
%   indicates angular units, uses a great circle arc on a sphere
%   approximating a body in the Solar System.  SPHERE may be one of the
%   following: 'sun', 'moon', 'mercury', 'venus', 'earth', 'mars',
%   'jupiter', 'saturn', 'uranus', 'neptune', or 'pluto', and is
%   case-insensitive.  If neither TO nor FROM is angular, SPHERE is
%   ignored.
%
%   Exercise caution with 'feet' and 'miles'
%   ----------------------------------------
%   DISTDIM interprets 'feet' and 'ft' as U.S. survey feet, and does not
%   support international feet at all.  In contrast, UNITSRATIO follows
%   the opposite, and more standard approach, interpreting both 'feet'
%   and 'ft' as international feet.  UNITSRATIO provides separate
%   options, including 'survey feet' and 'sf', to indicate survey feet.
%
%   By definition, one international foot is exactly 0.3048 meters and
%   one U.S. survey foot is exactly 1200/3937 meters.  For many
%   applications, the difference is significant.
%
%   Most projected coordinate systems use either the meter or the survey
%   foot as a standard unit. International feet are less likely to be
%   used, but do occur sometimes.
%
%   Likewise, DISTDIM interprets 'miles' and 'mi' as statute miles (also
%   known as U.S. survey miles), and does not support international
%   miles at all.  By definition, one international mile is 5280
%   international feet and one statute mile is 5280 survey feet.
%
%   You can evaluate:
%
%       unitsratio('millimeter','statute mile') ...
%           - unitsratio('millimeter','mile')
%
%   to see that the difference between a statute mile and an
%   international mile is just over three millimeters.  This may seem
%   like a very small amount over the length of a single mile, but
%   mixing up these units could result in a significant error over a
%   sufficiently long baseline.
%
%   Originally, the behavior of DISTDIM with respect to 'miles' and 'mi'
%   was documented only indirectly, via the now-obsolete UNITSTR
%   function.  As with feet, UNITSRATIO takes a more standard approach.
%   UNITSRATIO interprets 'miles' and 'mi' as international miles, and
%   'statute miles' and 'sm' as statute miles.  (UNITSRATIO accepts
%   several other values for each of these units; see the UNITSRATIO
%   help for further information.)
%
%   Replacing DISTDIM
%   -----------------
%   If both FROM and TO are known at the time of coding, then you may be
%   able to replace DISTDIM with a direct conversion utility, as in the
%   following examples:
%
%            distdim(dist,'nm',km') -->  nm2km(dist)
%
%            distdim(dist,'sm','deg') --> sm2deg(dist)
%
%       distdim(dist, 'rad', 'km', 'moon') --> rad2km(dist,'moon')
%
%   If the there is no appropriate direct conversion utility, or you won't
%   know the values of FROM and/or TO until run time, you can
%   generally replace:
%
%          distdim(dist, FROM, TO)
%
%   with:
%
%          unitsratio(TO, FROM) * dist
%
%   If you are using units of feet or miles, see the cautionary note
%   above about how they are interpreted. For example, with distIn in
%   meters and distOut in survey feet,
%
%          distOut = distdim(distIn, 'meters', 'feet');
%
%   should be replaced with:
%
%          distOut = unitsratio('survey feet','meters') * distIn
%
%   Saving a multiplicative factor from UNITSRATIO and using it to
%   convert in a separate step can make code cleaner and more efficient
%   than using DISTDIM.  For example, replace:
%
%           dist1_meters = distdim(dist1_nm, 'nm', 'meters');
%           dist2_meters = distdim(dist2_nm, 'nm', 'meters');
%
%   with:
%
%           metersPerNM = unitsratio('meters','nm');
%           dist1_meters = metersPerNM * dist1_nm;
%           dist2_meters = metersPerNM * dist2_nm;
%
%   UNITSRATIO does not perform great-circle conversion between units of
%   length and angle, but it can be easily combined with other functions
%   to do so. For example, to convert degrees to meters along a
%   great-circle arc on a sphere approximating the planet Mars, you
%   could replace:
% 
%          distdim(dist, 'degrees', 'meters', 'mars')
%         
%   with:
%         
%          unitsratio('meters','km') * deg2km(dist, 'mars')
%
%   See also  DEG2KM, DEG2NM, DEG2SM, KM2DEG, KM2NM, KM2RAD,
%             KM2SM,  NM2DEG, NM2KM,  NM2RAD, NM2SM, RAD2KM,
%             RAD2NM, RAD2SM, SM2DEG, SM2KM,  SM2NM, SM2RAD,
%             UNITSRATIO.

% Copyright 1996-2017 The MathWorks, Inc.

narginchk(3,4)
if nargin < 4
    sphere = 'earth';
end

% Check the FROM and TO for supported units,
% returning standard names in lower case.
from = convertStringsToChars(from);
from = unitstrd(from);

to = convertStringsToChars(to);
to = unitstrd(to);

% Warn and convert to real if DIST is complex.
dist = ignoreComplex(dist, mfilename, 'DIST');

% Convert units only if there's something to change.
if ~strcmp(from, to)
    dist = applyconversion(dist, from, to, sphere);
end

%-----------------------------------------------------------------------

function dist = applyconversion(dist, from, to, sphere)

% Note:
%   The following switch constructs have otherwise clauses for
%   completeness, but if UNITSTR has done its job, then
%   assertUnsupportedUnits will never be called.

toIsSupported   = true;
fromIsSupported = true;
 
switch from
    case 'degrees'
        switch to
            case 'kilometers',        dist = deg2km(dist,sphere);
            case 'nauticalmiles',     dist = deg2nm(dist,sphere);
            case 'radians',           dist = deg2rad(dist);
            case 'statutemiles',      dist = deg2sm(dist,sphere);
            case 'meters',            dist = 1000*deg2km(dist,sphere);
            case 'feet',              dist = 5280*deg2sm(dist,sphere);
            otherwise,                toIsSupported = false;
        end

    case 'kilometers'
        switch to
            case 'degrees',           dist = km2deg(dist,sphere);
            case 'nauticalmiles',     dist = km2nm(dist);
            case 'radians',           dist = km2rad(dist,sphere);
            case 'statutemiles',      dist = km2sm(dist);
            case 'meters',            dist = 1000*dist;
            case 'feet',              dist = 5280*km2sm(dist);
            otherwise,                toIsSupported = false;
        end

    case 'meters'
        switch to
            case 'degrees',           dist = km2deg(dist/1000,sphere);
            case 'nauticalmiles',     dist = km2nm(dist/1000);
            case 'radians',           dist = km2rad(dist/1000,sphere);
            case 'statutemiles',      dist = km2sm(dist/1000);
            case 'kilometers',        dist = dist/1000;
            case 'feet',              dist = 5280*km2sm(dist/1000);
            otherwise,                toIsSupported = false;
        end

    case 'nauticalmiles'
        switch to
            case 'degrees',           dist = nm2deg(dist,sphere);
            case 'kilometers',        dist = nm2km(dist);
            case 'meters',            dist = 1000*nm2km(dist);
            case 'radians',           dist = nm2rad(dist,sphere);
            case 'statutemiles',      dist = nm2sm(dist);
            case 'feet',              dist = 5280*nm2sm(dist);
            otherwise,                toIsSupported = false;
        end

    case 'radians'
        switch to
            case 'degrees',           dist = rad2deg(dist);
            case 'kilometers',        dist = rad2km(dist,sphere);
            case 'meters',            dist = 1000*rad2km(dist,sphere);
            case 'nauticalmiles',     dist = rad2nm(dist,sphere);
            case 'statutemiles',      dist = rad2sm(dist,sphere);
            case 'feet',              dist = 5280*rad2sm(dist,sphere);
            otherwise,                toIsSupported = false;
        end

    case 'statutemiles'
        switch to
            case 'degrees',           dist = sm2deg(dist,sphere);
            case 'kilometers',        dist = sm2km(dist);
            case 'meters',            dist = 1000*sm2km(dist);
            case 'nauticalmiles',     dist = sm2nm(dist);
            case 'radians',           dist = sm2rad(dist,sphere);
            case 'feet',              dist = 5280*dist;
            otherwise,                toIsSupported = false;
        end

    case 'feet'
        switch to
            case 'degrees',           dist = sm2deg(dist/5280,sphere);
            case 'nauticalmiles',     dist = sm2nm(dist/5280);
            case 'radians',           dist = sm2rad(dist/5280,sphere);
            case 'statutemiles',      dist = dist/5280;
            case 'kilometers',        dist = sm2km(dist/5280);
            case 'meters',            dist = 1000*sm2km(dist/5280);
            otherwise,                toIsSupported = false;
        end

    otherwise
        fromIsSupported = false;
end

assert(toIsSupported, 'map:distdim:UnsupportedToUnits', ...
    'Unsupported ''TO'' units: %s.', to)

assert(fromIsSupported, 'map:distdim:UnsupportedFromUnits', ...
    'Unsupported ''FROM'' units: %s.', from)
