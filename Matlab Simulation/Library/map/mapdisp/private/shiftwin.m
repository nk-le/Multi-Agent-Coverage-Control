function shiftwin(fig)
%SHIFTWIN adjusts figure position if corners are offscreen
%
%  SHIFTWIN(fig) adjusts position of figure fig if any of the corners are
%  offscreen.  The window is translated, but not scaled.

%  Written by:  W. Stumpf
%  Copyright 1996-2015 The MathWorks, Inc.

savedUnits = fig.Units;
fig.Units = 'points';
position = fig.Position;

% shift window to get lower left corner on screen

llcornerx = position(1);
llcornery = position(2);

shiftx = min(llcornerx, 0);
shifty = min(llcornery, 0);

if shiftx < 0 || shifty < 0
	position = position + [-shiftx+50 -shifty+50 0 0];
	fig.Position = position;
end

% shift window to get upper right hand corner on screen

urcornerx = position(1) + position(3);
urcornery = position(2) + position(4);

screenSize = screenSizeInPoints();

shiftx = max(urcornerx - screenSize(3), 0);
shifty = max(urcornery - screenSize(4) + 50, 0);

if shiftx > 0 
    position = position + [-shiftx-50 0 0 0];
	fig.Position = position;
end

if shifty > 0
	position = position + [0 -shifty-50 0 0];
	fig.Position = position;
end

fig.Units = savedUnits;

%--------------------------------------------------------------------------

function sz = screenSizeInPoints()
root = groot;
savedUnits = root.Units;
root.Units = 'points';
sz = root.ScreenSize;
root.Units = savedUnits;
