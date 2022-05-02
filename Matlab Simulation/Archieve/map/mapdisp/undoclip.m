function [lat,long] = undoclip(lat,long,splitpts,object)
%UNDOCLIP Remove object clips introduced by CLIPDATA
%
%  [lat,long] = undoclip(lat,long,clippts,'object') will remove
%  the object clips introduced by CLIPDATA.  This function is necessary
%  to properly invert projected data from the map coordinates to the
%  original lat, long data points.  The input variable, clippts, must
%  be constructed by the function CLIPDATA.
%
%  Allowable objects are:  'surface' for undoing clipped graticules;
%  'light' for undoing clipped lights; 'line' for undoing clipped lines;
%  'patch' for undoing clipped patches; and 'text' for undoing clipped
%  text object location points.
%
%  See also CLIPDATA, TRIMDATA, UNDOTRIM.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Return if nothing to undo
if isempty(splitpts)
    return
end

object = validatestring(object, ...
    {'surface','light','line','patch','text'},'UNDOCLIP','OBJECT', 4);

switch object
    case 'surface'
	     lat(splitpts(:,1)) = splitpts(:,2);
	     long(splitpts(:,1)) = splitpts(:,3);

    case 'line'
	     lat(splitpts(:,1)) = [];
	     long(splitpts(:,1)) = [];

    case 'patch'           %  Simply replace the original patch data
         lat = splitpts(:,1);
         long = splitpts(:,2);
end
