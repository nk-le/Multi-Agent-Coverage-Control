function sm = km2sm(km)
%KM2SM Convert kilometers to statute miles
%
%  sm = KM2SM(km) converts distances from kilometers to statute miles.
%
%  See also SM2KM, KM2DEG, KM2RAD, KM2NM.

% Copyright 1996-2011 The MathWorks, Inc.

% Exact conversion factor
% 1 kilometer = 1000 meters, 1200/3937 meters = 1 statue foot,
% 5280 statute feet = 1 statue mile
cf = 1*1000/(1200/3937)/5280;
sm = cf * km;
