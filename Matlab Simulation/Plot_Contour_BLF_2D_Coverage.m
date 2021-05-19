 A = [-1 , 0; 0 , -1; -1 , 1; 0.6 , 1; 0.6 , -1]; 
 b = [0, 0, 6, 15.6, 3.6];
 worldVertexes = [0, 0; 0,6; 6,12 ; 16,6 ; 6,0; 0,0];
[X,Y] = meshgrid(linspace(0,11,400));
Z = 0;
Cx = 3.5;
Cy = 3.5;

Cxu = 6;
Cyu = 6;


for i = 1:numel(b)
   tmpCheck = (b(i) - (A(i,1).*X + A(i,2).*Y) > 0);
   %Z = Z + 1/1000000 * log(tmpCheck * (b(i) - (A(i,1).*Cx + A(i,2).*Cy))./(b(i) - (A(i,1).*X + A(i,2) .*Y))).^2;
   Z = Z + ((X - Cx).^2 + (Y - Cy).^2)  .*  ((1 ./ (((A(i,1).*X + A(i,2).*Y) - b(i)))).^2); 
end

Z(Z >= 1000 | Z == --inf) = 0;
scatter(Cx,Cy,'r','LineWidth',2)
hold on; grid on;
    contour3(X,Y,Z,200,'r');%,'ShowText','on');
xlim([-1 12]);
ylim([-1 12]);
