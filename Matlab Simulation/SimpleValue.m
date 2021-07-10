classdef SimpleValue
   properties
      Value
   end
   methods
      function obj = SimpleValue(v)
         if nargin > 0
            obj.Value = v;
         end
      end
   end
end
