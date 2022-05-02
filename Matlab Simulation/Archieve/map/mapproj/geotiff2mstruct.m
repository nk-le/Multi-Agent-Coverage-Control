function mstruct = geotiff2mstruct(gtif)
%GEOTIFF2MSTRUCT Convert GeoTIFF information to map projection structure
%
%   MSTRUCT = GEOTIFF2MSTRUCT(PROJ) converts the GeoTIFF projection
%   structure, PROJ, to the map projection structure, MSTRUCT. The length
%   units of the MSTRUCT projection are meters.
%
%   PROJ must reference a projected coordinate system, as indicated by a
%   value of 'ModelTypeProjected' in the ModelType field. If ModelType has
%   the value 'ModelTypeGeographic' then it doesn't make sense to convert
%   to a map projection structure and an error is issued.
%
%   Example 
%   -------
%   % Compare inverse transform of points using projinv.
%   % Obtain the projection structure of 'boston.tif'.
%   proj = geotiffinfo('boston.tif');
%
%   % Convert the corner map coordinates to latitude and longitude.
%   x = proj.CornerCoords.X;
%   y = proj.CornerCoords.Y;
%   [latProj, lonProj] = projinv(proj, x, y);
%
%   % Obtain the mstruct from the GeoTIFF projection.
%   mstruct = geotiff2mstruct(proj);
%
%   % Convert the units of x and y to meter to match projection units.
%   x = unitsratio('meter','sf') * x;
%   y = unitsratio('meter','sf') * y;
%
%   % Convert the corner map coordinates to latitude and longitude.
%   [latMstruct, lonMstruct] = projinv(mstruct, x, y);
%
%   % Verify the values are within a tolerance of each other.
%   abs(latProj - latMstruct) <= 1e-7
%   abs(lonProj - lonMstruct) <= 1e-7
%
%   See also GEOTIFFINFO, PROJFWD, PROJINV, PROJLIST.

% Copyright 1996-2020 The MathWorks, Inc.

% Verify the input structure
if ~isGeoTiff(gtif)
    error(message('map:validate:invalidGeoTIFF'))
end

% Assert that the GeoTIFF structure references a projected coordinate
% system.
map.internal.assert(strcmp(gtif.ModelType, 'ModelTypeProjected'), ...
    'map:validate:expectedModelTypeProjected', gtif.ModelType);

% Get the projection code structure
code = projcode(gtif.CTProjection);
if (strcmp(code.mapprojection,'Unknown'))
    error(message('map:validate:unknownPROJ', ...
        gtif.CTProjection, 'PROJFWD', 'PROJINV'))
end

% Create a default mstruct using the mapprojection name
mstruct = defaultm(code.mapprojection);

% Set params as a row vector (for use in mstruct).
projParams = gtif.ProjParm(:)';
projIds = string(gtif.ProjParmId)';

% Obtain origin for mstruct.
% The origin is defined at one of three geokey locations. These geokey
% locations are unique within the projection parameters, meaning that only
% one set is defined.
%    ProjNatOriginLatGeoKey, ProjNatOriginLongGeoKey
%    ProjCenterLatGeoKey, ProjCenterLongGeoKey
%    ProjFalseOriginLatGeoKey, ProjFalseOriginLongGeoKey
geokeylat = ["ProjNatOriginLatGeoKey", "ProjCenterLatGeoKey", "ProjFalseOriginLatGeoKey"];
geokeylon = strrep(geokeylat, "Lat", "Long");
origin = zeros(1,2);
for k = 1:length(geokeylat)
    index = ismember(projIds, [geokeylat(k), geokeylon(k)]);
    if any(index)
        origin = projParams(index);
        break
    end
end

% Obtain standard parallels for mstruct.
geokey1 = "ProjStdParallel1GeoKey";
geokey2 = "ProjStdParallel2GeoKey";
parallelsIndex = ismember(projIds, [geokey1, geokey2]);
stdparallels = projParams(parallelsIndex);

% Obtain scalefactor for mstruct
% The scalefactor is defined in one of two geokey locations. These geokey
% locations are unique within the projection parameters, meaning that only
% one is defined. In general, the scale is located in projParams(5).
%    ProjScaleAtCenterGeoKey
%    ProjScaleAtNatOriginGeoKey
geokey1 = "ProjScaleAtCenterGeoKey";
geokey2 = "ProjScaleAtNatOriginGeoKey";
scalefactorIndex = ismember(projIds, [geokey1, geokey2]);
scalefactor = projParams(scalefactorIndex);

% Make sure scalefactor is 1 if empty or 0 or in the case where both keys
% are listed (which could potentially occur in an non-conforming GeoTIFF
% file).
if ~isscalar(scalefactor) || scalefactor == 0
  scalefactor = 1;
end

% Obtain easting and northing for mstruct.
% The false easting and false northing are defined in these geokeys:
%    ProjFalseEastingGeoKey, ProjFalseNorthingGeoKey
geokeyeast  = "ProjFalseEastingGeoKey";
geokeynorth = "ProjFalseNorthingGeoKey";
index = ismember(projIds, [geokeyeast, geokeynorth]);
values = projParams(index);
if length(values) == 2
    easting = values(1);
    northing = values(2);
else
    easting = 0;
    northing = 0;
end

% Assign values to mstruct.
mstruct.origin = [origin 0];
mstruct.mapparallels = stdparallels;
mstruct.scalefactor = scalefactor;
mstruct.falseeasting  = easting; 
mstruct.falsenorthing = northing; 

% Set the 'geoid' field 
mstruct.geoid = [gtif.SemiMajor  axes2ecc(gtif.SemiMajor, gtif.SemiMinor)];

% Set the rest of the mstruct properties
if strcmp(mstruct.mapprojection,'ups')
    % UPS sets the origin itself and will warn
    % because we've set it already.
    warnstate = warning('off','map:origin:ignoringOriginForUPS');
    c = onCleanup(@() warning(warnstate));
    if mstruct.origin(1) >= 0
        mstruct.zone = 'north';
    else
        mstruct.zone = 'south';
    end
    mstruct = defaultm(mstruct);
else
    mstruct = defaultm(mstruct);
end
