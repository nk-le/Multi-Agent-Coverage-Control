L = linspace(0,2*pi,6);
xv = cos(L);
yv = sin(L);
boundaries = [xv; yv]; 

xq = [0.5, 0];
yq = [0, 0];
[in,on] = inpolygon(xq,yq,xv,yv);

[p1, p2, result] = findVertexes(xq(1), yq(1), boundaries);

figure
plot(xv,yv) % polygon
axis equal

hold on
plot(xq(in),yq(in),'r+') % points inside
plot(xq(~in),yq(~in),'bo') % points outside
if(result == 1)
plot(p1(1), p1(2), '-x');
plot(p2(1), p2(2), '-x');
end
hold off



function [p1, p2, result] = findVertexes(posX, posY, boundaries)
    distance = zeros(1, numel(boundaries(1,:)) - 1);
    for i = 1:numel(boundaries(1,:))-1
        p1(1) = boundaries(1,i);
        p1(2) = boundaries(2,i);
        p2(1) = boundaries(1, i + 1);
        p2(2) = boundaries(2, i + 1); 

        p1Tod =  [posX, posY,0] - [p1(1), p1(2),0];
        p1Top2 = [p2(1),p2(2),0] - [p1(1), p1(2), 0];   
        
        angle = atan2(norm(cross(p1Tod,p1Top2)), dot(p1Tod,p1Top2));
        distance(i) = norm(p1Tod) * sin(angle); % Find distance 

    end  
    [value, minIndex] = min(distance(1,:));
    p1(1) = boundaries(1,minIndex);
    p1(2) = boundaries(2,minIndex);
    p2(1) = boundaries(1,minIndex + 1);
    p2(2) = boundaries(2,minIndex + 1);
    result = 1;
end

function [p1, p2, result] = findVertexes(posX, posY, boundaries)
    tol = 0.1;
    distance = zeros(1, numel(boundaries(1,:)) - 1);
    for i = 1:numel(boundaries(1,:))-1
        p1(1) = boundaries(1,i);
        p1(2) = boundaries(2,i);
        p2(1) = boundaries(1, i + 1);
        p2(2) = boundaries(2, i + 1); 
  
        xV = [p1(1), p2(1)];
        yV = [p1(2), p2(2)];
        
        coefficients = polyfit(xV, yV, 1);
        yFit = polyval(coefficients, posX);
        residualsSum = sum(abs(yFit - posY));
        
        p1Tod = [posX, posY] -p1;
        p1Top2 = p2 - p1;
        CosAngle = max(min(dot(p1Tod,p1Top2)/(norm(p1Tod)*norm(p1Top2)),1,-1));
        SinAngle = 1 - CosAngle ^ 2;
        distance(i) = norm(p1Tod) * SinAngle;% Find distance 
               
        %if residualsSum < tol
            % They're considered to be on a line
            %result = 1;
            %break; 
        %else
            %if(i == numel(boundaries(1,:)) - 1)
                %disp("No Vertexes Found");
                %p1(1) = NaN;
                %p1(2) = NaN;
                %p2(1) = NaN;
                %p2(2) = NaN;
                %result = 0;
            %end
        %end
    end  
    [value, minIndex] = min(distance);
    p1(1) = boundaries(1,minIndex);
    p1(2) = boundaries(2,minIndex);
    p2(1) = boundaries(1,minIndex + 1);
    p2(2) = boundaries(2,minIndex + 1);
end