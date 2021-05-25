function varargout = robinson(varargin)
%ROBINSON  Robinson Pseudocylindrical Projection
%
%  For this projection, scale is true along the 38 deg parallels, and is
%  constant along any parallel, and between any pair of parallels
%  equidistant from the Equator.  It is not free of distortion at any
%  point, but distortion is very low within about 45 degrees of the center
%  and along the Equator.  This projection is not equal area, conformal or
%  equidistant;  however, it is considered to "look right" for world maps,
%  and hence is widely used by Rand McNally, the National Geographic
%  Society and others.  This feature is achieved through the use of tabular
%  coordinates rather than mathematical formulae for the graticules.
%
%  This projection was presented by Arthur H. Robinson in 1963, and is also
%  called the Orthophanic projection, which means "right appearing."
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @robinsonDefault;
mproj.forward = @robinsonFwd;
mproj.inverse = @robinsonInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = robinsonDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 38);
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = robinsonFwd(mstruct, lat, lon)

[a, r] = deriveParameters(mstruct);

%  Pick up NaN place holders.
x = lon;
y = lat;

%  Projection transformation

for i = 1:size(r,1)-1
    xslope = (r(i,3) - r(i+1,3)) / (r(i,2) - r(i+1,2));
    yslope = (r(i,4) - r(i+1,4)) / (r(i,2) - r(i+1,2));
    indx = find(abs(lat) >= r(i,2) & abs(lat) <= r(i+1,2));

    if ~isempty(indx)
        dellat = abs(lat(indx)) - r(i,2);

        X = r(i,3) + xslope * dellat;
        Y = (r(i,4) + yslope * dellat) .* sign(lat(indx));

        x(indx) = 0.8487 * a * X .* lon(indx);
        y(indx) = 1.3523 * a * Y;
    end
end

%--------------------------------------------------------------------------

function [lat, lon] = robinsonInv(mstruct, x, y)

[a, r] = deriveParameters(mstruct);

%  Pick up NaN place holders.
lon = x;
lat = y;

% Inverse projection
for i = 1:size(r,1)-1
    xslope   = (r(i,3) - r(i+1,3)) / (r(i,4) - r(i+1,4));
    latslope = (r(i,2) - r(i+1,2)) / (r(i,4) - r(i+1,4));

    Y = y / (1.3523*a);
    indx = find(abs(Y) >= r(i,4) & abs(Y) <= r(i+1,4));

    if ~isempty(indx)
        dely = abs(Y(indx)) - r(i,4);
        X = r(i,3) + xslope * dely;

        lat(indx) = (r(i,2) + latslope * dely) .* sign(y(indx));
        lon(indx) = x(indx) ./ (0.8487 * a * X);
    end
end

%--------------------------------------------------------------------------

function [a, r] = deriveParameters(mstruct)

a = ellipsoidprops(mstruct);

%  Robinson projection data
%  [Lat in deg,  Lat in rad,  X factor, Y factor]

r =[
         0         0    1.0000         0
    5.0000    0.0873    0.9986    0.0620
   10.0000    0.1745    0.9954    0.1240
   15.0000    0.2618    0.9900    0.1860
   20.0000    0.3491    0.9822    0.2480
   25.0000    0.4363    0.9730    0.3100
   30.0000    0.5236    0.9600    0.3720
   35.0000    0.6109    0.9427    0.4340
   40.0000    0.6981    0.9216    0.4958
   45.0000    0.7854    0.8962    0.5571
   50.0000    0.8727    0.8679    0.6176
   55.0000    0.9599    0.8350    0.6769
   60.0000    1.0472    0.7986    0.7346
   65.0000    1.1345    0.7597    0.7903
   70.0000    1.2217    0.7186    0.8435
   75.0000    1.3090    0.6732    0.8936
   80.0000    1.3963    0.6213    0.9394
   85.0000    1.4835    0.5722    0.9761
   90.0000    1.5708    0.5322    1.0000
];
