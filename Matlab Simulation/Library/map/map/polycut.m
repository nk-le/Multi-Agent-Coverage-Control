function [xv,yv] = polycut(xp1,yp1)
%POLYCUT  Compute branch cuts for holes in polygons
%
%   [lat2,long2] = POLYCUT(lat,long) connects the contour and holes of polygons
%   using optimal branch cuts.  Polygons are input as NaN-delimited vectors, or 
%   as cell arrays containing individual polygons in each element with the outer 
%   face separated from the subsequent inner faces by NaNs. Multiple polygons 
%   outputs are separated by NaNs. 
%
%   See also POLYSHAPE, POLYSPLIT, POLYJOIN

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  A. Kim

if isempty(xp1) & isempty(yp1)
    xv = [];
    yv = [];
    return
end

% convert inputs to cell
if ~iscell(xp1)
   [xp1,yp1]=deal({xp1},{yp1});
end

for i=1:length(xp1)
	% close open polygons
	[xp1{i},yp1{i}] = closefaces(xp1{i},yp1{i});
end


% loop through each polygon input
xv = [];  yv = [];
for n=1:length(xp1)
   
   % extract polygon types and convert to structure
	[xc,yc,xh,yh,nanindx] = extractpoly(xp1(n),yp1(n));
	polystruc(1).x = xc;  polystruc(1).y = yc;
	for m=1:length(nanindx)-1
		indx = nanindx(m)+1:nanindx(m+1)-1;
		polystruc(m+1).x = xh(indx);
		polystruc(m+1).y = yh(indx);
	end
	icont = 1;  ihole = 2:length(nanindx);

	if length(ihole)==0

		x = [];  y = [];
		for k=1:length(polystruc)
			x = [x; nan; polystruc(k).x];  y = [y; nan; polystruc(k).y];
		end
		x(1) = [];  y(1) = [];
		if all(isnan(x)) & all(isnan(y))
			x = [];  y = [];
		end

	else

%***** polygon branch cut algorithm *****
		Np = length(polystruc);  pvec = (1:Np)';

% starting with the contour polygon, find the hole polygon closet to it,
% repeat for each successive polygon
		polynum = icont;
		for k=1:Np-1
			pvec(find(pvec==polynum(k))) = [];
			x1 = polystruc(polynum(k)).x;  y1 = polystruc(polynum(k)).y;
			for m=1:length(pvec)
				x2 = polystruc(pvec(m)).x;  y2 = polystruc(pvec(m)).y;
				[i1(m),i2(m),dmin(m)] = mindist(x1,y1,x2,y2);
			end
			imin= find(dmin==min(dmin));  polynum(k+1,1) = pvec(imin(1));
			pt1(k+1,1) = i2(imin(1));  pt2(k,1) = i1(imin(1));
			clear i1 i2 dmin
		end
		pt1(1) = 1;  pt2(Np) = pt1(Np);

% record path of polygons along branch cuts
		x1 = [];  y1 = [];  x2 = [];  y2 = [];
		for k=1:Np
			poly = polynum(k);  i1 = pt1(k);  i2 = pt2(k);
			xp = polystruc(poly).x;  yp = polystruc(poly).y;
			if pt1(k)<pt2(k)
				x1 = [x1; xp(i1:i2)];			  y1 = [y1; yp(i1:i2)];
				x2 = [xp(i2:end); xp(2:i1); x2];  y2 = [yp(i2:end); yp(2:i1); y2];
			else
				x1 = [x1; xp(i1:end); xp(2:i2)];  y1 = [y1; yp(i1:end); yp(2:i2)];
				x2 = [xp(i2:i1); x2];			  y2 = [yp(i2:i1); y2];
			end
		end
		x = [x1; x2];  y = [y1; y2];

	end

	xv = [xv; x; nan];
	yv = [yv; y; nan];

	clear x y polystruc

end

xv(end) = [];  yv(end) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [i1,i2,dmin] = mindist(x1,y1,x2,y2)
%MINDIST  Minimum polygon distance points.
%   [I1,I2] = MINDIST(X1,Y1,X2,Y2) returns the indices of the closest
%   points between two polygons.
%
%   [I1,I2,DMIN] = MINDIST(X1,Y1,X2,Y2) also returns the minimum distances.

%  Written by:  A. Kim

% columnize inputs
x1 = x1(:);  y1 = y1(:);  x2 = x2(:);  y2 = y2(:);

% if self-enclosed, remove last point
if x1(1)==x1(end) & y1(1)==y1(end)
	x1 = x1(1:end-1);  y1 = y1(1:end-1);
end
if x2(1)==x2(end) & y2(1)==y2(end)
	x2 = x2(1:end-1);  y2 = y2(1:end-1);
end

% tile matrices for vectorized distance calculations
n1 = length(x1);  n2 = length(x2);
X1 = reshape(repmat(x1,1,n2)',1,n1*n2)';
Y1 = reshape(repmat(y1,1,n2)',1,n1*n2)';
I1 = reshape(repmat((1:n1)',1,n2)',1,n1*n2)';
X2 = repmat(x2,n1,1);
Y2 = repmat(y2,n1,1);
I2 = repmat((1:n2)',n1,1);

% calculate distances between points
dist = sqrt((X1-X2).^2 + (Y1-Y2).^2);
dmin = unique(min(dist));
imin = find(dist==dmin);
i1 = I1(imin(1));  i2 = I2(imin(1));

%----------------------------------------------------------------
function [xc,yc,xh,yh,nanindx] = extractpoly(xp,yp)
%EXTRACTPOLY  Extract contour and holes from polygon element.
%   [XC,YC,XH,YH,NANINDX] = EXTRACTPOLY(XP,YP) extracts the contour and
%   holes data from a polygon element.

%  Written by:  A. Kim

% convert data to matrix
if iscell(xp)
	xp = xp{1};  yp = yp{1};
end

% append a nan at the end
x = [xp; nan];  y = [yp; nan];
indx = find(isnan(x));

% contour
indxc = 1:indx(1)-1;
xc = x(indxc);  yc = y(indxc);

% holes
xh = [];  yh = [];  nanindx = [];
if length(indx)>1
	indxh = indx(1):indx(end);
	xh = x(indxh);  yh = y(indxh);
	nanindx = find(isnan(xh));
end

%----------------------------------------------------------------
function [lat,lon] = closefaces(latin,lonin)
%CLOSEFACES closes all faces of a polygon

[lat,lon]=deal(latin,lonin);

if ~iscell(lat)
   [lat,lon]=polysplit(lat,lon);      
end 
   
for i=1:length(lat)
   [latface,lonface]=deal(lat{i},lon{i});
   [latfacecell,lonfacecell]=polysplit(latface,lonface);
   for j=1:length(latfacecell)   
      % close open polygons        
      if latfacecell{j}(1) ~= latfacecell{j}(end) | lonfacecell{j}(1) ~= lonfacecell{j}(end)
         latfacecell{j}(end+1)=latfacecell{j}(1);
         lonfacecell{j}(end+1)=lonfacecell{j}(1);
      end
      
   end 
   [lat{i},lon{i}]=polyjoin(latfacecell,lonfacecell);
end

if ~iscell(latin)
   [lat,lon] = polyjoin(lat,lon);
end
