function [Z, refvec] = ...
    etopo5AsciiRead(format, filename, samplefactor, latlim, lonlim)
%ETOPO5ASCIIRead Read the ASCII file version of ETOPO5 terrain data.
%
%  [Z, REFVEC] = ETOPO5ASCIIREAD(FORMAT, FILENAME, SAMPLEFACTOR, LATLIM,
%  LONLIM) reads the ETOPO5 data from FILENAME, where FILENAME is a cell
%  array of strings containing the name or names of the ETOPO5 data files.
%
%  FORMAT is a scalar structure containing information about the ETOPO5
%  data files.
%
%  SAMPLEFACTOR is a scalar integer, which when equal to 1 gives the data
%  at its full resolution (1080 by 4320 values).  When SAMPLEFACTOR is an
%  integer n greater than one, every n-th point is returned.  SAMPLEFACTOR
%  must divide evenly into the number of rows and columns of the data file.
%
%  The data is read within the specified latitude and longitude limits. The
%  limits of the desired data are specified as two element vectors of
%  latitude, LATLIM, and longitude, LONLIM, in degrees. The elements of
%  LATLIM and LONLIM must be in ascending order.  LONLIM must be specified
%  in the range [0 360].

% Copyright 2009-2011 The MathWorks, Inc.

%  Ascii data files (N & S hemispheres)
%  Data arranged in W-E columns (0 to 360) by N-S rows (90 to -90).
%  Elevation in meters

sf = samplefactor;
dcell = format.CellSize;
nrows = format.NumRows;
ncols = format.NumCols;
shift = 0;

if all(latlim == [-90 90]) && (all(lonlim == [-180 180]) ...
        || all(lonlim == [0 360]))
    subset = 0;
    
    %  Check to see if samplefactor fits matrix dimensions
    if mod(nrows, sf) ~=0 || mod(ncols, sf) ~=0
        error(message('map:validate:samplefactorNotDivisibleIntoRowsAndCols', ...
            nrows, ncols))
    end
    
    rowlim = [];
    collim = [];
else
    subset = 1;
    %  Check to see if data needs to be shifted (-pi to pi)
    if lonlim(1)<0
        shift = 1;
    end
    [rowlim, collim] = calcRowColLimits(latlim, lonlim, shift, ncols);
end

% Calculate row and col indices
[rowindx1, rowindx2, colindx, maptop, mapleft] = ...
    calculateIndices(rowlim, collim, sf, subset, dcell, shift, nrows, ncols);

% Sort data files so that the 'northern' file is always first.
filename = sort(filename);

% Obtain the file names.
filename = getHemisphereFilenames(filename);

% Northern hemisphere file.
mapN = readHemisphereFile( ...
    filename{1}, 'northern', shift, rowindx1, colindx, ncols);

% Southern hemisphere file.
mapS = readHemisphereFile( ...
    filename{2}, 'southern', shift, rowindx2, colindx, ncols);

Z = [mapS; mapN];
cellsize = sf*dcell;
refvec = [1/cellsize maptop  mapleft];

%--------------------------------------------------------------------------

function filename = getHemisphereFilenames(filename)
% Obtain both northern and southern hemisphere file names.

if numel(filename) == 1
    [path, name] = fileparts(filename{1});
    if isempty(path)
        path = pwd;
    end
    if isequal(name,'etopo5.northern')
        filename{2} = [path filesep 'etopo5.southern.bat'];
    else
        filename{2} = filename{1};
        filename{1} = [path filesep 'etopo5.northern.bat'];
    end
end

%--------------------------------------------------------------------------

function [rowlim, collim] = calcRowColLimits(latlim, lonlim, shift, ncols)
% Convert lat and lon limits to row and column limits.

% Calculate the row limits.
rowlim = calcRowLimits(latlim, ncols);

% Calculate the column limits.
collim = calcColLimits(lonlim, ncols, shift);

%--------------------------------------------------------------------------

function rowlim = calcRowLimits(latlim, ncols)
% Convert latitude limits to row limits.

if latlim(2)==90
    rowlim(1) = 1;
else
    rowlim(1) = floor(-12*(latlim(2)-90)) + 1;
end

if latlim(1)==-90
    rowlim(2) = ncols/2;
else
    rowlim(2) = ceil(-12*(latlim(1)-90));
end

%--------------------------------------------------------------------------

function collim = calcColLimits(lonlim, ncols, shift)
% Convert longitude limits to column limits.

if ~shift
    lon0 = 0;
else
    lon0 = -180;
end

if (~shift && lonlim(1)==0) || (shift && lonlim(1)==-180)
    collim(1) = 1;
else
    collim(1) = floor(12*(lonlim(1)-lon0)) + 1;
end

if (~shift && lonlim(2)==360) || (shift && lonlim(2)==180)
    collim(2) = ncols;
else
    collim(2) = ceil(12*(lonlim(2)-lon0));
end

%--------------------------------------------------------------------------

function [rowindx1, rowindx2, colindx, maptop, mapleft] = ...
    calculateIndices(rowlim, collim, sf, subset, dcell, shift, nrows, ncols)
% Calculate row and col indices.

rowindx1 = [];
rowindx2 = [];
if ~subset
    rowindx1 = 1:sf:nrows;
    rowindx2 = 1:sf:nrows;
    colindx = 1:sf:ncols;
    maptop = 90;
    mapleft = 0;
else
    if rowlim(1)<=nrows && rowlim(2)<=nrows		% submap in N hemisphere
        rowindx1 = rowlim(1):sf:rowlim(2);
        rowindx2 = [];
    elseif rowlim(1)>=nrows && rowlim(2)>=nrows	% submap in S hemisphere
        rowindx1 = [];
        rowindx2 = rowlim(1)-nrows:sf:rowlim(2)-nrows;
    elseif rowlim(1)<=nrows && rowlim(2)>=nrows	% submap in both hemispheres
        rowindx1 = rowlim(1):sf:nrows;
        row1 = sf -(nrows-rowindx1(length(rowindx1)));
        rowindx2 = row1:sf:rowlim(2)-nrows;
    end
    colindx = collim(1):sf:collim(2);
    maptop = 90 - dcell*(rowlim(1)-1);
    mapleft = dcell*(collim(1)-1);
    if shift
        mapleft = dcell*(collim(1)-1) - 180;
    end
end

%--------------------------------------------------------------------------

function Z = readHemisphereFile( ...
    filename, hemisphere, shift, rowindx, colindx, ncols)
% Read ETOPO5 ASCII hemisphere image file.

%  Read from bottom to top of map (first row of matrix is bottom of map)
srow = [0; (25923:25924:27971995)'];	% start row position indicators

if ~isempty(rowindx)
    fid = fopen(filename,'r');
    if fid==-1
        error(message('map:fileio:fileNotFound', filename));
    end
    y = srow(rowindx);
    new_m = length(y);
    for m=new_m:-1:1
        fseek(fid,y(m),'bof');
        temp = fscanf(fid,'%d',[1 ncols]);
        % pad data if necessary
        if size(temp,2) ~= ncols
            numberMissing = ncols-size(temp,2);
            temp = [temp temp(1:numberMissing)]; %#ok<AGROW>
        end
        if shift
            half = ncols/2;
            temp = [temp(half+1:ncols) temp(1:half)];
        end
        Z(new_m+1-m,:) = temp(colindx);
    end
    fclose(fid);
else
    Z = [];
end
