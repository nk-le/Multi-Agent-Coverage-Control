function [x,y,z] = polybool3d(flag,polygon1,polygon2)
% This function applies "polybool" to 2 polygons being located in one plane in threedimensional space through adequate projections
% The function does not check if both polygons are subsets of the same plane, this is a precondition
% polygon1 & polygon2: Enter as 3xN-Matrices. N corresponds to the number of polygon corners
% flag: select operation to be perfomed by "polybool" (https://de.mathworks.com/help/map/ref/polybool.html)
% E-mail: dimitrij.chudinzow@gmail.com
%% Check number of corners
number_corners_polygon1=size(polygon1,2);
number_corners_polygon2=size(polygon2,2);

if min(number_corners_polygon1,number_corners_polygon2)<3    
    disp('Error: both polygons must have minimum 3 corners');       
else
%%
x_axis=[1;0;0];
y_axis=[0;1;0]; 

polygon1_vector1=polygon1(:,1)-polygon1(:,2);
polygon1_vector2=polygon1(:,1)-polygon1(:,3);
polygon1_normal_vector=cross(polygon1_vector1,polygon1_vector2);

% formulating plane equation using polygon1. Since polygon1 and polygon2 are considered to be in the same plane, it doesn't make a difference which points are used
plane_a=polygon1_normal_vector(1);
plane_b=polygon1_normal_vector(2);
plane_c=polygon1_normal_vector(3);
plane_d=dot(polygon1(:,1),polygon1_normal_vector);

 % first we check whether the normal vector of polygon1 is parallel to XY-plane or XZ-plane
 crossproduct_polygon1_x_axis=cross(polygon1_normal_vector,x_axis);
 crossproduct_polygon1_y_axis=cross(polygon1_normal_vector,y_axis);
    
    if norm(crossproduct_polygon1_y_axis)==0 % polygon1 & polygon2 are parallel to XZ-plane --> set all Y-coordinates to Zero        
    polygon1_projection=zeros(size(polygon1));  
    polygon2_projection=zeros(size(polygon2)); 
    
    polygon1_projection(1,:)=polygon1(1,:);
    polygon1_projection(3,:)=polygon1(3,:);
    
    polygon2_projection(1,:)=polygon2(1,:);
    polygon2_projection(3,:)=polygon2(3,:);
    
    [x,z]=polybool(flag,polygon1_projection(1,:),polygon1_projection(3,:),polygon2_projection(1,:),polygon2_projection(3,:));
    y=(plane_d-plane_c*z-plane_a*x)/plane_b;     
                        
    elseif norm(crossproduct_polygon1_x_axis)==0 % polygon1 & polygon2 are parallel to YZ-plane --> set all X-coordinates to Zero        
    polygon1_projection=zeros(size(polygon1));  
    polygon2_projection=zeros(size(polygon2)); 
    
    polygon1_projection(2,:)=polygon1(2,:);
    polygon1_projection(3,:)=polygon1(3,:);
    
    polygon2_projection(2,:)=polygon2(2,:);
    polygon2_projection(3,:)=polygon2(3,:);
    
    [y,z]=polybool(flag,polygon1_projection(2,:),polygon1_projection(3,:),polygon2_projection(2,:),polygon2_projection(3,:));
    x=(plane_d-plane_c*z-plane_b*y)/plane_a;     
                    
    else % polygon1 & polygon2 are parallel to XY-plane or arbitralily tilted --> set all Z-coordinates to Zero        
    polygon1_projection=zeros(size(polygon1));  
    polygon2_projection=zeros(size(polygon2)); 
    
    polygon1_projection(1,:)=polygon1(1,:);
    polygon1_projection(2,:)=polygon1(2,:);
    
    polygon2_projection(1,:)=polygon2(1,:);
    polygon2_projection(2,:)=polygon2(2,:);
    
    [x,y]=polybool(flag,polygon1_projection(1,:),polygon1_projection(2,:),polygon2_projection(1,:),polygon2_projection(2,:));
    z=(plane_d-plane_a*x-plane_b*y)/plane_c;      
    end    
end

end

