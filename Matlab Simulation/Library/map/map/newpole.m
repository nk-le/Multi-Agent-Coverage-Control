function origin = newpole(polelat,polelon,units)
%NEWPOLE  Origin vector to place specific point at pole
%
%  origin = NEWPOLE(lat,lon) computes the origin of a map,
%  given the point (lat,lon) which is to become the north pole (90 0)
%  in the transformed map.  The output matrix origin is a valid
%  origin vector and can be used in any function requiring an origin
%  input (such as AXESM or NEWORIG).
%
%  origin = NEWPOLE(lat,lon,'units') defines the 'units' of the input
%  and output data.  If omitted, 'degrees' are assumed.
%
%  See also PUTPOLE, ORG2POL.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2,3)

if nargin == 2
    units = [];
end

%  Empty argument test

if isempty(units) || ...
        (isStringScalar(units) && strlength(units) == 0)
    units = 'degrees';   
end

%  Dimensional tests

if ~isequal(size(polelat),size(polelon))
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions on lat and lon inputs')
end

%  Ensure column vectors and real input

polelat = real(polelat(:));
polelon = real(polelon(:));

%  Transform input data to radians

[polelat, polelon] = toRadians(units, polelat, polelon);

%  Get the indices for the northern and southern hemisphere new poles

indx1 = find(polelat >= 0);    indx2 = find(polelat <  0);

%  Preallocate output memory

origlat = zeros(size(polelat));
origlon = zeros(size(polelon));
orient  = zeros(size(polelat));

%  Compute the origin for northern hemisphere poles

if ~isempty(indx1)
    origlat(indx1) = pi/2 - polelat(indx1);
	origlon(indx1) = wrapToPi(polelon(indx1)+pi);

    indx3 = find(polelat == pi/2);    %  Correct for any poles staying
    if ~isempty(indx3)                %  at the north pole
		origlon(indx3) = wrapToPi(polelon(indx3));
    end
end

%  Compute the origin for southern hemisphere poles

if ~isempty(indx2)
    origlat(indx2) = pi/2 + polelat(indx2);
    origlon(indx2) = wrapToPi(polelon(indx2));
	orient(indx2)  = -pi;
end

%  Build up the output origin matrix

origin = [origlat origlon orient];

%  Transform back to desired units

origin = fromRadians(units, origin);
