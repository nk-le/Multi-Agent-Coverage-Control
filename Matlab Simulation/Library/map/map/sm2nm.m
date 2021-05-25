function nm = sm2nm(sm)
%SM2NM Convert statute to nautical miles
%
%  nm = SM2NM(sm) converts distances from statute miles to nautical miles.
%
%  See also NM2SM, SM2DEG, SM2RAD, SM2KM.

% Copyright 1996-2011 The MathWorks, Inc.

% Exact conversion factor
% 1 statute mile = 5280 statute feet, 1 statute foot = 1200/3937 meters
% 1852 meters = 1 nm
cf = 1*5280*(1200/3937)/1852;
nm = cf * sm;
