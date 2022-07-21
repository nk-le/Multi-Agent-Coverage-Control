classdef LogHandle
    %LOGSTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Log settings
        DEFAULT_MAX_SIZE = 1e4;
        nMax
        cnt = 0;
        
        % log info
        pose3
        vm2
        v
        w
        Vk
        CVT2
    end
    
    methods
        function obj = LogHandle(n)
            if (~exist('n', 'var'))
               n = obj.DEFAULT_MAX_SIZE; 
            end
            
            obj.pose3 = zeros(n,3);
            obj.v = zeros(n,1);
            obj.w = zeros(n,1);
            obj.Vk = zeros(n,1);
            obj.vm2 = zeros(n,2);
            obj.CVT2 = zeros(n,2); 
            obj.cnt = 0;
            obj.nMax = n;
        end
        
        function log(obj,p,z,c,v,w,V)
            obj.cnt = obj.cnt + 1;
            if(obj.cnt <= obj.nMax)
                obj.pose3(obj.cnt, :) = p;
                obj.vm2(obj.cnt, :) = z;
                obj.CVT2(obj.cnt, :) = c;
                obj.w(obj.cnt) = w;
                obj.v(obj.cnt) = v;
                obj.Vk(obj.cnt) = V;
            else
                fprint("Logged Memory Full!");
            end
        end
    end
end

