function [newlat,newlong]=navfix(lat,long,az,casetype,drlat,drlong)
%NAVFIX  Mercator-based navigational fix
%
%  [latfix,lonfix] = NAVFIX(lat,long,az) exactly parallels the manual
%  navigation plotting method to establish rhumb-line and range-arc cross
%  fixes.  Manual navigation employs a mercator projection chart, on which
%  azimuthal sightings are plotted as straight (rhumb) lines.  Range arcs
%  are of constant radius on the projection, i.e., they appear as
%  perfect circles on a displayed mercator chart, as one might draw
%  with a compass.  Any number (at least two) of sighting object positions
%  and azimuths or ranges can be input; one output row will be provided for
%  each combination of pairs of the input objects. The output is a two-column
%  vector;  both entries in a row are NaN's when no intersection exists for
%  that pair.  Two lines of position will return an intersection point (if any)
%  and a NaN, as two lines can intersect once at most. Where arcs
%  are involved, there may be two points of intersection (navigational
%  ambiguity).
%
%  [latfix,lonfix] = NAVFIX(lat,long,az,casetype) uses input object
%  types are designated by the input "casetype" vector elements, which are
%  ones corresponding to lines of position, (and for which the input
%  azimuth is in degrees), and zeros corresponding to arcs of position, (for
%  which "az" is really a range in nautical miles).
%
%  [latfix,lonfix] = NAVFIX(lat,long,range,casetype) determines the range
%  scale used for each arc from the mercator scale at the arc center.
%
%  [latfix,lonfix] = NAVFIX(lat,long,az,casetype,drlat,drlong) provides
%  a dead-reckoning (DR) latitude and longitude to resolve ambiguity by
%  returning for each pair of objects only the intersection closest to
%  the DR position.  Under this situation, when any pair of objects fails
%  to intersect, the output is empty and a warning is displayed.
%
%  mat = NAVFIX(...) returns a single output, where mat = [latfix lonfix].
%
%  Note:  This is a navigational function -- all lats/longs are in
%         degrees, all distances in nautical miles, all times
%         in hours, and all speeds in knots (nautical miles per hour).
%
%  See also LEGS, TRACK, DRECKON, GCWAYPTS.

% Copyright 1996-2015 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

%  Reference for principles of graphical navigational plotting:
%  Richard R. Hobbs,"Marine Navigation 1: Piloting", 2nd Edition,
%  Naval Institute Press, Annapolis, MD, 1981.

if nargin==3
	drlat=[];
    drlong=[];
    casetype = [];
elseif nargin==4
	drlat=[];
    drlong=[];
elseif nargin~=6
    error(message('map:validate:invalidArgCount'))
end

validateattributes( lat, {'double'}, {'2d'}, 'NAVFIX',  'LAT', 1)
validateattributes(long, {'double'}, {'2d'}, 'NAVFIX', 'LONG', 2)
validateattributes(  az, {'double'}, {'2d'}, 'NAVFIX',   'AZ', 3)

if ~isequal(size(lat), size(long), size(az))
error(message('map:validate:inconsistentSizes3', ...
    'NAVFIX', 'LAT', 'LONG', 'AZ'))
end

if isscalar(lat)
    error('map:nav:expectedMultiplePoints', ...
        'At least two geographic objects are required to crossfix.')
end

if isempty(casetype)
    casetype = ones(size(lat));
elseif ~isequal(size(casetype), size(lat))
    error(message('map:validate:inconsistentSizes2', ...
        'NAVFIX', 'CASETYPE', 'LAT'))
end

if ~isempty(drlat)
    validateattributes(drlat, {'double'}, {'scalar'}, ...
        'navfix', 'DRLAT', 5)
    validateattributes(drlong, {'double'}, {'scalar'}, ...
        'navfix', 'DRLONG', 6)
end

%  Ensure real inputs
lat      = ignoreComplex(lat,      mfilename, 'lat');
long     = ignoreComplex(long,     mfilename, 'long');
az       = ignoreComplex(az,       mfilename, 'az');
casetype = ignoreComplex(casetype, mfilename, 'casetype');
drlat    = ignoreComplex(drlat,    mfilename, 'drlat');
drlong   = ignoreComplex(drlong,   mfilename, 'drlong');

%  Arcs of position must be drawn using a range scale
%  appropriate to their latitude on the Mercator chart

indx=find(casetype==0);

%  For arcs of position, "az" is a range in nautical miles.  There
%  are 60 nm in a degree of latitude, (This is not exactly true, but
%  it is sometimes taken as a truism in Mercator plotting in navigation.)
%  The Euclidean distance in a projected Mercator system varies with
%  latitude, so following manual practice the Euclidean distance
%  appropriate to the covered latitude range is used.

if ~isempty(indx)
	[~,rup] = merccalc(lat(indx)+az(indx)/60,long(indx),'forward','degrees');
	[~,rdown] = merccalc(lat(indx)-az(indx)/60,long(indx),'forward','degrees');
	az(indx)=abs(rup-rdown)/2;
end

jndx=find(casetype==1);

% Azimuths are from the ship, but calculations are from the objects-- take the
% complements of each azimuth

if ~isempty(jndx)
	az(jndx)=zero22pi(az(jndx)+180,'degrees');
end

if length(az)~=length([jndx(:);indx(:)])
	error('map:nav:expectedCasetypeToBeLogical', ...
        'Elements of CASETYPE must be 0 or 1.')
end

% Pairwise match the navigation objects

pair=nchoosek(1:length(casetype),2);

% Since "no entry" is a NaN, initialize as such

nanholder = NaN;
newlat  = nanholder;   newlat  = newlat(ones(size(pair)));
newlong = nanholder;   newlong = newlong(ones(size(pair)));

% Determine intersection points for every pair

for i=1:size(pair,1)
	if casetype(pair(i,1))==1
		if casetype(pair(i,2))==1  % This is the casetype where both objects are azimuths (rhumb lines)

			[newlat(i,1),newlong(i,1)]=rhxrh(lat(pair(i,1)),long(pair(i,1)),az(pair(i,1)),lat(pair(i,2)),long(pair(i,2)),az(pair(i,2)),'degrees');

			% If intersection is in opposite direction, discount it.  This can occur because
			% rhumb lines are defined in both directions from any given point, but
			% sightings are specific to the azimuth given.  Both the zero22pi and the npi2pi
			% tests are done to ensure that 359.999 is counted as close to 0, and -180 as close to 180

			if abs(zero22pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-zero22pi(az(pair(i,1)),'degrees'))>90 && ...
					abs(npi2pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-npi2pi(az(pair(i,1)),'degrees'))>90

				newlat(i,1)=NaN;
				newlong(i,1)=NaN;
			end

			if abs(zero22pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-zero22pi(az(pair(i,2)),'degrees'))>90 && ...
					abs(npi2pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-npi2pi(az(pair(i,2)),'degrees'))>90

				newlat(i,1)=NaN;
				newlong(i,1)=NaN;
			end



		else   % casetype with first one an azimuth, second one a range

			[linex,liney]=merccalc(lat(pair(i,1)),long(pair(i,1)),'forward','degrees');
			[centerx,centery]=merccalc(lat(pair(i,2)),long(pair(i,2)),'forward','degrees');

			% slope of line
			slope=tan(pi/2 - deg2rad(az(pair(i,1))));
			if isinf(slope)
				intercpt=linex;
			else
				intercpt=liney-slope*linex;
			end

			% radius of circle
			range=az(pair(i,2));

			[xout,yout]=linecirc(slope,intercpt,centerx,centery,range);
			[newlat(i,:), newlong(i,:)]=merccalc(xout,yout,'inverse','degrees');

			% If intersection is in opposite direction, discount it.  This can occur because
			% rhumb lines are defined in both directions from any given point, but
			% sightings are specific to the azimuth given

			if abs(zero22pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-zero22pi(az(pair(i,1)),'degrees'))>90 && ...
					abs(npi2pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-npi2pi(az(pair(i,1)),'degrees'))>90
				disp('here1')

				newlat(i,1)=NaN;
				newlong(i,1)=NaN;
			end
			if abs(zero22pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,2),newlong(i,2),'degrees'),'degrees')-zero22pi(az(pair(i,1)),'degrees'))>90 && ...
					abs(npi2pi(azimuth('rh',lat(pair(i,1)),long(pair(i,1)),newlat(i,2),newlong(i,2),'degrees'),'degrees')-npi2pi(az(pair(i,1)),'degrees'))>90

				newlat(i,2)=NaN;
				newlong(i,2)=NaN;
			end
		end

	elseif	casetype(pair(i,2))==1   % This is the casetype with the first a range, second an azimuth

		[linex,liney]=merccalc(lat(pair(i,2)),long(pair(i,2)),'forward','degrees');
		[centerx,centery]=merccalc(lat(pair(i,1)),long(pair(i,1)),'forward','degrees');

		% slope of line
		slope=tan(pi/2 - deg2rad(az(pair(i,2))));
		if isinf(slope)
				intercpt=linex;
			else
				intercpt=liney-slope*linex;
		end

		% radius of circle
		range=az(pair(i,1));

		[xout,yout]=linecirc(slope,intercpt,centerx,centery,range);
		[newlat(i,:), newlong(i,:)]=merccalc(xout,yout,'inverse','degrees');

		% If intersection is in opposite direction, discount it.  This can occur because
		% rhumb lines are defined in both directions from any given point, but
		% sightings are specific to the azimuth given

		if abs(zero22pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-zero22pi(az(pair(i,2)),'degrees'))>90 && ...
			abs(npi2pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,1),newlong(i,1),'degrees'),'degrees')-npi2pi(az(pair(i,2)),'degrees'))>90
			newlat(i,1)=NaN;
			newlong(i,1)=NaN;
		end
		if abs(zero22pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,2),newlong(i,2),'degrees'),'degrees')-zero22pi(az(pair(i,2)),'degrees'))>90 && ...
			abs(npi2pi(azimuth('rh',lat(pair(i,2)),long(pair(i,2)),newlat(i,2),newlong(i,2),'degrees'),'degrees')-npi2pi(az(pair(i,2)),'degrees'))>90
			newlat(i,2)=NaN;
			newlong(i,2)=NaN;
		end

	else	% This is the casetype of two ranges

		% the centers
		[x1,y1]=merccalc(lat(pair(i,1)),long(pair(i,1)),'forward','degrees');
		[x2,y2]=merccalc(lat(pair(i,2)),long(pair(i,2)),'forward','degrees');

		% the radii
		r1=az(pair(i,1));
		r2=az(pair(i,2));

		[xout,yout]=circcirc(x1,y1,r1,x2,y2,r2);
		[newlat(i,:), newlong(i,:)]=merccalc(xout,yout,'inverse','degrees');

	end
end

% If dead reckoning position is given, resolve ambiguity where needed

if ~isempty(drlat)

	for j=1:size(pair,1)

		if	isnan(newlat(j,1)) && ~isnan(newlat(j,2))
			newlat(j,1)=newlat(j,2);
			newlong(j,1)=newlong(j,2);
		elseif ~isnan(newlat(j,1)) && ~isnan(newlat(j,2))

			%  choose the position closest to the dr point

			[x1,y1] = merccalc(newlat(j,1),newlong(j,1),'forward','degrees');
			[x2,y2] = merccalc(newlat(j,2),newlong(j,2),'forward','degrees');
			[xdr,ydr] = merccalc(drlat,drlong,'forward','degrees');
			dist1=(x1-xdr)^2+(y1-ydr)^2;
			dist2=(x2-xdr)^2+(y2-ydr)^2;

			if dist1>dist2
				newlat(j,1)=newlat(j,2);
				newlong(j,1)=newlong(j,2);
			end

		end
	end
	newlat=newlat(:,1);
	newlong=newlong(:,1);

	% Any NaN's indicate a bad pair of navigation objects;  when asking for a fix
	% (i.e., entering a dr position), one needs all objects to participate
	% in the solution or there is no fix

	if any(isnan(newlat))
		newlat=[];    newlong=[];
		warning('map:nav:noFix','No fix.')
	end
end

%  Combine output arguments if necessary
if nargout < 2
    newlat = [newlat newlong];
end
