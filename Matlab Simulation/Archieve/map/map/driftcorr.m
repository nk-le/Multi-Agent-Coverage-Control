function [heading,groundspeed,windcorrangle] = driftcorr(course,airspeed,windfrom,windspeed)
%DRIFTCORR Heading to correct for wind or current drift
%
% heading = DRIFTCORR(course,airspeed,windfrom,windspeed) computes 
% the heading which corrects for drift due to wind (for aircraft) 
% or current (for watercraft). Course is the desired direction of
% movement (in degrees), airspeed is the speed of the vehicle relative
% to the moving air or water mass, windfrom is the direction facing 
% into the wind or current (in degrees), and windspeed is the speed 
% of the wind or current (in the same units as airspeed). 
%
% [heading,groundspeed,windcorrangle] = DRIFTCORR(...) also returns
% the groundspeed and wind correction angle. The wind correction angle 
% is positive to the right, and negative to the left.
%
% See also DRIFTVEL.

% Copyright 1996-2015 The MathWorks, Inc.

% solution of triangle with two known sides a,b and v and one opposite angle alpha
% of alpha, beta and gamma.

windang = deg2rad(windfrom-course);
speedratio = (windspeed./airspeed).*sin(windang);
speedratioC = (windspeed./airspeed).*cos(windang);
if any(speedratio >= 1 | speedratioC >= 1)
   warning('map:nav:insufficientAirspeed',...
  'Drift correction not possible: airspeed too low relative to windspeed.')
   speedratio(speedratio >= 1 | speedratioC >= 1) = NaN;
end

heading = zero22pi(rad2deg(deg2rad(course) + asin(speedratio)));
groundspeed = airspeed.*sqrt(1-speedratio.^2)-windspeed.*cos(windang);
windcorrangle = npi2pi(heading-course);
