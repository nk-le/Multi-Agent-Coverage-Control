function [Z,refvec] = etopo5(varargin) %#ok<STOUT>
%ETOPO5 Read global 5-min digital terrain data
%
%     ETOPO5 is has been removed. Use READGEORASTER instead. The ETOPO5
%     model (5-minute gridded elevation data) has been superseded by the
%     ETOPO1 model (1-minute gridded elevation data). Read ETOPO1 using
%     READGEORASTER. If necessary, reduce the resolution using GEORESIZE.
%
%  [Z, REFVEC] = ETOPO5 reads the topography data for the entire world for
%  the data in the current directory. The current directory is searched
%  first for ETOPO2 binary data, followed by ETOPO5 binary data, followed
%  by ETOPO5 ASCII data from the file names etopo5.northern.bat and
%  etopo5.southern.bat. Once a match is found the data is read. The data
%  grid, Z, is returned as an array of elevations. Data values are in whole
%  meters, representing the elevation of the center of each cell.  REFVEC
%  is the associated referencing vector.
%
%  [Z, REFVEC] = ETOPO5(SAMPLEFACTOR) reads the data for the entire world,
%  downsampling the data by SAMPLEFACTOR.  SAMPLEFACTOR is a scalar
%  integer, which when equal to 1 gives the data at its full resolution
%  (1080 by 4320 values).  When SAMPLEFACTOR is an integer n greater than
%  one, every n-th point is returned.  SAMPLEFACTOR must divide evenly into
%  the number of rows and columns of the data file.  If SAMPLEFACTOR is
%  omitted or empty, it defaults to 1. 
%
%  [Z, REFVEC] = ETOPO5(SAMPLEFACTOR, LATLIM, LONLIM) reads the data for
%  the part of the world within the specified latitude and longitude
%  limits. The limits of the desired data are specified as two element
%  vectors of latitude, LATLIM, and longitude, LONLIM, in degrees. The
%  elements of LATLIM and LONLIM must be in ascending order.  If LATLIM is
%  empty the latitude limits are [-90 90]. LONLIM must be specified in the
%  range [0 360]. If LONLIM is empty, the longitude limits are [0 360].
%
%  [Z, REFVEC] = ETOPO5(DIRECTORY, ...) allows the path for the data file
%  to be specified by DIRECTORY rather than the current directory. 
%
%  [Z, REFVEC] = ETOPO5(FILE, ...) reads the data from FILE, where FILE is
%  a string or a cell array of strings containing the name or names of the
%  data files. 
%
%  See also GEORESIZE, READGEORASTER

%  Copyright 1996-2021 The MathWorks, Inc.

error(message('map:removed:function', upper(mfilename), 'ETOPO'));
