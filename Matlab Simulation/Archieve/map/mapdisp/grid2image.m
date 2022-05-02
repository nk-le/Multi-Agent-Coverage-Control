function hndl = grid2image(varargin)
%GRID2IMAGE Display regular data grid as image
%
%   GRID2IMAGE(A, R) displays a regular data grid A as an image. The
%   image is displayed in unprojected form, with longitude as X and
%   latitude as Y, producing considerable distortion away from the
%   Equator. A can be M-by-N or M-by-N-by-3, and can contain double,
%   uint8, or uint16 data. The grid is georeferenced to latitude-
%   longitude by R, which can be a geographic raster reference object, a
%   referencing vector, or a referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z) and its RasterInterpretation must be
%   'cells'.
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel.
%
%   GRID2IMAGE(A,R,'PropertyName',PropertyValue,...) applies the
%   specified image properties to the display.
%
%   h = GRID2IMAGE(...) returns the handle of the image object
%   displayed.
%
%   Example
%   -------
%   load topo60c
%   figure
%   grid2image(topo60c,topo60cR)
%
%  See also IMAGE, MAPSHOW, MAPVIEW
 
% Copyright 1996-2020 The MathWorks, Inc.

% Verify the input count
narginchk(2, Inf)

% Get the inputs
[varargin{:}] = convertStringsToChars(varargin{:});
[A,R,ax,xlbl,ylbl,props] = parseInputs(varargin{:});

% Compute the XData and YData corresponding to the centers of the first
% and last columns and first and last rows, and construct an image object.
rasterSize = R.RasterSize;
xdata = R.intrinsicXToLongitude([1 rasterSize(2)]);
ydata = R.intrinsicYToLatitude( [1 rasterSize(1)]);
h = image(A,'XData',xdata,'YData',ydata,'CDataMapping','scaled','Parent',ax);

% Override the automatic reversal of YDir by image.
set(ax,'Ydir','Normal');

% Set properties if necessary
if ~isempty(props)
  set(h,props{:,1},props{:,2});
end

% Set labels if necessary
if ~isempty(xlbl)
  xlabel(xlbl);
end
if ~isempty(ylbl)
  ylabel(ylbl);
end

% Return the handle
if nargout == 1
  hndl = h;
end

%************************************************************************
function [A,R,parent,xlabel,ylabel,props] = parseInputs(A, R, varargin)

validateattributes(A,{'numeric'}, {'real','nonempty'},'GRID2IMAGE','A',1)

% If R is already spatial referencing object, validate it. Otherwise
% convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(A), 'degrees', 'grid2image', 'R', 2);

assert(strcmp(R.RasterInterpretation,'cells'), ...
    'map:validate:unexpectedPropertyValueString', ...
    'Function %s expected the %s property of input %s to have the value: ''%s''.', ...
    'grid2image', 'RasterInterpretation', 'R', 'cells')

xlabel = 'Longitude';
ylabel = 'Latitude';

if nargin == 2
  parent = newplot;
end

props = [];
if nargin > 2
  if mod(numel(varargin),2) ~= 0
    error('map:grid2image:invalidPropPairs', 'The property/value inputs must always occur as pairs.')
  end
  params = varargin(1:2:end);
  values = varargin(2:2:end);

  idx = find(strcmpi('parent', params));
  if isempty(idx)
    parent = gca;
  else
    parent = values{idx};
    params(idx) = [];
    values(idx) = [];
  end
  if ~isempty(params) && ~isempty(values)
    props = {params,values};
  end
end

if ismap(parent)
  error('map:grid2image:invalidAxes', 'Image displays do not go in map axes.')
end

if ndims(A) > 3  
  error('map:grid2image:invalidCData', ...
      'Indexed CData must be size M-by-N; TrueColor CData must be size M-by-N-by-3.')
end
