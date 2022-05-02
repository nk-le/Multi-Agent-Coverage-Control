function outputs = applyProjection(mproj, varargin)
% Apply a non-azimuthal map projection (in the Cylindrical, Polyconic,
% Conic, Polyconic, or Modified Azimuthal class).

% Copyright 2005-2015 The MathWorks, Inc.

n = numel(varargin);
if n == 1
    outputs{1} = mproj.default(varargin{1});
elseif n == 5 || n == 6 || n == 7
    mproj.applyForward = @applyForward;
    mproj.applyInverse = @applyInverse;
    outputs = doApplyProj(mproj, varargin{:});
else
    error(message('map:validate:invalidArgCount'))
end

%--------------------------------------------------------------------------

function [x, y, savepts] = applyForward(mproj, mstruct, lat, lon, objectType)

% Convert origin and frame limits to radians & auxiliary sphere
origin = convertOrigin(mproj, mstruct);
[flatlimit, flonlimit] = convertLimits(mproj, mstruct);

% Convert input coordinates to radians
[lat, lon] = toRadians(mstruct.angleunits, real(lat), real(lon));

% Convert to auxiliary latitude
lat  = convertlat(mstruct.geoid, lat, ...
    'geodetic', mproj.auxiliaryLatitudeType, 'nocheck');

% Rotate and trim lat-lon data
switch objectType
    case {'notrim', 'geopoint', 'geomultipoint', 'geoline', 'geopolygon'}
        
        % If there's a triaxial rotation, apply it now, but wait until
        % after trimming if it's purely a longitude shift.  This can
        % reduce the effect of numerical roundoff on vertices that fall
        % right at the limits.
        longitudeShiftOnly = (origin(1) == 0) && (origin(3) == 0);
        if longitudeShiftOnly
            originlon = wrapToPi(origin(2));
            flonlimit = flonlimit + originlon;
        else
            rotatePure = getRotatePure(mproj.classCode);
            [lat, lon] = rotatePure(lat, lon, origin, 'forward');
        end
        
        % Trim (skip savepts)
        switch(objectType)
            case 'notrim'
                % No trimming required
                
            case {'geopoint', 'geomultipoint'}
                [lat, lon] = trimPointToQuadrangle( ...
                    lat, lon, flatlimit, flonlimit);
                
            case 'geoline'
                [lat, lon] = trimPolylineToQuadrangle(...
                    lat, lon, flatlimit, flonlimit);
                
            case 'geopolygon'
                inc = 2.0*pi/180;
                [lat, lon] = trimPolygonToQuadrangle( ...
                    lat, lon, flatlimit, flonlimit, inc);               
        end
        savepts.trimmed = [];
        savepts.clipped = [];
        
        % Apply the delayed longitude shift
        if longitudeShiftOnly
            lon = lon - originlon;
        end
        
    case 'geosurface'
        % Apply rotation
        rotatePure = getRotatePure(mproj.classCode);
        [lat, lon] = rotatePure(lat, lon, origin, 'forward');
            
        % Trim mesh.
        [lat, lon] = trimMeshToQuadrangle(lat, lon, flatlimit, flonlimit);
        
        % Insert NaNs at the appropriate locations in the surface graticule
        % mesh so that a displayed map is clipped at the appropriate edges.
        [lat, lon] = clipgrat(lat,lon);
        
        savepts.trimmed = [];
        savepts.clipped = [];
        
    otherwise               
        % Apply rotation
        if strcmp(objectType,'linem')
            rotateFcn = getRotatePure(mproj.classCode);
        else
            rotateFcn = getRotateFcn(mproj.classCode);
        end
        [lat, lon] = rotateFcn(lat, lon, origin, 'forward');
        
        % Clip at date line, trim data, save structure of altered points
        [lat, lon, clipped] = clipdata(lat, lon, objectType);
        [lat, lon, trimmed] = trimdata(lat, flatlimit, lon, flonlimit, objectType);
        savepts.trimmed = trimmed;
        savepts.clipped = clipped;       
end

% Project
[x, y] = mproj.forward(mstruct, lat, lon);
[x, y] = applyScaleAndOriginShift(mstruct, x, y);
applyProjectionAspect = getApplyProjectionAspect(mproj.classCode);
[x, y] = applyProjectionAspect(mstruct, x, y);

%--------------------------------------------------------------------------

function [lat, lon, savepts] = applyInverse(...
    mproj, mstruct, x, y, objectType, savepts)

% Undo projection
interpretProjectionAspect = getInterpretProjectionAspect(mproj.classCode);
[x, y] = interpretProjectionAspect(mstruct, x, y);
[x, y] = undoScaleAndOriginShift(mstruct, x, y);
[lat, lon] = mproj.inverse(mstruct, x, y);

% Undo trimming and clipping
[lat, lon] = undotrim(lat, lon, savepts.trimmed, objectType);
[lat, lon] = undoclip(lat, lon, savepts.clipped, objectType);

% Undo rotation and restore geodetic latitude
rotateFcn = getRotateFcn(mproj.classCode);
origin = convertOrigin(mproj, mstruct);
[lat, lon] = rotateFcn(lat, lon, origin, 'inverse');
lat = convertlat(mstruct.geoid, lat, ...
    mproj.auxiliaryLatitudeType, 'geodetic', 'nocheck');

% Restore angle units
[lat, lon] = fromRadians(mstruct.angleunits, lat, lon);

%--------------------------------------------------------------------------

function [lat, lon] = trimPointToQuadrangle(lat, lon, flatlimit, flonlimit)

% Discard points falling outside the quadrangle.
q = ~ingeoquad(rad2deg(lat), rad2deg(lon), ...
    rad2deg(flatlimit), rad2deg(flonlimit));
lat(q) = [];
lon(q) = [];

% Ensure that lon falls within the interval specified by flonlimit.
lon = flonlimit(1) + wrapTo2Pi(lon - flonlimit(1));

%--------------------------------------------------------------------------

function origin = convertOrigin(mproj, mstruct)
% Convert origin to radians & auxiliary sphere

origin = toRadians(mstruct.angleunits, mstruct.origin);

origin(1) = convertlat(mstruct.geoid, origin(1), ...
    'geodetic', mproj.auxiliaryLatitudeType, 'nocheck');

%--------------------------------------------------------------------------

function [flatlimit, flonlimit] = convertLimits(mproj, mstruct)
% Convert frame limits to radians & auxiliary sphere

% Extract the projection parameters and convert to radians
[flatlimit, flonlimit] = toRadians( ...
    mstruct.angleunits, mstruct.flatlimit, mstruct.flonlimit);

% Adjust the latitudes to the auxiliary sphere
flatlimit = convertlat(mstruct.geoid, flatlimit, ...
    'geodetic', mproj.auxiliaryLatitudeType, 'nocheck');

%--------------------------------------------------------------------------

function f = getApplyProjectionAspect(classCode)

switch classCode
    case 'Tran'  % Transverse Mercator/UTM or (standard) Cassini
        f = @applyProjAspectTran;
    case {'Cstd','Pstd'}  % Standard form of conic/polyconic projections
        f = @applyProjAspectCstd;
    otherwise    % Other non-azimuthal projections
        f = @applyProjAspect;
end

%--------------------------------------------------------------------------

function [out1, out2] = applyProjAspect(mstruct, x, y)

% Assign outputs based on projection aspect.
switch  mstruct.aspect
    case 'normal'
        out1 = real(x);
        out2 = real(y);
    case 'transverse'
        out1 = real(y);
        out2 = real(-x);
    otherwise
        error(message('map:projections:invalidProjectionAspect', ...
            mstruct.aspect, 'normal', 'transverse'))
end

%--------------------------------------------------------------------------

function [out1, out2] = applyProjAspectTran(~, x, y)

% Ignore projection aspect value for Transverse Mercator/UTM.
out1 = real(x);
out2 = real(y);

%--------------------------------------------------------------------------

function [out1, out2] = applyProjAspectCstd(mstruct, x, y)

% Ignore projection aspect value for (standard) conic projection.
out1 = real(x);
out2 = real(y);
if ~strcmp(mstruct.aspect,'normal')
    warning(message('map:projections:ignoringNonNormalAspect', 'Conic'))
end

%--------------------------------------------------------------------------

function f = getInterpretProjectionAspect(classCode)

switch classCode
    case 'Tran'  % Transverse Mercator/UTM or (standard) Cassini
        f = @interpProjAspectTran;
    case {'Cstd','Pstd'}  % Standard form of conic/polyconic projections
        f = @interpProjAspectCstd;
    otherwise    % Other non-azimuthal projections
        f = @interpProjAspect;
end

%--------------------------------------------------------------------------
     
function [x, y] = interpProjAspect(mstruct, in1, in2)

% Interpret inputs based on projection aspect.
switch mstruct.aspect
    case 'normal'
        x = in1;
        y = in2;
    case 'transverse'
        x = -in2;
        y =  in1;
    otherwise
        error(message('map:projections:invalidProjectionAspect', ...
            mstruct.aspect, 'normal', 'transverse'))
end

%--------------------------------------------------------------------------
     
function [x, y] = interpProjAspectTran(mstruct, in1, in2)

% Ignore projection aspect value for Transverse Mercator/UTM.
x = in1;
y = in2;
if ~strcmp(mstruct.aspect,'normal')
    warning(message('map:projections:ignoringNonNormalAspect', ...
        'Transverse Mercator'))
end

%--------------------------------------------------------------------------
     
function [x, y] = interpProjAspectCstd(mstruct, in1, in2)

% Ignore projection aspect value for (standard) conic projection.
x = in1;
y = in2;
if ~strcmp(mstruct.aspect,'normal')
    warning(message('map:projections:ignoringNonNormalAspect', 'Conic'))
end

%--------------------------------------------------------------------------

function f = getRotateFcn(classCode)

if any(strcmp(classCode,{'Tran','Cstd','Pstd'}))
    f = @rotatePolarOnly;
else
    f = @rotatemRadians;
end
%--------------------------------------------------------------------------

function f = getRotatePure(classCode)

if any(strcmp(classCode,{'Tran','Cstd','Pstd'}))
    f = @rotatePolarOnly;
else
    f = @rotatePureTriax;
end

%--------------------------------------------------------------------------

function [lat, lon] = rotatePolarOnly(lat, lon, origin, direction)

% Rotate only about the polar axis.

if strcmp(direction,'forward')
    lon = wrapToPi(lon - origin(2));
elseif strcmp(direction,'inverse')
    lon = wrapToPi(lon + origin(2));
else
    error(message('map:validate:invalidDirectionString', ...
        direction, 'forward', 'inverse'))
end

function [yout,xout] = clipgrat(ymat,xmat)
%CLIPGRAT:  NaN clip graticules for surface meshes
%
%  CLIPGRAT will insert NaNs at the appropriate locations in a surface
%  graticule mesh so that a displayed map is clipped at the appropriate
%  edges.  
%
%  For graticules, clip points are NaNs which overwrite a point at the clip
%  location.  This approach does not alter the dimensions of the underlying
%  graticule, which in turn, does not stretch or compress the displayed
%  map.  However, data will not be displayed at the clipped edges of the
%  map.
%
%  The input data must be in radians and be properly transformed for the
%  particular aspect and origin so that it fits in the specified clipping
%  range.
%
%  The output data is in radians, with clips placed at the proper location.
%  The output variable splitpts returns the index of the clipped elements
%  (column 1, vector indexing for the matrices) and the original latitude
%  and longitude data (columns 2 and 3 respectively) from the unclipped
%  inputs.  These original data are necessary to restore the graticule if
%  the map parameters or projection are ever changed.

%  Unlike lines and grids where a NaN is inserted into the array, a
%  graticule has the clip point simply replaced by a NaN. Since a surface
%  map is drawn with the map data in the Cdata property, altering the
%  underlying graticule (Xdata, Ydata, Zdata), will stretch and modify the
%  displayed map.  By the time the clips are performed, the graticule grid
%  must be defined.  So, with graticules, a NaN is simply inserted into the
%  location of a clip crossing, and thus, not altering the already existing
%  graticule grids.

% Initialize outputs.  Don't initialize xout and yout because it may mess
% up the first assignment of clipped data later.  Scalars don't need to be
% clipped.
if isscalar(xmat) 
   xout = xmat;     
   yout = ymat; 
   return                          
end

% Work with matrix or column vectors.
if size(xmat,1) == 1            
   xmat = xmat';   
   ymat = ymat';
end

% Initialize output matrices.  This must be done after the above operations
% on xmat.
xout  = xmat;     
yout  = ymat;

%*********************************************************
%  First search the graticule for clips along the rows.
%  Then, search the graticule for clips along the columns.
%*********************************************************

%***********
%  Row clips
%***********

xtest = diff(sign(xout));
[i,j] = find(xtest ~= 0 & ~isnan(xtest) );

splitvec = i + (j-1)*size(xmat,1);
indx = abs(xmat(splitvec) - xmat(splitvec+1)) > pi;
splitvec = splitvec(indx);

% Replace the point at the clip with a NaNs.
xout(splitvec) = NaN;     
yout(splitvec) = NaN;

%**************
%  Column clips
%**************

% Find the clip points of the transposed matrix.
xtrans = xout';
xtest = diff(sign(xtrans));

[i,j] = find(xtest ~= 0 & ~isnan(xtest) );
splitvec = i + (j-1)*size(xtrans,1);
indx = abs(xtrans(splitvec) - xtrans(splitvec+1)) > pi;

% Determine the index of the clip for the untransposed matrix.
splitvec = j(indx) + (i(indx)-1)*size(xmat,1);

% Replace the point at the clip with a NaNs.  
xout(splitvec) = NaN;     
yout(splitvec) = NaN;
