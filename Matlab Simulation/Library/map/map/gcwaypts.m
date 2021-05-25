function [outlat,outlon]=gcwaypts(lat1,lon1,lat2,lon2,nlegs)
%GCWAYPTS   Equally spaced waypoints along great circle track
%
%  [lat,lon] = GCWAYPTS(lat1,lon1,lat2,lon2) returns ten ordered
%  waypoints for the purpose of approximating great circle sailing.
%  All inputs must be scalars.
%
%  [lat,lon] = GCWAYPTS(lat1,lon1,lat2,lon2,nlegs) computes "nlegs"
%  waypoints.
%
%  mat = GCWAYPTS(...) returns a single output, where mat = [lat lon].
%
%  Note:  This is a navigational function -- all lats/longs are in
%         degrees, all distances in nautical miles, all times
%         in hours, and all speeds in knots (nautical miles per hour).
%
%  See also NAVFIX, TRACK, DRECKON, LEGS.

% Copyright 1996-2015 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

narginchk(4,5)

if nargin==4
	nlegs = [];
end

%  Empty argument tests.  Set defaults

if isempty(nlegs);   nlegs = 10;          end

%  Argument dimension tests

if any([max(size(lat1)) max(size(lon1)) max(size(lat2)) max(size(lon2))] ~= 1)
	 error(['map:' mfilename ':mapError'], ...
         'Lat and long inputs must be scalars')
elseif max(size(nlegs)) ~= 1
     error(['map:' mfilename ':mapError'], ...
         'Number of legs must be a scalar')
end

nlegs = ignoreComplex(nlegs, mfilename, 'nlegs');

%  Ensure that nlegs is an integer

nlegs = round(nlegs);

%  Special case if starting from a Polar point (02012002 LSJ)
%  Note that lat1 is a scalar.
if (lat1 == 90) || (lat1 == -90)
    
    [outlat,outlon] = track2(lat1,lon1,lat2,lon2,[],'',nlegs);
    
else
    
	%  Determine total gc distance and initial azimuth
	
	[rng, az] = distance('gc',lat1,lon1,lat2,lon2);
	
	%  Split the ranges into a number of legs
	%  Convert units to rad for calculation since can't do
	%  math on dms or dm, then convert back
	
	rng=rng/nlegs;
	rngvec=rng*(1:nlegs)';
	
	%  Expand the input data for vector processing in reckon
	
	latvec=lat1(ones(size(rngvec)));
	lonvec=lon1(ones(size(rngvec)));
	azvec=az(ones(size(rngvec)));
	
	%  Compute the way pts
	
	[outlat,outlon] = reckon('gc',latvec,lonvec,rngvec,azvec);
	
	%  Build the way point matrix
	
	outlat=[lat1;outlat];  outlon=[lon1;outlon];
    
end

%  Set output arguments if necessary

if nargout < 2;  outlat = [outlat  outlon];   end
