function [c, h] = contour3m(varargin)
%CONTOUR3M Project 3-D contour plot of map data
%
%   CONTOUR3M(...) is the same as CONTOURM(...) except that the lines
%   for each contour level are drawn in their own horizontal plane, at
%   the z-coordinate equal to the value of that level.
%
%   % Example 1
%   % ---------
%   % In an ordinary axes, contour the EGM96 geoid heights as a 3-D surface
%   % with 50 levels and set the contour line color to black.
%   figure('Color','white')
%   R = georefpostings([-90 90],[0 360],1,1);
%   N = egm96geoid(R);
%   contour3m(N,R,50,'LineColor','black');
%   
%   % Add the geoid as a surface.
%   hold on
%   geoshow(N,R,'DisplayType','surface')
%
%   % Add a title.
%   title('EGM96 Global Geoid Heights with 50 Contour Levels');
%
%   % View in 3-D
%   view(3)
%
%   % Example 2
%   % ---------
%   % In a map axes, contour the topography/bathymetry of South Asia and the
%   % northern Indian Ocean with a contour interval of 500 meters.
%   load topo60c
%   latlim = [ 0  50];
%   lonlim = [35 115];
%   [Z,R] = geocrop(topo60c, topo60cR, latlim, lonlim);
%   figure('Color','white')
%   axesm('lambertstd','MapLatLimit',latlim,'MapLonLimit',lonlim)
%   tightmap
%   axis off
%   contour3m(Z,R,'black','LevelStep',500)
%
%   % Add topo as a surface and set the color map.
%   geoshow(Z,R,'DisplayType','surface')
%   demcmap(Z)
%
%   % Add a title.
%   title('South Asia Topography and Bathymetry with 500 m Contours');
%
%   % View in 3-D
%   set(gca,'DataAspectRatio',[1 1 40000])
%   view(3)

%   See also CLABELM, CONTOUR3, CONTOUR, CONTOURM, GEOSHOW

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,inf)
switch(nargout)
    case 0
        contourm(varargin{:},'LineZ','levels')
    case 1
        c = contourm(varargin{:},'LineZ','levels');
    case 2
        [c, h] = contourm(varargin{:},'LineZ','levels');
end

% Note: The 'LineZ' parameter that appears above is for internal use
% only and may be subject to change.
