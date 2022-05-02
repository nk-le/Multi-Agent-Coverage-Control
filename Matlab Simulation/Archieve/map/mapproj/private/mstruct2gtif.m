function gtif = mstruct2gtif(mstruct)
%MSTRUCT2GTIF Convert a mstruct to GTIF.
%
%   GTIF = MSTRUCT2GTIF(MSTRUCT) Converts the mstruct, MSTRUCT, to a
%   limited GeoTIFF structure, GTIF. If the geoid field of the mstruct
%   contains an ellipsoid vector, then the first element of the ellipsoid
%   vector (the semimajor axis) must in meters.
%
%   Example
%   -------
%      mstruct = defaultm('miller');
%      mstruct.geoid = referenceEllipsoid('clarke66');
%      gtif = mstruct2gtif(mstruct);
%
%   See also GEOTIFF2MSTRUCT, PROJ2GTIF.

%   Copyright 2003-2020 The MathWorks, Inc.

% Verify the mstruct
if ~ismstruct(mstruct)
    error(message('map:validate:missingStructureFields','MSTRUCT'))
end

% Get the projection code conversion structure
code = projcode(mstruct.mapprojection);
if ( isequal(code.CTProjection, 'CT_LambertConfConic_2SP') && ...
     mstruct.nparallels < 2)
  code = projcode('CT_LambertConfConic_1SP');
end
if (isequal(code.mapprojection,'Unknown'))
    error(message('map:projections:notSupportedByGeoTIFF', ...
        mstruct.mapprojection))
end

% Assign default GeoTIFFCode values
GeoTIFFCodes = initGeoTIFFCodes;

% Get the semimajor and semiminor axes and ellipsoid code, if known
ellipsoid = mstruct.geoid;
if isprop(ellipsoid,'SemimajorAxis')
    gtif.SemiMajor = ellipsoid.SemimajorAxis;
    gtif.SemiMinor = ellipsoid.SemiminorAxis;
    if isprop(ellipsoid,'Code')
        ellipsoid.LengthUnit = 'meter';
        ellipsoidCode = ellipsoid.Code;
    else
        ellipsoidCode = [];
    end
else
    [a, ecc] = ellipsoidprops(mstruct);
    gtif.SemiMajor = a;
    gtif.SemiMinor = minaxis(a,ecc);
    ellipsoidCode = findEllipsoid(a, ecc);
end
if ~isempty(ellipsoidCode)
    GeoTIFFCodes.Ellipsoid = ellipsoidCode;
end

% Get the projection parameters
[origin, parallels, scale, easting, northing] = getProjParm( code.index, ...
         mstruct.origin, mstruct.mapparallels, mstruct.scalefactor, ...
         mstruct.falseeasting, mstruct.falsenorthing);
gtif.ProjParm = zeros(7,1);
gtif.ProjParm(1:2) = origin;
gtif.ProjParm(3:4) = parallels;
gtif.ProjParm(5) = scale;
gtif.ProjParm(6) = easting;
gtif.ProjParm(7) = northing;

% Set the GTIF CT projection
gtif.projname             = code.projname;
gtif.CTProjection         = code.CTProjection;
GeoTIFFCodes.CTProjection = code.CTcode;

% Set the GeoTIFFCodes
gtif.GeoTIFFCodes = GeoTIFFCodes;
gtif.GeoTIFFCodes = int16GeoTiffCodes(gtif.GeoTIFFCodes);

%--------------------------------------------------------------------------
function GeoTIFFCodes = initGeoTIFFCodes
% Default GeoTIFFCode values
GeoTIFFCodes.Model = 1;
GeoTIFFCodes.PCS = 32767;
GeoTIFFCodes.GCS = 32767;
GeoTIFFCodes.UOMAngle = 32767;
GeoTIFFCodes.Datum = 32767;
GeoTIFFCodes.PM = 32767;
GeoTIFFCodes.ProjCode = 32767;
GeoTIFFCodes.Projection= 32767;
GeoTIFFCodes.MapSys = 32767;

% Default units to meters for now
GeoTIFFCodes.UOMLength = 9001;

%--------------------------------------------------------------------------
function ellipsoidCode = findEllipsoid(a, ecc)
% Check against 3 known PROJ4 ellipsoids:
%    GRS 80, Clarke 1866, and Clarke 1880

codes = [7019 7008 7034];
tol = 1e-13;

% Check each known ellipsoid until a sufficiently close match is found.
k = 1;
n = numel(codes);
ellipsoidCode = [];
while k <= n && isempty(ellipsoidCode)
    s = referenceEllipsoid(codes(k));
    s.LengthUnit = 'meter';
    if (a == s.SemimajorAxis) && (abs(ecc - s.Eccentricity) < tol)
        ellipsoidCode = s.Code;
    end
    k = k + 1;
end
