classdef (Abstract) CoverageAgentBase < handle
    %COVERAGEAGENTBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %% Obtained Voronoi partitions from the centralized Voronoi computer (Simulation)
        received_VoronoiPartitionInfo
        prev_received_VoronoiPartitionInfo
        
    end
    
    methods
        function obj = CoverageAgentBase()
        end
        
        function update_voronoi(obj)
            
        end
        
        function [CVT, dCk_dzi_For_Neighbor] = computePartialDerivativeCVT(obj, i_received_VoronoiPartitionInfo)
            assert(isa(i_received_VoronoiPartitionInfo, 'Struct_Voronoi_Partition_Info'));  
            [assignedID, ~, ~] = i_received_VoronoiPartitionInfo.getValue();
            assert(assignedID == obj.get_id());
            obj.received_VoronoiPartitionInfo = i_received_VoronoiPartitionInfo;
            z_2d = obj.get_voronoi_generator_2();
            [CVT, dCk_dzi_For_Neighbor] = obj.voronoiComputer.computePartialDerivativeCVT(z_2d, i_received_VoronoiPartitionInfo);
        end
        
        
    end
    
    methods (Abstract)
       z = get_voronoi_generator_2(obj)
       id = get_id(obj)
    end
    
    
end

