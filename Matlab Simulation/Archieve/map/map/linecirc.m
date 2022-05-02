function [x,y]=linecirc(slope,intercpt,centerx,centery,radius)
%LINECIRC  Intersections of circles and lines in Cartesian plane
%
%  [xout,yout] = LINECIRC(slope,intercpt,centerx,centery,radius) finds
%  the points of intersection given a circle defined by a center and
%  radius in x-y coordinates, and a line defined by slope and
%  y-intercept, or a slope of "inf" and an x-intercept.  Two points
%  are returned.  When the objects do not intersect, NaNs are returned.
%  When the line is tangent to the circle, two identical points are
%  returned. All inputs must be scalars
%
%  See also CIRCCIRC.

% Copyright 1996-2007 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

assert(isscalar(slope) && isscalar(intercpt) && ...
    isscalar(centerx) && isscalar(centery) && isscalar(radius),...
    ['map:' mfilename ':mapError'], 'Inputs must be scalars')

assert(isreal([slope intercpt centerx centery radius]), ...
    ['map:' mfilename ':mapError'], 'inputs must be real')

assert(radius > 0, ...
    ['map:' mfilename ':mapError'], 'radius must be positive')

% find the cases of infinite slope and handle them separately

if ~isinf(slope)
	% From the law of cosines

	a=1+slope.^2;
	b=2*(slope.*(intercpt-centery)-centerx);
	c=centery.^2+centerx.^2+intercpt.^2-2*centery.*intercpt-radius.^2;

	x=roots([a,b,c])';

	%  Make NaN's if they don't intersect.

	if ~isreal(x)
		x=[NaN NaN]; y=[NaN NaN];
	else
		y=[intercpt intercpt]+[slope slope].*x;
	end

% vertical slope case
elseif abs(centerx-intercpt)>radius  % They don't intercept
	x=[NaN;NaN]; y=[NaN;NaN];
else
	x=[intercpt intercpt];
	step=sqrt(radius^2-(intercpt-centerx)^2);
	y=centery+[step,-step];
end
