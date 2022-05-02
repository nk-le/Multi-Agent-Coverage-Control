function hidem(object)
%HIDEM Hide specified graphic objects on map axes
%
%  HIDEM('str') hides the object on the current axes specified
%  by 'str', where 'str' is any object recognized by HANDLEM.
%  Hiding an object is accomplished by setting its visible property to off.
%
%  HIDEM will display a Graphical User Interface prompting for the
%  objects to be hid from the current axes.
%
%  HIDEM(h) hides the objects specified by the input handles h.
%
%  See also CLMO, SHOWM, HANDLEM, NAMEM, TAGM.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin == 0
    object = 'taglist';
else
    object = convertStringsToChars(object);
end

%  Get the appropriate object handles

% special treatment for scaleruler because of hidden handle elements
if ischar(object) &&  strcmp(object,'scaleruler')
    % hidem('scaleruler') - hide all rulers
    groups = findall(gca,'type','hggroup');
    tags = {groups.Tag};
    hndl = groups(startsWith(tags,"scaleruler"));
elseif ischar(object) &&  startsWith(object,'scaleruler')
    % hidem('scaleruler2') - hide the named ruler
    hndl = findall(gca,'tag',object);
else
    hndl = handlem(object);
end

%  Hide the identified graphics objects
set(hndl,'Visible','off')
