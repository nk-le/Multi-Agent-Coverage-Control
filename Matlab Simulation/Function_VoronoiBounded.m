function [V,C]= Function_VoronoiBounded(x,y, crs)
% VORONOIBOUNDED computes the Voronoi cells about the points (x,y) inside
% the bounding box (a polygon) crs.  If crs is not supplied, an
% axis-aligned box containing (x,y) is used.
% !!!   Voronoi bounded ko loai bo Infinity !!!

bnd=[min(x) max(x) min(y) max(y)]; %data bounds
if nargin < 3
    crs=double([bnd(1) bnd(4);bnd(2) bnd(4);bnd(2) bnd(3);bnd(1) bnd(3);bnd(1) bnd(4)]);
end

rgx = max(crs(:,1))-min(crs(:,1));
rgy = max(crs(:,2))-min(crs(:,2));
rg = max(rgx,rgy);
midx = (max(crs(:,1))+min(crs(:,1)))/2;
midy = (max(crs(:,2))+min(crs(:,2)))/2;

% add 4 additional edges
xA = [x; midx + [0;0;-5*rg;+5*rg]];
yA = [y; midy + [-5*rg;+5*rg;0;0]];

[vi,ci]=voronoin([xA,yA]);

% remove the last 4 cells
C = ci(1:end-4);
V = vi;
% use Polybool to crop the cells
% Polybool for restriction of polygons to domain.

for ij=1:length(C)
        % thanks to http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
        % first convert the contour coordinate to clockwise order:
        [X2, Y2] = poly2cw(V(C{ij},1),V(C{ij},2));
        [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),X2,Y2);
        ix=nan(1,length(xb));
        for il=1:length(xb)
            if any(V(:,1)==xb(il)) && any(V(:,2)==yb(il))
                ix1=find(V(:,1)==xb(il));
                ix2=find(V(:,2)==yb(il));
                for ib=1:length(ix1)
                    if any(ix1(ib)==ix2)
                        ix(il)=ix1(ib);
                    end
                end
                if isnan(ix(il))==1
                    lv=length(V);
                    V(lv+1,1)=xb(il);
                    V(lv+1,2)=yb(il);
                    ix(il)=lv+1;
                end
            else
                lv=length(V);
                V(lv+1,1)=xb(il);
                V(lv+1,2)=yb(il);
                ix(il)=lv+1;
            end
        end
        C{ij}=ix;
   
end