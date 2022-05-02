function tf = mprojIsAzimuthal(mapprojection)
% True if the projection with the ID string corresponding to
% MAPPROJECTION is azimuthal or pseudo-azimuthal.

% Copyright 2009 The MathWorks, Inc.

tf = any(strcmp(mapprojection, {...
       'ups','stereo','ortho','breusing',...
       'eqaazim','eqdazim','gnomonic','vperspec','wiechel'}));
