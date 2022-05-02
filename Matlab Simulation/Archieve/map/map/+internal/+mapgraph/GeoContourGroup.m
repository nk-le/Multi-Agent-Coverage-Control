%GeoContourGroup Stub class for opening a figure from R2013b or earlier
%
%   FOR INTERNAL USE ONLY -- This class is intentionally undocumented and
%   is intended for use only within other toolbox classes and functions.
%   Its behavior may change, or the class itself may be removed in a future
%   release.
%
%   GeoContourGroup methods:
%      constructor - A private constructor ensures that instances of this
%                    class cannot be constructed.
%      loadobj - Forwards its input to the loadobj method of the
%                internal.mapgraph.GeographicContourGroup class.

% Copyright 2013 The MathWorks, Inc.

classdef GeoContourGroup
    
    methods (Static, Hidden)
        
        function h = loadobj(S)
            % Construct an instance of the geographic contour class
            % added in R2014a.
            h = internal.mapgraph.GeographicContourGroup.loadobj(S);
        end
        
    end
    
    methods (Access = private)
        function h = GeoContourGroup(varargin)
            % Disable the internal.mapgraph.GeoContourGroup constructor by
            % declaring it private.
        end
    end
end
