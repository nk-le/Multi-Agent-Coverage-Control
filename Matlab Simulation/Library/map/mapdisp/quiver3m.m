function h = quiver3m(lat, lon, alt, u, v, w, varargin)
%QUIVER3M Project 3-D quiver plot on map axes
%
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt) projects a three dimensional vector
%  plot in the current map axes.  The vectors are plotted from
%  (lat, lon, alt) to (lat + dlat, lon + dlon, alt + dalt). Note that both
%  (lat,lon) and (dlat,dlon) must be in the same angle units as the current
%  map. The units of alt and dalt must be mutually consistent, because they
%  are used together to define the altitude of the vectors above the map.
%
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt,s) uses the input s to scale the
%  vectors after they have been automatically scaled to fit within
%  the rectangular grid.  If omitted, s = 1 is assumed.  To suppress the
%  automatic scaling, specify s = 0.
%
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt,'LineSpec'),
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt,'LineSpec',s),
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt,'LineSpec','filled') and
%  QUIVER3M(lat,lon,alt,dlat,dlon,dalt,'LineSpec',s,'filled') use the
%  LineSpec value to define the line style of the vectors.  If a symbol is
%  specified in 'LineSpec', then the symbol is plotted at the base of the
%  vector.  Otherwise, an arrow is drawn at the end of the vector.
%  If a marker is specified at the base, then this symbol can be filled in
%  by providing the input 'filled'.
%
%  h = QUIVER3M(...) returns a vector of handles to the projected
%  vectors.
%
%  See also QUIVERM, QUIVER, QUIVER3.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Argument tests
validateattributes(lat, {'double'}, {'2d'}, 'QUIVER3M', 'LAT', 1)
validateattributes(lon, {'double'}, {'2d'}, 'QUIVER3M', 'LON', 2)
validateattributes(alt, {'double'}, {'2d'}, 'QUIVER3M', 'ALT', 3)
validateattributes(u, {'double','single'}, {'2d'}, 'QUIVER3M', 'DLAT', 4)
validateattributes(v, {'double','single'}, {'2d'}, 'QUIVER3M', 'DLON', 5)
validateattributes(w, {'double','single'}, {'2d'}, 'QUIVER3M', 'DLON', 6)
     
if ~isequal(size(lat),size(lon),size(alt),size(u),size(v),size(w))
     error('map:quiver3m:inconsistentDims', ...
         'Inconsistent dimensions for inputs.')
end

%  Parts of quiverm (quiver3m) closely parallel quiver (quiver3).
%  Unfortunately, you can not simply call quiver with projected
%  lat and lon data.  You do not get the appropriate clip and trim
%  data, which would preclude further re-projecting (using setm) of
%  the map.

%  Parse the optional input variables
if nargin > 6
    [varargin{:}] = convertStringsToChars(varargin{:});
end
switch length(varargin)
    case 1
        filled = [];
        if ~ischar(varargin{1})
            autoscale  = varargin{1};
            linespec = [];
        else
            linespec = varargin{1};
            autoscale = [];
        end

    case 2
        linespec = varargin{1};
        if ~ischar(varargin{2})
            autoscale  = varargin{2};
            filled = [];
        else
            filled = varargin{2};
            autoscale = [];
        end

    case 3
        linespec = varargin{1};
        autoscale = varargin{2};
        filled = varargin{3};

    otherwise
        linespec = [];
        autoscale = [];
        filled = [];
end

%  If unspecified, set autoscale to unity unless there
%  is only one unique point:
if isempty(autoscale)
    mstruct = gcm;
    if multipleDistinctLocations(lat,lon,mstruct.angleunits)
        autoscale = 1;
    else
        autoscale = 0;
    end
end

if ~isempty(linespec)
    [~, ~, lmark] = internal.map.parseLineSpec(linespec);
else
    lmark = '';
end

%  Autoscaling operation is taken directly from quiver3.
if autoscale
    % Base autoscale value on average spacing in the lat and lon
    % directions.  Estimate number of points in each direction as
    % either the size of the input arrays or the effective square
    % spacing if lat and lon are vectors.
    if min(size(lat))==1, n=sqrt(numel(lat));
        m=n;
    else
        [m,n]=size(lat);
    end
    delx = diff([min(lat(:)) max(lat(:))])/n;
    dely = diff([min(lon(:)) max(lon(:))])/m;
    delz = diff([min(alt(:)) max(alt(:))])/max(m,n);
    del  = sqrt(delx.^2 + dely.^2 + delz.^2);
    len  = sqrt((u/del).^2 + (v/del).^2 + (w/del).^2);
    autoscale = autoscale*0.9 / max(len(:));
    u = u*autoscale;
    v = v*autoscale;
    w = w*autoscale;
end

%  Make inputs into row vectors.  Must be done after autoscaling
lat = lat(:)';
lon = lon(:)';
alt = alt(:)';
u = double(u(:)');
v = double(v(:)');
w = double(w(:)');

%  Make the vectors
vellat = [lat;  lat+u];
vellon = [lon;  lon+v];
velalt = [alt;  alt+w];
vellat(3,:) = NaN;
vellon(3,:) = NaN;
velalt(3,:) = NaN;

%  Set up for the next map
nextmap;

%  Project the vectors as lines only
if ~isempty(linespec)
    h1 = linem(vellat(:),vellon(:),velalt(:),linespec,'Marker','none');
else
    h1 = linem(vellat(:),vellon(:),velalt(:),'Marker','none');
end

%  Make and plot the arrow heads if necessary
alpha = 0.33;   % Size of arrow head relative to the length of the vector
beta  = 0.33;   % Width of the base of the arrow head relative to the length
h2 = [];

if isempty(lmark)
    % Normalize beta
    beta = beta * sqrt(u.*u + v.*v + w.*w)/sqrt(u.*u + v.*v + eps*eps);

    % Make arrow heads and plot them
    hu = [lat+u-alpha*(u+beta*(v+eps));lat+u; ...
        lat+u-alpha*(u-beta*(v+eps))];       hu(4,:) = NaN;
    hv = [lon+v-alpha*(v-beta*(u+eps));lon+v; ...
        lon+v-alpha*(v+beta*(u+eps))];       hv(4,:) = NaN;
    hw = [alt+w-alpha*w;alt+w;alt+w-alpha*w];  hw(4,:) = NaN;

    if ~isempty(linespec)
        h2 = linem(hu(:),hv(:),hw(:),linespec,'Marker','none');
    else
        h2 = linem(hu(:),hv(:),hw(:),'Marker','none');
    end
end

%  Plot a marker on the base if necessary
h3 = [];
if ~isempty(lmark)
    h3 = linem(lat,lon,alt,linespec,'LineStyle','none');
    if strcmp(filled,'filled')
        set(h3,'MarkerFaceColor',get(h1,'color'));
    end
end

%  Set the tags
set([h1;h2;h3],'Tag','Quivers')

%  Set the output argument if necessary
if nargout == 1
    h = [h1; h2; h3];
end
