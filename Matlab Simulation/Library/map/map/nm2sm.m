function sm = nm2sm(nm)
%NM2SM Convert nautical to statute miles
%
%  sm = NM2SM(nm) converts distances from nautical miles to statute miles.
%
%  See also SM2NM, NM2DEG, NM2RAD, NM2KM.

% Copyright 1996-2011 The MathWorks, Inc.

% Exact conversion factor
% 1 nm = 1852 meters, 1200/3937 meters = 1 statute foot,
% 5280 statute feet = 1 statute mile
cf = 1*1852/(1200/3937)/5280;
sm = nm * cf;
