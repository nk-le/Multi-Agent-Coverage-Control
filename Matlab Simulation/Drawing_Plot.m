psi = linspace(0,2*pi,1000)';
filter = zeros(numel(psi),1);
for i = 1:numel(psi)
   filter(i) = calculateFilter(psi(i),0.4,2); 
end
orbitingRadius = 2;
k1maxup = 0.5 * ones(numel(psi),1);
k1maxlow = 4.5 * ones(numel(psi),1);
figure
grid on; hold on;plot(psi, filter, 'DisplayName','Feasible Gain');
plot(psi, -filter,'-b');
plot(psi(psi >= 3 * pi / 2), -1 * k1maxlow(psi >= 3 * pi / 2), '-r');
plot(psi(psi <= pi / 2), -1 * k1maxlow(psi <= pi / 2), '-r');
plot(psi((psi <= 3 * pi / 2) & (psi >= pi / 2)), -1 * k1maxup((psi <= 3 * pi / 2) & (psi >= pi / 2)), '-r');
xlim([0 , 2 * pi]);
ylim([-7, 0]);
xlabel("\psi_{k} (Rad)");
ylabel("Control Gain");
title("|Umax| = 2.5 (rad/s), Orbiting Radius w = -2.0(rad/s), k1max = 0.5, k2max = 4.5");

function gain = calculateFilter(psi,k1, k2)
%threshold = obj.agent.wMax - obj.w0;
if((psi <= 3 * pi / 2) && (psi >= pi / 2))
     gain = k1;           
else
     gain = k2;
end
end  