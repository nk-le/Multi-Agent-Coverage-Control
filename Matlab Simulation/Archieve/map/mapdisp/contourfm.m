function [c, h] = contourfm(varargin)
%CONTOURFM  Project filled 2-D contour plot of map data
%
%   CONTOURFM(...) is the same as CONTOURM(...) except that the areas
%   between contours are filled with colors. For each contour interval,
%   CONTOURFM selects a distinct color from the figure's colormap.
%   You can obtain the same result by setting 'Fill','on' and
%   'LineColor','black' when calling CONTOURM.
%
%   Example 1
%   ---------
%   % Contour and fill the EGM96 geoid heights using 10 contour levels.
%   R = georefpostings([-90 90],[0 360],1,1);
%   N = egm96geoid(R);
%   figure
%   worldmap world
%   contourfm(N,R,10);
%
%   Example 2
%   ---------
%   % Contour and fill bathymetry and elevation data for the area around
%   % Korea, with contours at levels ranging from -5000 meters to 2500
%   % meters in increments of 500 meters.
%   load korea5c
%   figure('Color','white')
%   worldmap(korea5c,korea5cR)
%   [~,h] = contourfm(korea5c,korea5cR,-4500:500:2500);
%   caxis([-5000 3000])
%   contourcbar('southoutside')
%   title('Elevation and Bathymetry in meters')
%
%   See also CONTOURCBAR, CONTOURF, CONTOURM, CONTOUR3M.

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,inf)
switch(nargout)
    case 0
        contourm(varargin{:},'Fill','on','DefaultLineColor','black');
    case 1
        c = contourm(varargin{:},'Fill','on','DefaultLineColor','black');
    case 2
        [c, h] = contourm(varargin{:},'Fill','on','DefaultLineColor','black');
end

% Note: The 'DefaultLineColor' parameter that appears above is for
% internal use only and may be subject to change. Outside the toolbox,
% the 'LineColor' parameter should be used with contourm instead.
