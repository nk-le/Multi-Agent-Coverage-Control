function faces = setfaces(x,y)
%SETFACES  Construct face matrix for patch from vertex data
%
%  faces = SETFACES(x,y) will construct the face matrix for a patch,
%  given input vertex data.  The input vertex data are two column
%  vectors, with NaNs separating multiple faces of the patch.  If no
%  NaNs are found, then the face of the patch is defined by all
%  the vertices in the input vector data.  The face matrix and
%  vertex vectors are used to set the Face and Vertices properties
%  of the patch in PATCHM, PATCHESM, PROJECT and SETM.

% Copyright 1996-2006 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

% Ensure that the input data is in column format.
x = x(:);
y = y(:);

% If all vertices are NaNs, the patch has been trimmed
% and will not be displayed.
allNaNs = all(isnan(x) | isnan(y));

%  Find the individual faces to this patch (Separated by NaNs)
%  Then construct the face matrix.  The face matrix is pre-allocated
%  to the maximum size possible.  In trimmed data sets, some NaNs
%  will be neighboring each other (sequential entries in the vector
%  data) and these NaNs will not produce faces.  These rows of
%  the face matrix will need to be eliminated after construction.
%  (This approach was easier than trying to pre-compute the location
%  of the neighboring NaNs and then keeping all the subsequent
%  bookkeeping straight.  EVB).

indx = find(isnan(x) | isnan(y));
oneFace = isempty(indx);

if oneFace || allNaNs
    faces = 1:length(x);
else
    % Preallocate memory and initialize to NaN.
    faces = NaN + zeros(length(indx), max([diff(indx,[],1)-1;indx(1)]));
    
    % Process each face.
    for i = 1:length(indx)
        if i == 1
            startloc = 1;
        else
            startloc = indx(i-1)+1;
        end
        endloc = indx(i)-1;

        % Indices will be empty if NaNs are neighboring in the vector
        % data.
        indices = startloc:endloc;

        % Neighboring NaNs happen in trimmed data sets.
        if ~isempty(indices)
            faces(i,1:length(indices)) = indices;
        end
    end
end
