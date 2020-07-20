maxX = 10;
curX = 2;

x = linspace(0.01, maxX-0.01, 1000);

b = [0, maxX];

Cx = 3.0;
Cxu = 8.5;
Cxl = 4.0;

V = zeros(1,numel(x));
Vu = zeros(1,numel(x));
Vl = zeros(1,numel(x));

for i = 1:numel(b)
    V(x > 0 & x < maxX) = V(x > 0 & x < maxX) + 8 * (log((b(i)-Cx)./(b(i)-x(x > 0 & x < maxX)))).^2;
    V(x <= 0 & x >= maxX)= 0;
    Vl(x > 0 & x < maxX) = Vl(x > 0 & x < maxX) + 8 *(log((b(i)-Cxl)./(b(i)-x(x > 0 & x < maxX)))).^2;
    Vl(x <= 0 & x >= maxX)= 0;
    Vu(x > 0 & x < maxX) = Vu(x > 0 & x < maxX) + 8 *(log((b(i)-Cxu)./(b(i)-x(x > 0 & x < maxX)))).^2;
    Vu(x <= 0 & x >= maxX)= 0;
end

plot(x,V,'-g','LineWidth', 1);
hold on; grid on;

%plot(x,Vl,'-b','LineWidth', 1);
%plot(x,Vu,'-y','LineWidth', 1);

%legend("V_k(x_k,C(x_k,x_l))");

%scatter(x(100), V(100),'b','LineWidth', 2);

%{
scatter(x(100), Vl(100),'r','LineWidth', 2);
scatter(x(100), Vu(100),'y','LineWidth', 2);

scatter(x(120), V(120),'b','LineWidth', 2);
scatter(x(120), Vl(120),'r','LineWidth', 2);
scatter(x(120), Vu(120),'y','LineWidth', 2);

scatter(Cx,0,[],'b','LineWidth', 2);
scatter(Cxl,0,[],'r','LineWidth', 2);
scatter(Cxu,0,[],'y','LineWidth', 2);
%}
%plot(4,0,'-x','LineWidth', 2);

%legend("V_k","z_k(t_0)","C_k(t_0)");
title("V_k(Z)");
xlabel("z_k");
ylabel("V_k(Z)");
xlim([min(x)-0.5 max(x)+ 0.5]);
ylim([-1 40]);
