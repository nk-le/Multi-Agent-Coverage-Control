classdef Agent_Voronoi_Report_Centralized < Agent_Voronoi_Report
    properties (Access  = private)
        % dC_dz =   [dCx_dzx, dCx_dzy;
        %            dCy_dzx, dCy_dzy]
        dC_dz
        % dV_dz =   [dV_dzx, dV_dzy]'
        dV_dz
    end
    
    methods
        function obj = Agent_Voronoi_Report_Centralized(myID)
            obj@Agent_Voronoi_Report(myID);
            obj.dC_dz = zeros(2,2);
            obj.dV_dz = zeros(2,1);
        end

    end
    
    methods (Access = protected)

    end
end

