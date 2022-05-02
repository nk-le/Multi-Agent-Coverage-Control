function printMap(this)
%printMap Print MapViewer

% Copyright 1996-2013 The MathWorks, Inc.

% Construct a temporary, invisible figure. This is what will actually be
% printed.
fig = copyMap(this);

% Define a clean-up object to close it automatically -- in case of error in
% the print dialog.
clean = onCleanup(@() close(fig));

% Print the temporary figure; it will close when CLEAN goes out of scope.
printdlg(fig);
