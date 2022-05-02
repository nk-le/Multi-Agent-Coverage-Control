function fcn = mapstructfcn(geometry, fcnname)
%MAPSTRUCTFCN Wrap map display function for use with geostructs
%
%   FCN = MAPSTRUCTFCN(GEOMETRY, FCNNAME) returns a handle to a nested
%   function that calls the function returned by MAPVECFCN(GEOMETRY,
%   FCNNAME) only if given non-NaN and non-empty x,y coordinates; otherwise
%   the nested function returns a zero-by-one empty.
%
%   See also MAPSHOW, MAPVECFCN, MAPSTRUCTSHOW, MAPVECSHOW.
%
% Copyright 2006 The MathWorks, Inc.

plotfcn = mapvecfcn(geometry, fcnname);
fcn = @wrappedfcn;

   function h = wrappedfcn(x, y, varargin)
      if any(~isnan(x(:)))
         h = plotfcn(x, y, varargin{:});
      else
         h = reshape([],[0 1]);
      end
   end

end
