function km = sm2km(sm)
%SM2KM Convert statute miles to kilometers
%
%  km = SM2KM(sm) converts distances from statute miles to kilometers.
%
%  See also KM2SM, SM2DEG, SM2RAD, SM2NM.

% Copyright 1996-2011 The MathWorks, Inc.

% Exact conversion factor
% 1 statute mile = 5280 statute feet, 1 statute foot = 1200/3937 meter, 
% 1000 meters = 1 kilometer
cf = 1*5280*1200/3937/1000;
km = cf * sm;
