a = [-1 1];
b = [0 10];

%z1 = linspace(0.1,10-0.1,500);
%z2 = linspace(0.1,10-0.1,500);
[z1,z2] = meshgrid(linspace(0.01,10-0.01,100));

%z2 = 8 * ones(1, numel(z1));
%V = zeros(1, numel(z1));
%for i = 1:numel(b)
%   tmpCheck = (b(i) - (a(i).*x) > 0);
%   V = V + 10 * log(tmpCheck * ())./(b(i) - (A(i,1).*X + A(i,2) .*Y))).^2;
%end

V = (log((z1 + z2)/4 ./z1)).^2 + (log((10 - (z1 + z2)/4) ./ (10-z1))).^2;
V(V >= 800) = 0;
%plot(z1,V)
contour3(z1,z2,V,500);
hold on; grid on;
zlim([0 40]);