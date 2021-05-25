function [fname,qname] = usgsdems(latlim,lonlim)
%USGSDEMS USGS 1-Degree DEM filenames for latitude-longitude quadrangle
%
%   [FNAME, QNAME] = USGSDEMS(LATLIM, LONLIM) returns cellarrays of the file
%   names and quadrangle names covering the geographic region for 1-degree
%   USGS digital elevation maps (also referred to as "3-arc second" or
%   "1:250,000 scale" DEMs).  The region is specified by scalar latitude
%   and longitude points, or two element vectors of latitude and longitude
%   limits in units of degrees.
%
%   See also DEMDATAUI, GEORASTERINFO, READGEORASTER

% Copyright 1996-2019 The MathWorks, Inc.
% Written by:  A. Kim, W. Stumpf

if isscalar(latlim) && isnumeric(latlim)
	latlim = latlim*[1 1];
else
   validateattributes(latlim, {'numeric'}, {'size',[1,2]}, mfilename, 'LATLIM', 1);
end

if isscalar(lonlim) && isnumeric(lonlim)
	lonlim = lonlim*[1 1];
else
   validateattributes(lonlim, {'numeric'}, {'size',[1,2]}, mfilename, 'LONLIM', 2);
end

filename = 'usgsdems.dat';
fid = fopen(filename, 'r');
if fid==-1
	error(message('map:fileio:unableToOpenFile', filename))
end

% preallocate bounding rectangle data for speed
numElements = 924;
YMIN = zeros(1, numElements); YMAX = YMIN;
XMIN = YMIN; XMAX = YMIN;

% read names and bounding rectangle limits
fnames = cell(numElements, 1);
qnames = fnames;
for n=1:numElements
	fnames{n,1} = fscanf(fid,'%s',1);
	YMIN(n) = fscanf(fid,'%d',1);
	YMAX(n) = fscanf(fid,'%d',1);
	XMIN(n) = fscanf(fid,'%d',1);
	XMAX(n) = fscanf(fid,'%d',1);
	qnames{n,1} = fscanf(fid,'%s',1);
end
fclose(fid);


do = ...
 find( ...
		(...
		(latlim(1) <= YMIN & latlim(2) >= YMAX) | ... % tile is completely within region
		(latlim(1) >= YMIN & latlim(2) <= YMAX) | ... % region is completely within tile
		(latlim(1) >  YMIN & latlim(1) <  YMAX) | ... % min of region is on tile
		(latlim(2) >  YMIN & latlim(2) <  YMAX)   ... % max of region is on tile
		) ...
			&...
		(...
		(lonlim(1) <= XMIN & lonlim(2) >= XMAX) | ... % tile is completely within region
		(lonlim(1) >= XMIN & lonlim(2) <= XMAX) | ... % region is completely within tile
		(lonlim(1) >  XMIN & lonlim(1) <  XMAX) | ... % min of region is on tile
		(lonlim(2) >  XMIN & lonlim(2) <  XMAX)   ... % max of region is on tile
		)...
	);

if ~isempty(do)
	fname = fnames(do);
	qname = qnames(do);
else
	fname = [];
	qname = [];
end
