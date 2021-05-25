function rotatetext(h,direction)
%ROTATETEXT Rotate text to projected graticule
% 
%   ROTATETEXT rotates displayed text objects to account for the
%   curvature of the graticule.  The objects are selected interactively
%   from a graphical user interface.
%   
%   ROTATETEXT(OBJECTS) rotates the selected objects.  OBJECTS may be a
%   name of an object recognized by HANDLEM, or a vector of handles to
%   displayed text objects.
%   
%   ROTATETEXT(OBJECTS,DIRECTION) accepts a DIRECTION, which must
%   be either 'forward' (the default value) or 'inverse'. Specifying
%   'inverse' causes ROTATETEXT to remove the rotation added by an
%   earlier call to ROTATETEXT.
%
%   Meridian and parallel labels can be rotated automatically by setting
%   the map axes LabelRotation property to on. ROTATETEXT does not
%   support the 'globe' projection.

% Copyright 1996-2020 The MathWorks, Inc.

% Get handles to displayed text objects
if nargin < 1
    h = handlem;
elseif ischar(h) || isstring(h)
    h = handlem(h);
elseif ~ishghandle(h)
	error('map:rotatetext:invalidObject', ...
        'Object must be a name string or handle.')
end

% Get direction / set forward to true or false
if nargin < 2
    forward = true;
else
    switch(direction)
        case 'forward'
            forward = true;
        case 'inverse'
            forward = false;
        otherwise
            error('map:rotatetext:invalidDirectionString', ...
                '%s must be ''%s'' or ''%s''.', 'DIRECTION','forward','inverse')
    end
end

% Validate map axes
mstruct = gcm;
if strcmp(mstruct.mapprojection,'globe')
    error('map:rotatetext:usingGlobe', ...
        '%s does not work with the globe projection.','ROTATETEXT')
end

% open limits to avoid bumping against the frame

t = defaultm(mstruct.mapprojection); % temporary mstruct, in degrees
mstruct.flatlimit = fromDegrees(mstruct.angleunits, t.trimlat);
mstruct.flonlimit = fromDegrees(mstruct.angleunits, t.trimlon);

% calculate vector rotation introduced by the projection

for i=1:length(h)
    if ishghandle(h(i),'text')
        pos = get(h(i),'position');
        [lat,lon] = map.crs.internal.minvtran(pos(1),pos(2));
        th = labelRotationAngle(mstruct, lat, lon);
        rot = get(h(i),'Rotation');
        if forward
            set(h(i),'rotation',th+rot);
        else
            set(h(i),'rotation',-th+rot);
        end
    end
end
