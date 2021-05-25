function [out1,out2] = eqacalc(in1,in2,origin,direction,units,ellipsoid)
%EQACALC  Transformation of data to and from an Equal Area space
%
%   [x,y] = eqacalc(lat,lon,origin,'forward',units,ellipsoid) and
%   [lat,lon] = eqacalc(x,y,origin,'inverse',units,ellipsoid) project and
%   unproject points between latitude-longitude and an equidistant
%   cylindrical system, in support of GRN2EQA and EQA2GRN.

% Copyright 1996-2011 The MathWorks, Inc.

% Construct a equidistant cylindrical map projection structure.
mstruct = defaultm('eqacylin');
mstruct.geoid        = ellipsoid;
mstruct.angleunits   = units;
mstruct.mapparallels = [0 0];
mstruct.origin       = origin;
mstruct.aspect       = 'normal';
[mstruct.flatlimit, mstruct.flonlimit] ...
    = fromDegrees(units, [-90 90], [-180 180]);
mstruct = defaultm(mstruct);

% Set some interface variables for eqacylin.
object = 'text';           %  Suppress all clips and trims
savepts.trimmed = [];      %  Savepts needed in inverse direction
savepts.clipped = [];

% Apply the projection.
[out1,out2] = eqacylin(mstruct,in1,in2,object,direction,savepts);
