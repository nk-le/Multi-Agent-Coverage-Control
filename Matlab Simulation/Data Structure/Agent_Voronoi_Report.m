classdef Agent_Voronoi_Report < Report_Base
    properties (Access  = private)
        % dC_dz =   [dCx_dzx, dCx_dzy;
        %            dCy_dzx, dCy_dzy]
        dC_dz
        % dV_dz =   [dV_dzx, dV_dzy]'
        dV_dz
    end
    
    methods
        function obj = Agent_Voronoi_Report(myID)
            obj@Report_Base(myID);
            obj.dC_dz = zeros(2,2);
            obj.dV_dz = zeros(2,1);
        end
        
        function assign(obj, newdCdz, newdVdz)
            assert(all(size(newdCdz) ~= [2,2]));
            assert(all(size(newdVdz) ~= [2,1]));
            
            obj.dC_dz = newdCdz;
            obj.dV_dz = newdVdz;
        end 
    end
    
    methods (Access = protected)
         function printInfo(obj)
            fprintf("dC_dz [%.4f %.4f; %.4f %.4f]. dV_dz: [%.4f %.4f] \n", ...
            obj.dC_dz(1,1), obj.dC_dz(1,2),obj.dC_dz(2,1), obj.dC_dz(2,2), obj.dV_dz(1), obj.dV_dz(2));
        end
    end
end

