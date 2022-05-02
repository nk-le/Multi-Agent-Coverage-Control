function [out1,out2,out3,savepts] ...
    = globe(mstruct,in1,in2,in3,objectType,direction,savepts)
%GLOBE  Earth as sphere in 3-D graphics
%
%  In the three-dimensional sense, this "projection" is true in scale,
%  equal-area, conformal, minimum error, and equidistant everywhere.
%  When displayed, however, this "projection" looks like an orthographic
%  azimuthal projection, provided that the MATLAB axes projection
%  property is set to orthographic.

% Copyright 1996-2019 The MathWorks, Inc.

if nargin == 1
    out1 = globeDefault(mstruct);
    return
end

switch direction
    
    case 'forward'
        
        alt = in3;
        if isempty(alt)
            alt = zeros(size(in1));
        end
        
        geotypes = {'geopoint','geomultipoint','geoline','geopolygon'};
        
        if any(strncmp(objectType, geotypes, numel(objectType)))
            [lat, lon] = toRadians(mstruct.angleunits, in1, in2);
        else
            [lat, lon] = toRadians(mstruct.angleunits, real(in1), real(in2));                       
            epsilon = epsm('radians');
            lon = backOffAtPi(lon, epsilon);
            lat = backOffAtPoles(lat, epsilon);           
        end
        [out1, out2, out3] = geodetic2ecef(lat, lon, alt, mstruct.geoid);

    case 'inverse'

        [lat, lon, out3] = ecef2geodetic(in1, in2, in3, mstruct.geoid);
        [out1, out2] = fromRadians(mstruct.angleunits, lat, lon);
        if strcmp(objectType,'patch')
            %  Patches can only have a scalar altitude.
            out3 = out3(1);
        end

    otherwise
        
        error(message('map:validate:invalidDirectionString', ...
            direction, 'forward', 'inverse'))
end

%  Some operations on NaNs produce NaN + NaNi.  However operations
%  outside the map may product complex results and we don't want
%  to destroy this indicator.
indx = find(isnan(out1) | isnan(out2));
out1(indx) = NaN;   
out2(indx) = NaN;
savepts = struct('trimmed',[],'clipped',[]);

%--------------------------------------------------------------------------

function mstruct = globeDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.galtitude = 0;
