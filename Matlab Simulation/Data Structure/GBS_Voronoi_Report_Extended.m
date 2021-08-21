classdef GBS_Voronoi_Report_Extended < GBS_Voronoi_Report
    properties (Access  = public)
        NAME = "GBS_Voronoi_Report_Extended"
        % dC_dz =   [dCx_dzx, dCx_dzy;
        %            dCy_dzx, dCy_dzy]
        dC_dz
        % dV_dz =   [dV_dzx, dV_dzy]'
        dV_dz
    end
    
    methods
        function obj = GBS_Voronoi_Report_Extended(myID)
            obj@GBS_Voronoi_Report(myID);
            obj.dC_dz = zeros(2,2);
            obj.dV_dz = zeros(2,1);
        end

    end
    
    methods (Access = protected)

    end
end

