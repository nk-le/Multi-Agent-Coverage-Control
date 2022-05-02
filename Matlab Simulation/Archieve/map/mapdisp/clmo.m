function clmo(object)
%CLMO Clear specified graphic objects from map axes
%
%  CLMO('str') deletes the object on the current axes specified
%  by the 'str', where 'str' is any value recognized by HANDLEM.
%
%  CLMO displays a Graphical User Interface prompting for the
%  objects to be deleted from the current axes.
%
%  CLMO(h) deletes the objects specified by the input handles h.  This
%  is equivalent to DELETE(h)
%
%  See also HIDE, SHOWM, HANDLEM, NAMEM, TAGM.

% Copyright 1996-2017 The MathWorks, Inc.

if nargin == 0
    object = 'taglist';
end

%  Handle scaleruler separately, because hidden elements aren't 
%  returned by HANDLEM

if all(ishghandle(object))
	delete(object)
	return
end

switch object
    case{'all','map'}
        scaleruler off
    case 'scaleruler'
        scaleruler off
        return
    otherwise
        % special treatment for scalerulers, because of hidden elements
        if strmatch('scaleruler',object) % strip trailing numbers
            hndls = findall(gca,'tag',object);
            delete(hndls);
            return
        end
end

%  Get the appropriate object handles
hndl = handlem(object);

%  Delete the identified graphics objects
delete(hndl)
