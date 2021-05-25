function [hout,htout] = mdistort(action,levels,gsize)
% MDISTORT Display contours of constant map distortion
% 
%   MDISTORT, with no input arguments, toggles the display of contours
%   of projection-induced distortion on the current map axes.  The
%   magnitude of the distortion is reported in percent.
%   
%   MDISTORT OFF removes the contours.
%   
%   MDISTORT('PARAMETER') or MDISTORT PARAMETER displays contours of 
%   distortion for the specified parameter.  Recognized parameters
%   are 'area', 'angles' for the maximum angular distortion of
%   right angles, 'scale' or 'maxscale' for the maximum scale,
%   'minscale' for the minimum scale, 'parscale' for scale along the
%   parallels, 'merscale' for scale along the meridians, and
%   'scaleratio' for the ratio of maximum and minimum scale.  If
%   omitted, the 'maxscale' parameter is displayed.  All parameters are
%   displayed as percent distortion, except angles, which are displayed
%   in degrees.
% 
%   MDISTORT('PARAMETER',LEVELS) specifies the levels for which the
%   contours are drawn.  LEVELS is a vector of values as used by
%   CONTOUR. If omitted, the default levels are used.
%   
%   MDISTORT('PARAMETER',LEVELS,GSIZE) controls the size of the
%   underlying graticule used to compute the contours.  GSIZE is a
%   two-element vector containing the number of rows and columns.  If
%   omitted, the default Mapping Toolbox graticule size of [50 100] is
%   assumed.
% 
%   h = MDISTORT(...) returns a handle to the contourgroup object
%   containing the contours and text.
%
%   Note:  The location of contours drawn by MDISTORT may be noisy in areas
%          where the distortion varies slowly within a map, which is often
%          the case with UTM. MDISTORT issues a warning if a UTM projection
%          is encountered.
%
%   See also TISSOT, DISTORTCALC, VFWDTRAN

% Copyright 1996-2020 The MathWorks, Inc.
% Written by: W. Stumpf

% Reference
% ---------
% Maling, Coordinate Systems and Map Projections, 2nd Edition, 

narginchk(0, 3)
ax = gca;

if nargin < 1
	h = findobj(ax,'Tag','DISTORTMlines');
    if isempty(h)
		action = 'maxscale';
	else
		action = 'off';
    end
else
    action = convertStringsToChars(action);
end

if nargin < 2
    levels = [];
end

if nargin < 3
	gsize = [50 100];
end

if strcmpi(action,'off')
    h = mdistortOff(ax);
else
    validateattributes(action,{'char','string'}, {'nonempty','scalartext'},'MDISTORT','PARAMETER',1)
    h = mdistortConstruct(ax, action, levels, gsize);
end

% Set output arguments
if nargout >= 1
    hout = h;
end

if nargout == 2
    htout = [];
    warning(message('map:mdistort:textHandlesRequested','MDISTORT','HT'))
end

%-----------------------------------------------------------------------

function h = mdistortConstruct(ax, action, levels, gsize)

% Check for recognized actions
actions = {'on','off','area','angles','angle','scale','maxscale',...
           'minscale','parscale','merscale','scaleratio'};

if ~any(strcmpi(action, actions))
	error(message('map:mdistort:unknownOption','MDISTORT'))
end

if strcmp(action,'on')
    action = 'maxscale';
end

% Get the map structure from the axes
mstruct = getm(ax);

% Issue a warning if projection is UTM
if strcmp(mstruct.mapprojection,'utm')
    warning(message('map:mdistort:projectionIsUTM','MDISTORT'))
end

% Construct a graticule within the frame limits and compute 
% distortion parameters at the graticule intersections.
% [latgrat, longrat] = framegrat(mstruct, gsize);

% Grid up the area within the frame and project to map coordinates
[xgrat, ygrat] = framegrat(mstruct, gsize);
 
% Convert from planar (x-y) system to geographic latitude-longitude 
[latgrat, longrat] = map.crs.internal.minvtran(mstruct, xgrat, ygrat);

% Assign scaling parameter
param = computeParameter(action, mstruct, latgrat, longrat);

% Set up contour levels
if isempty(levels)
    if any(strcmpi(action, {'angles','angle'}))
        levels = [ 0 0.5 1 2 5 10 20 30 45 90 180];
    else
        levels = [ 0 0.5 1 2 5 10 15 20 50 100  200 400 800];
        levels = [-fliplr(levels) levels(2:end)]; % used for scale calculations
    end
end

% Remove any previously plotted results
mdistortOff(ax);

% Add contour lines and labels to the plot
[~,h] = contour(xgrat,ygrat,param,levels,'Parent',ax,...
    'ShowText','on','Tag','DISTORTMlines');
% [~,h] = contourm(latgrat,longrat,param,levels,'Parent',ax,...
%     'ShowText','on','Tag','DISTORTMlines');

if ~isempty(h)
    % t = findobj(h,'Type','text');
    % set(t,'Color','red','BackgroundColor','none')
    setappdata(h,'MapDistortionProperty',action)
    setappdata(h,'mapgraph',1)  % setm checks for non-empty mapgraph appdata
end

%-----------------------------------------------------------------------

function property = mdistortOff(ax)
% Return the name of the currently plotted distortion property for redisplay
% after a projection change (undocumented behavior used by setm).

h = findobj(ax,'Tag','DISTORTMlines','Type','contour');
% h = findobj(ax,'Tag','DISTORTMlines','Type','hggroup');

if ~isempty(h) && ishghandle(h)
    property = getappdata(h,'MapDistortionProperty');
    delete(h)
else
    property = '';
end

%-----------------------------------------------------------------------

function param = computeParameter(action, mstruct, latgrat, longrat)

% Compute the projection distortion parameters by finite differences
[areascale, angdef, maxscale, minscale, merscale, parscale] = ...
	distortcalc(mstruct, latgrat, longrat);

switch action
    case 'area'
        param = (areascale-1)*100; % in percent
    case {'angles','angle'}
        % Convert angular deformation to degrees
        param = toDegrees(mstruct.angleunits, angdef);
    case {'maxscale','scale'}
        param = (maxscale-1)*100; % in percent
    case 'minscale'
        param = (minscale-1)*100; % in percent
    case 'parscale'
        param = (parscale-1)*100; % in percent
    case 'merscale'
        param = (merscale-1)*100; % in percent
    case 'scaleratio'
        param = (abs(minscale./maxscale)-1)*100; % in percent
end

% Contour results are affect by numerical noise in the distortion
% parameter, so smooth with Gaussian filtering.

% g = fspecial('gaussian',[7 7],3);               % IPT function
g = [
 0.0112972 0.0149145 0.0176195 0.0186260 0.0176195 0.0149145 0.0112972
 0.0149145 0.0196901 0.0232611 0.0245899 0.0232611 0.0196901 0.0149145
 0.0176195 0.0232611 0.0274797 0.0290496 0.0274797 0.0232611 0.0176195
 0.0186260 0.0245899 0.0290496 0.0307091 0.0290496 0.0245899 0.0186260
 0.0176195 0.0232611 0.0274797 0.0290496 0.0274797 0.0232611 0.0176195
 0.0149145 0.0196901 0.0232611 0.0245899 0.0232611 0.0196901 0.0149145
 0.0112972 0.0149145 0.0176195 0.0186260 0.0176195 0.0149145 0.0112972];

% padded = padarray(param,[3 3],'replicate');     % IPT function
[m,n] = size(param);
padded = param([1 1 1 1:m m m m],[1 1 1 1:n n n n]);

param = conv2(padded,g,'valid');

%-----------------------------------------------------------------------

function [xgrat, ygrat] = framegrat(mstruct, gsize)
% Construct a graticule that covers the map frame in the frame's own
% latitude-longitude system (which may be shifted and rotated with
% respect to geographic coordinates), and project it to map X-Y.

% function [latgrat, longrat] = framegrat(mstruct, gsize)
% % Construct a graticule that covers the map frame.
%
% %  Save the projection origin.
% origin = mstruct.origin;

%  Reset the projection origin, moving to the frame's system.
projImplementedViaRotation = ...
    ~any(strcmp(mstruct.mapprojection, {'tranmerc', 'cassinistd', ...
            'eqaconicstd', 'eqdconicstd', 'lambertstd', 'polyconstd'}));
        
if projImplementedViaRotation
    mstruct.origin = [0 0 0];
else
    % Don't modify the origin latitude -- this projection does not
    % simply rotate an auxiliary sphere.
    mstruct.origin = [mstruct.origin(1) 0 0];
end

% Construct the graticule.
epsilon = 100000*epsm('degrees');
if ~mprojIsAzimuthal(mstruct.mapprojection)
    % non-azimuthal frame
    flatlim = mstruct.flatlimit + epsilon * [1 -1];
    flonlim = mstruct.flonlimit + epsilon * [1 -1];
	[latgrat, longrat] = map.internal.graticuleMesh(flatlim, flonlim, gsize);
else
    % azimuthal frame
	rnglim = mstruct.flatlimit;
	rnglim(1) = 0;
	azlim = fromDegrees(mstruct.angleunits, [0+epsilon 360-epsilon]);	
	[rnggrat,azgrat] = map.internal.graticuleMesh(rnglim,azlim, gsize);
	[latgrat, longrat] = reckon( ...
        'gc', 0, 0, rnggrat, azgrat, mstruct.angleunits);
end

% Project the graticule in the system with the shifted origin.
[xgrat, ygrat] = map.crs.internal.mfwdtran(mstruct, latgrat, longrat);

% % Unproject in the original system.
% mstruct.origin = origin;
% [latgrat, longrat] = minvtran(mstruct, xgrat, ygrat);
