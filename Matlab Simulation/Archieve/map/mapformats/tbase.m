function [Z, refvec] = tbase(scalefactor,latlim,lonlim)
%TBASE  Read 5-minute global terrain elevations from TerrainBase
%
%    TBASE will be removed in a future release. Use READGEORASTER instead.
%    (Import of TerrainBase will no longer be supported; use READGEORASTER
%    to import terrain data in a different supported format.)
%
%  [Z, REFVEC] = TBASE(SAMPLEFACTOR) reads the data for the entire world,
%  downsampling the data by the scale factor. The result is returned as a
%  regular data grid and referencing vector. Elevations and depths are
%  given in meters above or below mean sea level.
%
%  [Z, REFVEC] = TBASE(SAMPLEFACTOR, LATLIM, LONLIM) reads the data for the
%  part of the world within the latitude and longitude limits. The limits
%  must be two-element vectors in units of degrees. Longitude limits can be
%  defined in the range [-180 180] or [0 360]. For example,
%  lonlim = [170 190] returns data centered on the dateline, while
%  lonlim = [-10  10] returns data centered on the prime meridian.
%
%  See also READGEORASTER

% Copyright 1996-2021 The MathWorks, Inc.

%  Binary data file (byteorder - little endian)
%  Data arranged in W-E columns (-180 to 180) by N-S rows (90 to -90).
%  Elevation in meters

switch nargin        
    case 1
        subset = 0;
        latlim = [-90 90];
        lonlim = [-180 180];
        
    case 2
        subset = 1;
        lonlim = [-180 180];
        
    case 3
        subset = 1;
end

sf = scalefactor;
dcell = 5/60;			% 5 minute grid
shift = false;

if ~subset
    % Check to see if scalefactor fits matrix dimensions
    map.internal.assert(mod(1080, sf) == 0 && mod(4320, sf) == 0, ...
        'map:validate:samplefactorNotDivisibleIntoRowsAndCols', ...
        1080, 4320 );
else
    checkgeoquad(latlim, lonlim, mfilename, 'LATLIM', 'LONLIM', 2, 3)
    map.internal.assert(lonlim(1) <= lonlim(2), ...
        'map:maplimits:expectedAscendingLonlim');
    
    % Check to see if data needs to be shifted (0 to 2pi)
    shift = lonlim(2)>180;
    if shift
        map.internal.assert(0 <= lonlim(1) && lonlim(2) <= 360, ...
            'map:validate:expectedRange', ...
            'LONLIM', '0', 'lonlim', '360');
    else
        map.internal.assert(-180 <= lonlim(1) && lonlim(2) <= 180, ...
            'map:validate:expectedRange', ...
            'LONLIM', '-180', 'lonlim', '180');
    end
    
    %  Convert lat and lon limits to row and col limits
    if latlim(2)==90
        rowlim(1) = 1;
    else
        rowlim(1) = floor(-12*(latlim(2)-90)) + 1;
    end
    if latlim(1)==-90
        rowlim(2) = 2160;
    else
        rowlim(2) = ceil(-12*(latlim(1)-90));
    end
    if ~shift
        lon0 = -180;
    else
        lon0 = 0;
    end
    if (~shift && lonlim(1)==-180) || (shift && lonlim(1)==0)
        collim(1) = 1;
    else
        collim(1) = floor(12*(lonlim(1)-lon0)) + 1;
    end
    if (~shift && lonlim(2)==180) || (shift && lonlim(2)==360)
        collim(2) = 4320;
    else
        collim(2) = ceil(12*(lonlim(2)-lon0));
    end

end

%  Read TBASE binary image file
fid = fopen('tbase.bin','rb','ieee-le');
if fid==-1
    error(message('map:fileio:fileNotFound', 'tbase.bin'))
end
if ~subset
    firstrow = 0;
    lastrow = 2*sf*floor(2159/sf)*4320;
    colindx = 1:sf:sf*floor(4319/sf)+1;
    maptop = 90;
    mapleft = -180;
else
    firstrow = 2*(rowlim(1)-1)*4320;
    lastrow = firstrow + 2*sf*floor((rowlim(2)-rowlim(1))/sf)*4320;
    colindx = collim(1):sf:collim(1)+sf*floor((collim(2)-collim(1))/sf);
    maptop = 90 - dcell*(rowlim(1)-1);
    mapleft = -180 + dcell*(collim(1)-1);
    if shift
        mapleft = dcell*(collim(1)-1);
    end
end

% start row position indicators
srow = firstrow:2*sf*4320:lastrow;			
rows = length(srow);

%  Read from bottom to top of map (first row of matrix is bottom of map)
for m=rows:-1:1
    fseek(fid,srow(m),'bof');
    temp = fread(fid,[1 4320],'int16');
    if shift
        temp = [temp(2161:4320) temp(1:2160)];
    end
    Z(rows-m+1,:) = temp(colindx);
end
fclose(fid);
cellsize = 1/(sf*dcell);
refvec = [cellsize maptop mapleft];
