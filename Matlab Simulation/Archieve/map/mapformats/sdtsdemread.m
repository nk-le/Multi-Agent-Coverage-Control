function [Z, refmat] = sdtsdemread(filename)
% SDTSDEMREAD Read data from SDTS raster/DEM data set
%
%       SDTSDEMREAD will be removed in a future release.
%       Use READGEORASTER instead.
% 
%   [Z, R] = SDTSDEMREAD(FILENAME) reads data from an SDTS raster or DEM
%   data set.  Z is a matrix containing the elevation/data values.  R is a
%   referencing matrix.  NaNs are assigned to elements of Z corresponding
%   to null data values or fill data values in the cell module.
%
%   FILENAME can be the name of the SDTS Catalog Directory file (*CATD.DDF)
%   or the name of any of the other files in the data set.  FILENAME may
%   include the directory name, otherwise FILENAME will be searched for in
%   the current directory and the MATLAB path.  If any of the files
%   specified in the Catalog Directory are missing SDTSDEMREAD will fail.
%    
%   Example
%   -------
%   [Z, R] = sdtsdemread('9129CATD.ddf');
%   mapshow(Z,R,'DisplayType','contour')
%
%   See also READGEORASTER

% Copyright 1996-2020 The MathWorks, Inc.

% Ensure that filename is a valid text type.
if nargin > 0
    filename = convertStringsToChars(filename);
end
validateattributes(filename, {'char','string'}, {'scalartext'}, mfilename, 'FILENAME', 1);

% Convert the filename input to the catalog/directory file name and ensure
% that the extension is upper case.
[pn,fn,xtn] = fileparts(filename);
fn1 = [fn(1:end-4) 'CATD'];
xtn = upper(xtn);
filename = fullfile(pn,[fn1 xtn]);

% Validate filename and append the extension, .DDF, if needed.
filename = internal.map.checkfilename(filename, {'DDF'}, mfilename, 1);

% Return both the INFO structure and the DEM data via the MEX interface.
[info, Z] = sdtsIfc(filename);

if isempty(Z)
    % Z is empty, the file is not a SDTS DEM file.
    error(message('map:fileio:invalidFileType', [fn, xtn], 'SDTS DEM'))
end

% Transpose the elevation data matrix.
Z = Z';

% Replace both void values and fill values with NaN.
d = info.ProfileStruct;
Z((Z==d.FillValue) |...
  (Z==d.VoidValue)) = NaN;

% Calculate the referencing matrix, if requested.
if nargout == 2
    [ExtSpatialOrigin] = transInt2Ext([d.XScaleFactor, d.YScaleFactor],...
                                      [d.XTopLeft, d.YTopLeft],...
                                      [d.XOrigin, d.YOrigin]);

    x11 = ExtSpatialOrigin(1) + d.XHorizResolution/2;
    y11 = ExtSpatialOrigin(2) - d.YHorizResolution/2;
    dx = d.XHorizResolution;
    dy = -d.YHorizResolution;
    
    W = [dx   0   x11;
          0  dy   y11];
    
    refmat = map.internal.referencingMatrix(W);
end

%--------------------------------------------------------------------------

function [extSpatial] = transInt2Ext(ScaleFactor,...
                                     IntSpatialAddress,...
                                     IntExtOrigin)
  
% This performs the transformation of a spatial address in the internal
% spatial reference system to the external reference system. The
% parameters: "extSpatial", "ScaleFactor", "IntSpatialAddress" and
% "IntExtOrigin" are vectors containing the X and Y components. This
% transformation is implemented by:
%
%  [X]   [SX  0 ]   [X']     [Xo]
%  [Y] = [0   SY] * [Y']  +  [Yo]
%
% where,
% X,Y   = geospatial components of spatial address in the external system 
% SX,SY = geospatial scaling factors for scaling to the external system, 
%         forming the diagonal elements of a diagonal matrix with 
%         off-diagonal zero elements
% X',Y' = geospatial components of spatial address in internal system 
% Xo,Yo = geospatial components of spatial address of origin of internal 
%         system in external system

extSpatial = diag(ScaleFactor) * IntSpatialAddress' + IntExtOrigin';
