function z=intpoly(f,x,y)
%intpoly z=intpoly(f,x,y) integrate function f(x,y) over the polygon defined by [x,y]
%   input:
%       -f: a function handle that takes in (x,y)
%   ouput:
%       -z: the value of f integrated over the polygon
% example: 
% fill([0,1,2],[0,1,0],'b') %this is the triangle region
% f=@(x,y)exp(x+y);
% z=intpoly(f,[0,1,2],[0,1,0]) will integrate f over the
% triangle region defined by its three verteces (0,0), (1,1) and (2,0)
% ver.1.0
% By: Liutong Zhou
% 2017/3/25
if isrow(x)
    x=x';
end
if isrow(y)
    y=y';
end
% delete duplicate verterces
mypolygon=unique([x,y],'rows','stable');
x=mypolygon(:,1);
y=mypolygon(:,2);

%[x,y]=poly2cw(x,y);
[xmin,ind1]=min(x);
x=circshift(x,-(ind1-1));
y=circshift(y,-(ind1-1));
[xmax,ind2]=max(x);
if y(2) >y(end)
    up=1:ind2;
    down=[ind2:length(x),1];
else
    down=1:ind2;
    up=[ind2:length(x),1];
end
ymin=@(xx)interp1(x(down),y(down),xx) ;%regional lower bound
ymax=@(xx)interp1(x(up),y(up),xx) ;%regional  upper bound
z=integral2(f,xmin,xmax,ymin,ymax);
end
