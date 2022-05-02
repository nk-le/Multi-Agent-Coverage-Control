function showm(object)
%SHOWM Show specified graphic objects on map axes
%
%  SHOWM('str') shows the object on the current axes specified
%  by 'str', where 'str' is any value recognized by HANDLEM.
%  Showing an object is accomplished by setting its visible property to on.
%
%  SHOWM will display a Graphical User Interface prompting for the
%  objects to be shown from the current axes.
%
%  SHOWM(h) shows the objects specified by the input handles h.
%
%  See also CLMO, HIDE, HANDLEM, NAMEM, TAGM.

% Copyright 1996-2017 The MathWorks, Inc.

if nargin == 0
    object = 'taglist';
else
    object = convertStringsToChars(object);
end

% special treatment for scaleruler because of hidden handle elements
if ischar(object) &&  strcmp(object,'scaleruler')
    % showm('scaleruler') - show all rulers
    groups = findall(gca,'type','hggroup');
    tags = {groups.Tag};
    hndl = groups(startsWith(tags,"scaleruler"));
elseif ischar(object) &&  startsWith(object,'scaleruler')
    % showm('scaleruler2') - show the named ruler
    hndl = findall(gca,'tag',object);
else
    hndl = handlem(object);
end

%  Show the identified graphics objects
set(hndl,'Visible','on')
