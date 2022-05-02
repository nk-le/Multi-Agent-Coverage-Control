function axesscale(baseaxes,ax)
%AXESSCALE Resize axes for equivalent scale
% 
%   AXESSCALE adjusts all axes in the current figure to have the same scale 
%   as the current axes (gca). In this context, scale means the
%   relationship between axes X and Y coordinates to figure and paper
%   coordinates. The XLimMode and YLimMode of the axes are set to Manual to
%   prevent autoscaling from changing the scale
% 
%   AXESSCALE(hbase) uses the axes hbase as the reference axes, and
%   rescales the other axes in the current figure.
% 
%   AXESSCALE(hbase,hother) uses the axes hbase as the base axes, and
%   rescales only the axes hother.
%
%   Example
%   -------
%   Display the conterminous United States, Alaska, and Hawaii in separate
%   axes in the same figure, with a common scale.
%
%   % Read state names and coordinates, extract Alaska and Hawaii
%   states = shaperead('usastatehi', 'UseGeoCoords', true);
%   statenames = {states.Name};
%   alaska = states(strcmp('Alaska', statenames));
%   hawaii = states(strcmp('Hawaii', statenames));
% 
%   % Create a figure for the conterminous states
%   f = figure;
%   hconus = usamap('conus');
%   geoshow(states, 'FaceColor', [0.5 1 0.5]);
%   load conus gtlakelat gtlakelon
%   geoshow(gtlakelat, gtlakelon,...
%           'DisplayType', 'polygon', 'FaceColor', 'cyan')
%   framem off; gridm off; mlabel off; plabel off
% 
%   halaska = axes('Parent',f);
%   usamap('alaska')
%   geoshow(alaska, 'FaceColor', [0.5 1 0.5]);
%   framem off; gridm off; mlabel off; plabel off
% 
%   hhawaii = axes('Parent',f);
%   usamap('hawaii') 
%   geoshow(hawaii, 'FaceColor', [0.5 1 0.5]);
%   framem off; gridm off; mlabel off; plabel off
% 
%   % Arrange the axes as desired
%   set(hconus, 'Position',[0.1   0.35 0.85 0.6])
%   set(halaska,'Position',[0.02  0.08 0.2  0.2])
%   set(hhawaii,'Position',[0.5   0.1  0.2  0.2])
% 
%   % Resize alaska and hawaii axes
%   axesscale(hconus)
%   hidem([halaska hhawaii])
% 
%   See also PAPERSCALE

% Copyright 1996-2013 The MathWorks, Inc.
% Written by: W. Stumpf, L. Job

if nargin == 0
	baseaxes = gca;
	ax = findobj(gcf,'type','axes');
elseif nargin == 1
	ax = findobj(gcf,'type','axes');
end

% check that the base handle is to an axes
if length(baseaxes(:)) > 1
   error(message('map:axesscale:invalidBaseAxesLength'))
end

if ~ishghandle(baseaxes,'axes')
   error(message('map:axesscale:invalidBaseAxesType'))
end

if any(~ishghandle([baseaxes;ax(:)],'axes')) 
   error(message('map:axesscale:invalidHandle'))
end

a = semimajorAxis(baseaxes);
warned = false;
for i=1:length(ax)
    % Check that ellipsoids are approximately the same to ensure that
    % scaling between geographic and x-y data is consistent.
    ai = semimajorAxis(ax(i));
    if ~isempty(a) && ~isempty(ai) && abs((ai - a)/a) > 0.01
        if ~warned
            warning(message('map:axesscale:ellipsoidUnitsDiffer'))
            warned = true;
        end
    end
end

% Lock down XLim and YLim to ensure that scale remains constant if
% additional data is plotted (and when Position is changed below).
set([baseaxes;ax(:)],'XLimMode','manual','YLimMode','manual');

% get the properties of BASEAXES

xlim = get(baseaxes,'xlim');
ylim = get(baseaxes,'ylim');
pos = get(baseaxes,'pos');
deltax = pos(3);
deltay = pos(4);

% set the xscale and yscale

xscale = deltax/abs(diff(xlim));
yscale = deltay/abs(diff(ylim));

% loop over remaining axes

for i = 1:numel(ax)
    if ishghandle(ax(i),'axes')
        xlim = abs(diff(get(ax(i),'xlim')));
        ylim = abs(diff(get(ax(i),'ylim')));
        pos = get(ax(i),'pos');
        pos(3) = xscale*xlim;
        pos(4) = yscale*ylim;
        set(ax(i),'pos',pos);
    end
end

%--------------------------------------------------------------------------

function a = semimajorAxis(ax)
% If AX is a map axis, return its semimajor axis. If not, return empty.

if ismap(ax)
    ellipsoid = getm(ax,'geoid');
    if isobject(ellipsoid)
        a = ellipsoid.SemimajorAxis;
    else
        a = ellipsoid(1);
    end
else
    a = [];
end
