function [out1,out2] = merccalc(in1,in2,direction,units)
%MERCCALC  Transformation of data to and from a Mercator space
%
%   [x,y] = merccalc(lat,lon,'forward',angleunits) and
%   [lat,lon] = merccalc(x,y,'inverse',angleunits) project and
%   unproject points between latitude-longitude and a Mercator
%   cylindrical system, in support of NAVFIX and RHXRH.

% Copyright 1996-2011 The MathWorks, Inc.

% Construct the necessary map projection structure.
mstruct = defaultm('mercator');
mstruct.angleunits   = units;
mstruct.mapparallels = [0 0];        %  Hard code some options used
mstruct.origin       = [0 0 0];      %  in mercator.m
mstruct.aspect       = 'normal';
[mstruct.flatlimit, mstruct.flonlimit, mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(units, [-90 90], [-180 180], [-89.9 89.9], [-180 180]);
mstruct = defaultm(mstruct);

% Set some interface variables for mercator.

object = 'text';           %  Suppress all clips and trims
savepts.trimmed = [];      %  Savepts needed in inverse direction
savepts.clipped = [];

% Apply the projection.
[out1,out2] = mercator(mstruct,in1,in2,object,direction,savepts);
