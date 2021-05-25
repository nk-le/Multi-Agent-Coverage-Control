function [rIndGrat, cIndGrat, Z] = flatRasterRead(filename, ...
    nrows, ncols, rlim, clim, precision, samplefactor, gsize)
%FLATRASTERREAD Read a flat, headerless, raster format file
%
%   [ROWGRAT, COLGRAT, Z] =  flatRasterRead(FILENAME, NROWS, NCOLS, RLIM,
%   CLIM, PRECISION, SAMPLEFACTOR, GSIZE, FCNNAME) reads raster data from a
%   flat, headerless, raster format file.  FILENAME is a string specifying
%   the name of the data file.  NROWS and NCOLS are scalar doubles
%   specifying the number of rows and columns in the raster file.  RLIM and
%   CLIM are two-element scalar doubles specifying the range of the data to
%   subset in the row and column dimension. SAMPLEFACTOR is an
%   integer-valued downsample factor. A SAMPLEFACTOR of 1 returns every
%   point.  GSIZE is a two-element vector specifying the size of the output
%   graticules ROWGRAT and COLGRAT.  If GSIZE is empty, ROWGRAT and COLGRAT
%   have the same size as Z.  PRECISION is a string specifying the binary
%   format of the data to be read as described in the help for
%   multibandread.  FCNNAME is the string name of the calling function and
%   is used in constructing error messages.  Z is a geolocated data grid
%   with coordinates ROWGRAT and COLGRAT in pixel units.

% Copyright 2007-2011 The MathWorks, Inc.

% Read the Z data from the file.
Z = singlebandread(filename, nrows, ncols, rlim, clim, samplefactor, precision);

% Assign rows and columns for the graticule.
readrows = rlim(1):samplefactor:rlim(2);
readcols = clim(1):samplefactor:clim(2);

% Construct a graticule of row and column indices.
if isempty(gsize)
    % Case: size(grat) = size(Z)
    [rIndGrat,cIndGrat] = makegraticule(readrows,readcols);
else
    % Texture map the data to a smaller graticule.
    [rIndGrat,cIndGrat] = makegraticule( ...
        [min(readrows) max(readrows)], ...
        [min(readcols) max(readcols)], ...
        gsize);
end

%--------------------------------------------------------------------------

function Z = singlebandread( ...
    filename, nrows, ncols, rlim, clim, samplefactor, precision)

% Verify the precision and the file size.
bytesPerPixel = getNumberOfBytesPerPixel(precision);
fileSize = bytesPerPixel * nrows * ncols;
fileList = dir(filename);
if fileList.bytes ~= fileSize
    error(message('map:fileio:inconsistentFileSize', ...
        num2str(fileSize), num2str(fileList.bytes)));
end

% Read the data from the file. The format of the file is flat.
imgSize = [nrows,ncols,1];
offset = 0;
interleave = 'bsq';
order = 'ieee-be';
Z = multibandread(filename, imgSize, precision, offset, interleave, order, ...
    {'row', 'range', [rlim(1),samplefactor,rlim(2)]},...
    {'col', 'range', [clim(1),samplefactor,clim(2)]});

%--------------------------------------------------------------------------

function bytesPerPixel = getNumberOfBytesPerPixel(precision)
% getNumberOfBytesPerPixel returns the number of bytes in a pixel based on
% the PRECISION string.

switch precision
    
    % Platform-independent precision strings.
    case {'int8',  'integer*1', 'uint8', 'char', 'uchar', 'schar'}
        bytesPerPixel = 1;
        
    case {'int16', 'integer*2', 'uint16' }
        bytesPerPixel = 2;
        
    case {'int32', 'integer*4', 'uint32', 'float32', 'real*4'}
        bytesPerPixel = 4;
        
    case {'int64', 'integer*8', 'uint64', 'float64', 'real*8'}
        bytesPerPixel = 8;
    
    % Platform-dependent precision strings.
    % The following platform dependent precisions are also supported but
    % they are not guaranteed to be the same size on all platforms. Assume
    % a size, and notify user.
        
    case {'short', 'ushort' , 'unsigned short'}
        bytesPerPixel = 2;
        warning(message('map:fileio:twoBytePrecisionAssumption', precision));
        
    case {'int', 'long', 'uint', 'unsigned int', 'ulong', 'unsigned long', 'float'}
        bytesPerPixel = 4;
        warning(message('map:fileio:fourBytePrecisionAssumption', precision));
        
    case 'double'
        bytesPerPixel = 8;
        warning(message('map:fileio:eightBytePrecisionAssumption', precision));
        
    otherwise
        error(message('map:fileio:invalidPrecision', precision))
end

%--------------------------------------------------------------------------

function [row, col] = makegraticule(row, col, npts)
%MAKEGRATICULE  Construct graticule from indices
%
%   [ROW, COL] = MAKEGRATICULE(ROW, COL) takes the vectors ROW and COL and
%   returns graticule matrices.  
%
%   [ROW, COL] = MAKEGRATICULE(ROW, COL, NPTS) returns a graticule mesh
%   with size NPTS.  The input vectors are two element vectors specifying
%   the graticule ROW and COLUMN limits. NPTS is a two element vector where
%   NPTS = [# ROW grid points, # COL grid points].  If NPTS = [], then the
%   graticule returned is the default graticule size 50-by-100.

if nargin == 2
    %  Two arguments defaults to number of row and column elements.
    npts = [numel(row) numel(col)];   
elseif isempty(npts)
    % Use the default graticule size.
    npts = [50 100];
end

if numel(row) == 2
    row = linspace(min(row), max(row), max(npts(1), numel(row)));
end

if numel(col) == 2
    col = linspace(min(col), max(col), max(npts(2), numel(col)));
end

% Create the arrays.
[col,row] = meshgrid(col,row);
