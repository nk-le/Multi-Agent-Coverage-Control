function mstruct = resetmstruct(mstruct)
% Process a map projection structure (mstruct) to fill in missing
% properties and resolve inconsistencies.  This includes:
%
% * Ensuring a 3-element origin vector
% * Ensuring that frame limits are bounded by "trimlat" and "trimlon"
% * Re-deriving map limits from frame limits + origin

% Copyright 2008-2016 The MathWorks, Inc.

%  Ensure that a map projection is specified
if isempty(mstruct.mapprojection)
    error('map:resetmstruct:mapprojError', 'No projection specified.')
end

%  Special pre-processing for UTM
if strcmp(mstruct.mapprojection,'utm')
    mstruct = utmdefaults(mstruct);
end

%  Special pre-processing for UPS
if strcmp(mstruct.mapprojection,'ups')
    mstruct = upsdefaults(mstruct);
end

%  Validate the spheroid object/ellipsoid vector (but allow empty)
if ~isempty(mstruct.geoid)
    checkellipsoid(mstruct.geoid, 'resetmstruct', 'mstruct.geoid');
end

%  Frame limits
[mstruct.flatlimit, mstruct.flonlimit] = adjustFrameLimits(mstruct);

%  Projection origin
mstruct.origin = adjustOrigin(mstruct);

%  Standard parallels
if isempty(mstruct.mapparallels)
    mstruct.mapparallels ...
        = defaultStandardParallels(mstruct.nparallels, mstruct.flatlimit);
end

%  Map limits
[mstruct.maplatlimit, mstruct.maplonlimit] = gratbounds(mstruct);

% Label Parallel and Meridian (depend initial values + map limits)
mstruct.mlabelparallel = meridianLabelParallel(mstruct);
mstruct.plabelmeridian = parallelLabelMeridian(mstruct);

defaultColor = get(0,'DefaultAxesXcolor');
defaults = struct( ...
    ... % Reference ellipsoid
    'geoid',          [1 0], ...
    ... % False easting and northing, scalefactor
    'falseeasting',   0, ...
    'falsenorthing',  0, ...
    'scalefactor',    1, ...
    ... % Default Frame Properties
    'frame',          'off', ...          
    'fedgecolor',     defaultColor, ...    
    'ffacecolor',     'none', ...    
    'flinewidth',     2, ...         
    'ffill',          100, ...
    ... % Default Grid Properties
    'grid',           'off', ...          
    'galtitude',      inf, ...       
    'gcolor',         defaultColor, ...       
    'glinestyle',     ':', ...      
    'glinewidth',     0.5, ...      
    'mlinefill',      100, ...       
    'plinefill',      100, ...       
    'mlinevisible',   'on', ...
    'plinevisible',   'on', ...
    'plinelocation',  fromDegrees(mstruct.angleunits,15), ...
    'mlinelocation',  fromDegrees(mstruct.angleunits,30), ...
    ... % Default Label Properties
    'labelunits',     mstruct.angleunits, ...
    'meridianlabel',  'off', ...
    'parallellabel',  'off');

mstruct = applyDefaults(mstruct, defaults);

% These defaults chain off others, so they need to be applied separately.
defaults = struct( ...
    'mlabellocation', mstruct.mlinelocation, ...
    'plabellocation', mstruct.plinelocation);

mstruct = applyDefaults(mstruct, defaults);

% Can't use label rotation with globe.
if strcmp(mstruct.mapprojection,'globe')
    mstruct.labelrotation = 'off';
end

%-----------------------------------------------------------------------

function mstruct = utmdefaults(mstruct)

if isempty(mstruct.zone)
    zone = '31N';
else
    zone = mstruct.zone;
end

ellipsoid = utmgeoid(zone);
ellipsoid = ellipsoid(1,:);

[latlim, lonlim] = utmzone(zone);
if min(latlim) >= 0 && max(latlim) > 0
    % Northern hemisphere
    falsenorthing = 0;
elseif min(latlim) < 0 && max(latlim) <= 0
    % Southern hemisphere
    falsenorthing = 1e7;   % Unit of length: meter
else
    % Both
    falsenorthing = 0;
end

defaults = struct(...
    'zone',           zone, ...
    'geoid',          ellipsoid, ...
    'maplatlimit',    fromDegrees(mstruct.angleunits,latlim), ...
    'maplonlimit',    fromDegrees(mstruct.angleunits,lonlim), ...
    'flatlimit',      fromDegrees(mstruct.angleunits,latlim), ...
    'flonlimit',      fromDegrees(mstruct.angleunits,[-3 3]), ...
    'origin',         fromDegrees(mstruct.angleunits,[0 min(lonlim)+3 0]), ...
    'mlinelocation',  fromDegrees(mstruct.angleunits,1), ...
    'plinelocation',  fromDegrees(mstruct.angleunits,1), ...
    'mlabellocation', fromDegrees(mstruct.angleunits,1), ...
    'plabellocation', fromDegrees(mstruct.angleunits,1), ...
    'falsenorthing',  falsenorthing);

mstruct = applyDefaults(mstruct, defaults);


%-----------------------------------------------------------------------

function mstruct = upsdefaults(mstruct)

if isempty(mstruct.zone)
    zone = 'north';
else
    zone = mstruct.zone;
end

% Defaults in degrees
if strcmp(zone,'north')
    maplatlimit    = [84 90];
    flatlimit      = [-Inf 6];
    origin         = [90 0 0];
    mlinelimit     = [84 89];
    mlabelparallel = 84;
elseif strcmp(zone,'south')
    maplatlimit    = [-90 -80];
    flatlimit      = [-Inf 10];
    origin         = [-90 0 0];
    mlinelimit     = [-89 -80];
    mlabelparallel = -80;
end

defaults = struct(...
    'zone',           zone, ...
    'geoid',          referenceEllipsoid('international','m'), ...
    'maplatlimit',    fromDegrees(mstruct.angleunits,maplatlimit), ...
    'flatlimit',      fromDegrees(mstruct.angleunits,flatlimit), ...
    'origin',         fromDegrees(mstruct.angleunits,origin), ...
    'mlinelimit',     fromDegrees(mstruct.angleunits,mlinelimit), ...
    'mlabelparallel', fromDegrees(mstruct.angleunits,mlabelparallel), ...
    'maplonlimit',    fromDegrees(mstruct.angleunits,[-180 180]), ...
    'flonlimit',      fromDegrees(mstruct.angleunits,[-180 180]), ...
    'mlineexception', fromDegrees(mstruct.angleunits,-180:90:180), ...
    'mlinelocation',  fromDegrees(mstruct.angleunits,15), ...
    'plinelocation',  fromDegrees(mstruct.angleunits,1), ...
    'mlabellocation', fromDegrees(mstruct.angleunits,15), ...
    'plabellocation', fromDegrees(mstruct.angleunits,1));

mstruct = applyDefaults(mstruct, defaults);

%-----------------------------------------------------------------------

function mstruct = applyDefaults(mstruct, defaults)
% Fill in empty fields of 1-by-1 structure array MSTRUCT with values
% from the corresponding fields of 1-by-1 structure array DEFAULTS.

f = fields(defaults);
for k = 1:numel(f)
    fieldk = f{k};
    if isempty(mstruct.(fieldk))
        mstruct.(fieldk) = defaults.(fieldk);
    end
end

%-----------------------------------------------------------------------

function [flatlimit, flonlimit] = adjustFrameLimits(mstruct)
% Ensure that the frame limits are two-element vectors and that they are
% consistent with the "trim limits."

%  Frame latitude limits
if isempty(mstruct.flatlimit)
    flatlimit = mstruct.trimlat;
elseif isscalar(mstruct.flatlimit)
    % Assume an azimuthal projection.
    flatlimit = [-Inf, min(mstruct.flatlimit, mstruct.trimlat(2))];
else
    % Clamp flatlimit within the "trimlat" range.
    flatlimit = [...
        max(mstruct.flatlimit(1), mstruct.trimlat(1)), ...
        min(mstruct.flatlimit(2), mstruct.trimlat(2))];
end

%  Frame longitude limits
D360 = fromDegrees(mstruct.angleunits,360);
if isempty(mstruct.flonlimit)
    flonlimit = mstruct.trimlon;
else
    % Avoid wrapping and keep the limits within [-360 360].
    flonlimit = fromDegrees(mstruct.angleunits, ...
        unwrapLonlim(toDegrees(mstruct.angleunits,mstruct.flonlimit)));
    
    if (abs(mstruct.trimlon(2) - mstruct.trimlon(1)) ~= D360)
        % The "trim" limits do not cover a full 360 degrees, so
        % clamp flonlimit within the "trimlon" range.
        flonlimit = [...
            max(flonlimit(1), mstruct.trimlon(1)), ...
            min(flonlimit(2), mstruct.trimlon(2))];
    end
end

%-----------------------------------------------------------------------

function origin = adjustOrigin(mstruct)
% Fill in missing elements to ensure a 1-by-3 origin vector, and adjust
% mstruct.origin(3) if the fixedorient field is set.

origin = mstruct.origin;
if isempty(origin)
    origin = [0 0 0];
elseif isscalar(origin)
    % Scalar value is interpreted as the longitude origin
    origin = [0 origin 0];
elseif numel(origin) == 2
    % Origin latitude and longitude are given; append default orientation
    origin(3) = 0;    
end

%  Override orientation setting if fixedorient is non-empty
if ~isempty(mstruct.fixedorient)
    if isscalar(mstruct.fixedorient)
        origin(3) = mstruct.fixedorient(1);
    else
        error('map:resetmstruct:mapprojError', ...
            '% must be a scalar.','FixedOrient')
    end
end

%-----------------------------------------------------------------------

function parallels = defaultStandardParallels(nparallels, latlimit)
% Compute default values for the latitudes of the standard parallels.
% (If the projection is not formulated to use standard parallels, then
% these values will be ignored.)

if nparallels == 1
    parallels = max(latlimit) - diff(latlimit)/3;
elseif nparallels == 2
    parallels = latlimit + diff(latlimit) * [1/6 -1/6];
else
    parallels = [];
end

%-----------------------------------------------------------------------

function lat = meridianLabelParallel(mstruct)

% Depends on mstruct.mlabelparallel and mstruct.maplatlimit

if isempty(mstruct.mlabelparallel)
    lat = max(mstruct.maplatlimit);
elseif ~ischar(mstruct.mlabelparallel)
    upper = max(mstruct.maplatlimit);
    lower = min(mstruct.maplatlimit);
    lat = max(min(mstruct.mlabelparallel,upper),lower);
elseif ischar(mstruct.mlabelparallel)
    switch mstruct.mlabelparallel
        case 'north',    lat = max(mstruct.maplatlimit);
        case 'south',    lat = min(mstruct.maplatlimit);
        case 'equator',  lat = 0;
    end
end

%-----------------------------------------------------------------------

function lon = parallelLabelMeridian(mstruct)

% Depends on mstruct.plabelmeridian and mstruct.maplonlimit

if isempty(mstruct.plabelmeridian)
    lon = min(mstruct.maplonlimit);
elseif ~ischar(mstruct.plabelmeridian)
    upper = max(mstruct.maplonlimit);
    lower = min(mstruct.maplonlimit);
    lon = max(min(mstruct.plabelmeridian,upper),lower);
elseif ischar(mstruct.plabelmeridian)
    switch mstruct.plabelmeridian
        case 'east',    lon = max(mstruct.maplonlimit);
        case 'west',    lon = min(mstruct.maplonlimit);
        case 'prime',   lon = 0;
    end
end

%-----------------------------------------------------------------------

function lonlim = unwrapLonlim(lonlim)
%unwrapLonlim Unwrap longitude-limit vector
%
%   LONLIM = unwrapLonlim(LONLIM) adds or subtracts multiples of 360
%   degrees from each element in a two-element longitude-limit vector of
%   the form LONLIM = [western_limit eastern_limit], ensuring that: 
% 
%                    lonlim(1) < lonlim(2)
%                    diff(lonlim) <= 360
%
%   In addition the limits either span or touch zero whenever possible.
%   And if the interval does not span or touch zero, then it is still
%   placed as close to zero as possible. Finally, in a symmetrical
%   situation where the interval excludes zero (e.g., [170 -170]), the
%   positive option is selected (e.g., [170 190] rather than
%   [-190 -170]).
%
%   Both inputs and outputs are both in units of degrees.
%
%   Note: In the special case of identical values in lonlim(1) and
%   lonlim(2), unwrapLonlim assumes that the intention is to span a full
%   360 degrees on longitude.

% Ensure that 0 < width <= 360.  (If lonlim(1) == lonlim(2), width = 360.)
width = ceilmod(diff(lonlim),360);

% Force lonlim(2) to exceed zero.
lonlim = ceilmod(lonlim(2),360) + [-width 0];

% But if subtracting 360 would make the limits include or move closer to
% zero, then do so.  Thus, for example, [270 360] ==> [-90  0].
if (lonlim(1) > 0) && (360 - lonlim(2) < lonlim(1))
    lonlim = lonlim - 360;
end

%-----------------------------------------------------------------------

function x = ceilmod(x,y)
% Like mod, but return y instead of zero if x is an exact multiple of y.

x = mod(x,y);
x(x == 0) = y;
