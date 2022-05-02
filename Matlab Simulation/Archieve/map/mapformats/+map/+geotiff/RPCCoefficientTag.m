classdef RPCCoefficientTag
%RPCCoefficientTag Rational Polynomial Coefficients Tag
%
%   RPCCoefficientTag is a class utilized by the 
%   functions <a href="matlab: help geotiffinfo">geotiffinfo</a> and <a href="matlab: help geotiffwrite">geotiffwrite</a> 
%   to contain the Rational Polynomial Coefficients (RPC) TIFF tag.
%
%   The class contains properties with names and permissible values
%   corresponding to the tag elements listed in the "RPCs in GeoTIFF"
%   technical note at: http://geotiff.maptools.org/rpc_prop.html
%
%   Class Description
%   -----------------
%   map.geotiff.RPCCoefficientTag properties:
%      BiasErrorInMeters - Root mean square bias error in meters
%      RandomErrorInMeters - Root mean square random error in meters
%      LineOffset - Line offset
%      SampleOffset - Sample offset
%      GeodeticLatitudeOffset - Geodetic latitude offset
%      GeodeticLongitudeOffset - Geodetic longitude offset
%      GeodeticHeightOffset - Geodetic height offset
%      LineScale - Line scale factor
%      SampleScale - Sample scale factor
%      GeodeticLatitudeScale - Geodetic latitude scale
%      GeodeticLongitudeScale - Geodetic longitude scale
%      GeodeticHeightScale - Geodetic height scale factor
%      LineNumeratorCoefficients - Line numerator coefficients
%      LineDenominatorCoefficients - Line denominator coefficients
%      SampleNumeratorCoefficients - Sample numerator coefficients
%      SampleDenominatorCoefficients - Sample denominator coefficients
%
%   map.geotiff.RPCCoefficientTag methods:
%      RPCCoefficientTag - Constructor
%      double - Convert property values to row vector of doubles
%
%   See also geotiffinfo, geotiffwrite

% Copyright 2015 The MathWorks, Inc.

    properties
        %BiasErrorInMeters - Root mean square bias error in meters
        %
        %   BiasErrorInMeters is a scalar double indicating the root mean
        %   square bias error of all points in the image in meters per
        %   horizontal axis. Permissible value is a positive number, 0, or
        %   -1 if unknown. Default value is -1.
        BiasErrorInMeters = -1
        
        %RandomErrorInMeters - Root mean square random error in meters
        %
        %   RandomErrorInMeters is a scalar double indicating the root mean
        %   square random error of all points in the image in meters per
        %   horizontal axis. Permissible value is a positive number, 0, or
        %   -1 if unknown. Default value is -1.
        RandomErrorInMeters = -1
        
        %LineOffset - Line offset
        %
        %   LineOffset is a scalar double indicating the line offset in
        %   pixels. Permissible value is a positive number or 0. Default
        %   value is 0.
        LineOffset = 0
        
        %SampleOffset - Sample offset
        %
        %   SampleOffset is a scalar double indicating the sample offset in
        %   pixels. Permissible value is a positive number or 0. Default
        %   value is 0.
        SampleOffset = 0
        
        %GeodeticLatitudeOffset - Geodetic latitude offset
        %
        %   GeodeticLatitudeOffset is a scalar double indicating the
        %   geodetic latitude offset in degrees. Permissible value ranges
        %   from -90 <= value <= 90. Default value is 0.
        GeodeticLatitudeOffset = 0
        
        %GeodeticLongitudeOffset - Geodetic longitude offset
        %
        %   GeodeticLongitudeOffset is a scalar double indicating the
        %   geodetic longitude offset in degrees. Permissible value ranges
        %   from -180 <= value <= 180. Default value is 0.
        GeodeticLongitudeOffset = 0
        
        %GeodeticHeightOffset - Geodetic height offset
        %
        %   GeodeticHeightOffset is a scalar double indicating the geodetic
        %   height offset in meters. Default value is 0.
        GeodeticHeightOffset = 0
        
        %LineScale - Line scale factor
        %
        %   LineScale is a scalar double indicating the line scale factor
        %   in pixels. Permissible value is a positive number. Default
        %   value is 1.
        LineScale = 1
        
        %SampleScale - Sample scale factor
        %
        %   SampleScale is a scalar double indicating the sample scale
        %   factor in pixels. Permissible value is a positive number.
        %   Default value is 1.
        SampleScale = 1
        
        %GeodeticLatitudeScale - Geodetic latitude scale
        %
        %   GeodeticLatitudeScale is a scalar double indicating the
        %   geodetic latitude scale in degrees. Permissible value is a
        %   positive number <= 90. Default value is 1.
        GeodeticLatitudeScale = 1
        
        %GeodeticLongitudeScale - Geodetic longitude scale
        %
        %   GeodeticLongitudeScale is a scalar double indicating the
        %   geodetic longitude scale in degrees. Permissible value is a
        %   positive number <= 180. Default value is 1.
        GeodeticLongitudeScale = 1
        
        %GeodeticHeightScale - Geodetic height scale factor
        %
        %   GeodeticHeightScale is a scalar double indicating the geodetic
        %   height scale factor in meters. Permissible value is a positive
        %   number. Default value is 1.
        GeodeticHeightScale = 1
        
        %LineNumeratorCoefficients - Line numerator coefficients
        %
        %   LineNumeratorCoefficients is a 20 element row vector of doubles
        %   indicating the coefficients for the polynomial in the numerator
        %   of the r(n) equation.
        LineNumeratorCoefficients = zeros(1,20)
        
        %LineDenominatorCoefficients - Line denominator coefficients
        %
        %   LineDenominatorCoefficients is a 20 element row vector of
        %   doubles indicating the coefficients for the polynomial in the
        %   denominator of the r(n) equation.
        LineDenominatorCoefficients = zeros(1,20)
        
        %SampleNumeratorCoefficients - Sample numerator coefficients
        %
        %   SampleNumeratorCoefficients is a 20 element row vector of
        %   doubles indicating the coefficients for the polynomial in the
        %   numerator of the c(n) equation.
        SampleNumeratorCoefficients = zeros(1,20)
        
        %SampleDenominatorCoefficients - Sample denominator coefficients
        %
        %   SampleDenominatorCoefficients is a 20 element row vector of
        %   doubles indicating the coefficients for the polynomial in the
        %   denominator of the c(n) equation.
        SampleDenominatorCoefficients = zeros(1,20)
    end
    
    methods
        function rpctag = RPCCoefficientTag(tiffTagValue)
        %RPCCoefficientTag - Constructor
        %
        %   rpctag = map.geotiff.RPCCoefficientTag constructs a default
        %   map.geotiff.RPCCoefficientTag object.
        %
        %   rpctag = map.geotiff.RPCCoefficientTag(tiffTagValue) constructs
        %   a map.geotiff.RPCCoefficientTag object and sets the properties
        %   values to the corresponding values in the 92 element vector of
        %   doubles specified in tiffTagValue.
        %
        %   Example
        %   -------
        %   % Construct a RPCCoefficientTag object with default values.
        %   rpctag = map.geotiff.RPCCoefficientTag
        %
        %   % Set properties and construct a new RPCCoefficientTag object.
        %   rpctag.LineOffset = 1790;
        %   rpctag.SampleOffset = 2457;
        %   rpctag.LineScale = 1791;
        %   rpctag.SampleScale = 2457;
        %   rpctag.GeodeticHeightScale = 500;
        %   tiffTagValue = double(rpctag);
        %   newRpctag = map.geotiff.RPCCoefficientTag(tiffTagValue)
        
            if nargin == 1
                validateattributes(tiffTagValue,{'double'}, ...
                    {'real','vector','numel',lengthOfTagValue(rpctag)},mfilename,'tiffTagValue')
                rpctag = assignPropertiesFromTagValue(rpctag,tiffTagValue);
            end
        end
        
        %------------------------------------------------------------------
        
        function tiffTagValue = double(rpctag)
        %double - Convert property values to row vector of doubles
        %
        %   tiffTagValue = double(rpctag) returns a 92 element row vector
        %   of class double, representing the values of the TIFF tag.
        %
        %   Example
        %   -------
        %   % Construct a RPCCoefficientTag object and convert property
        %   % values to row vector suitable for use as a TIFF tag.
        %   rpctag = map.geotiff.RPCCoefficientTag
        %   tiffTagValue = double(rpctag);
        
            if isscalar(rpctag)
                tiffTagValue = zeros(1,lengthOfTagValue(rpctag));
                names = properties(rpctag);
                tagIndex = makeTagIndex(rpctag);
                for k = 1:length(names)
                    name = names{k};
                    index = tagIndex.(name);
                    tiffTagValue(index) = rpctag.(name);
                end
            elseif isempty(rpctag)
                tiffTagValue = [];
            else
                validateattributes(rpctag,{'map.geotiff.RPCCoefficientTag'}, ...
                    {'scalar'},'RPCCoefficientTag/double')
            end
        end
        
        %-------------------------- set -----------------------------------
        
        function rpctag = set.BiasErrorInMeters(rpctag, value)
            if isempty(value) || value ~= -1
                validateattributes(value,{'double'}, ...
                    {'scalar','nonnan','finite','>=',0},mfilename,'BiasErrorInMeters')
            end
            rpctag.BiasErrorInMeters = value;
        end
        
        function rpctag = set.RandomErrorInMeters(rpctag, value)
            if isempty(value) || value ~= -1
                validateattributes(value,{'double'},...
                    {'scalar','nonnan','finite','>=',0},mfilename,'RandomErrorInMeters')
            end
            rpctag.RandomErrorInMeters = value;
        end
        
        function rpctag = set.LineOffset(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>=',0},mfilename,'LineOffset')
            rpctag.LineOffset = value;
        end
        
        function rpctag = set.SampleOffset(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>=',0},mfilename,'SampleOffset')
            rpctag.SampleOffset = value;
        end
        
        function rpctag = set.GeodeticLatitudeOffset(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>=',-90,'<=',90},mfilename,'GeodeticLatitudeOffset')
            rpctag.GeodeticLatitudeOffset = value;
        end
        
        function rpctag = set.GeodeticLongitudeOffset(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>=',-180,'<=',180},mfilename,'GeodeticLongitudeOffset')
            rpctag.GeodeticLongitudeOffset = value;
        end
        
        function rpctag = set.GeodeticHeightOffset(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite'},mfilename,'GeodeticHeightOffset')
            rpctag.GeodeticHeightOffset = value;
        end
        
        function rpctag = set.LineScale(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>',0},mfilename,'LineScale')
            rpctag.LineScale = value;
        end        
        
        function rpctag = set.SampleScale (rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>',0},mfilename,'SampleScale')
            rpctag.SampleScale = value;
        end
        
        function rpctag = set.GeodeticLatitudeScale(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>',0,'<=',90},mfilename,'GeodeticLatitudeScale')
            rpctag.GeodeticLatitudeScale = value;
        end     
        
        function rpctag = set.GeodeticLongitudeScale(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>',0,'<=',180},mfilename,'GeodeticLongitudeScale ')
            rpctag.GeodeticLongitudeScale = value;
        end     
        
        function rpctag = set.GeodeticHeightScale(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'scalar','nonnan','finite','>',0},mfilename,'GeodeticHeightScale')
            rpctag.GeodeticHeightScale = value;
        end        
        
        function rpctag = set.LineNumeratorCoefficients(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'vector','nonnan','finite','numel',numel(rpctag.LineNumeratorCoefficients)}, ...
                mfilename,'LineNumeratorCoefficients')
            rpctag.LineNumeratorCoefficients = value(:)';
        end  
           
        function rpctag = set.LineDenominatorCoefficients(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'vector','nonnan','finite','numel',numel(rpctag.LineDenominatorCoefficients)}, ...
                mfilename,'LineDenominatorCoefficients')
            rpctag.LineDenominatorCoefficients = value(:)';
        end        

        function rpctag = set.SampleNumeratorCoefficients(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'vector','nonnan','finite','numel',numel(rpctag.SampleNumeratorCoefficients)}, ...
                mfilename,'SampleNumeratorCoefficients')
            rpctag.SampleNumeratorCoefficients = value(:)';
        end   
        
        function rpctag = set.SampleDenominatorCoefficients(rpctag, value)
            validateattributes(value,{'double'}, ...
                {'vector','nonnan','finite','numel',numel(rpctag.SampleDenominatorCoefficients)}, ...
                mfilename,'SampleDenominatorCoefficients')
            rpctag.SampleDenominatorCoefficients = value(:)';
        end         
    end
    
    methods (Access = 'private')  
        
        function rpctag = assignPropertiesFromTagValue(rpctag,tagValue)
        % Assign property values from the 92 element row vector tagValue.
        % Use the TagIndex property to obtain each property's value. The
        % TagIndex field names correspond to property names and the field
        % values correspond to the index in the tagValue vector for that
        % property's value.

            names = properties(rpctag);
            tagIndex = makeTagIndex(rpctag);
            for k = 1:length(names)
                name = names{k};
                index = tagIndex.(name);
                rpctag.(name) = tagValue(index);
            end
        end
        
        %------------------------------------------------------------------
        
        function tagIndex = makeTagIndex(rpctag)
        % Make a structure to relate property names to index values. The
        % structure contains field names set to the property names of the
        % class and values set to index values that relate an element of
        % the tagValue row vector to that property.
        
            % The elements of the TIFF tag value have a one-to-one
            % association with the property order of the class. All but the
            % last four are scalar and thus have a one-to-one association
            % with the index into the property names cell array.
            names = properties(rpctag);
            position = 0;
            for k = 1:numel(names)
                name = names{k};
                start = position + 1;
                position = position + numel(rpctag.(name));
                tagIndex.(name) = (start:position);
            end
        end
        
        %------------------------------------------------------------------
        
        function len = lengthOfTagValue(rpctag)
        % Compute length required for the TIFF tag value. The length is the
        % sum of the lengths of all the properties.
        
           names = properties(rpctag);
           len = 0;
           for k = 1:length(names)
               len = len + length(rpctag.(names{k}));
           end
        end
    end
end
