classdef VoronoiComputer < handle
    %VORONOIINFO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID
        GeneratorCoord_2d = zeros(2,1)
        CVTCoord_2d = zeros(2,1)
        % Save the last computed result to evaluate the calculation
        prev_CVTCoord_2d
        dCkdzk
        published_dC_neighbor
        prev_dCkdzk
        prev_published_dC_neighbor
        
        rxPartialDerivativeInfo
    end
    
    methods
        function obj = VoronoiComputer(ID)
            obj.ID = ID;
        end
        
        function [CVT, dCk_dzi_For_Neighbor] = computePartialDerivativeCVT(obj, z_2d, i_received_VoronoiPartitionInfo)
             obj.GeneratorCoord_2d = z_2d;            
             obj.prev_CVTCoord_2d = obj.CVTCoord_2d;
             obj.prev_dCkdzk = obj.dCkdzk;
             format long;
             [~, Vertex2D_List, neighborInfoList] = i_received_VoronoiPartitionInfo.getValue();
             % Initally no vertex passed 
             if(~isempty(Vertex2D_List))
                 
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(Vertex2D_List);
                CVT = obj.CVTCoord_2d;
               
                nNeighbor = numel(neighborInfoList);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                mVi = Voronoi2D_calcPartitionMass(Vertex2D_List);
                dCk_dzi_For_Neighbor = Struct_Neighbor_CVT_PD.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    % Compute the partial derivative related to each
                    % adjacent agent
                    [neighborID, neighbor_vm_2d, v1_2d, v2_2d] = neighborInfoList{i}.getNeighborInfo();
                    
                    [dCk_dzk_Neighbor_i, dCk_dzi] = Voronoi2D_calCVTPartialDerivative(...
                                                        obj.GeneratorCoord_2d, ...
                                                        obj.CVTCoord_2d, ...
                                                        mVi, ... 
                                                        neighbor_vm_2d, ... 
                                                        v1_2d, ...
                                                        v2_2d);
                    % Result for an adjacent agent to be published
                    dCk_dzi_For_Neighbor(i) = Struct_Neighbor_CVT_PD(obj.ID, neighborID, ...
                                                                       obj.GeneratorCoord_2d, ...
                                                                       obj.CVTCoord_2d, ...
                                                                       dCk_dzi); %% Create a report with neighbor ID to publish             
                    % Accumulate to get the own partial derivative
                    dCk_dzk = dCk_dzk + dCk_dzk_Neighbor_i;
                end
                obj.dCkdzk = dCk_dzk;
                
                %% For debugging only
                obj.prev_published_dC_neighbor = obj.published_dC_neighbor;
                obj.published_dC_neighbor = dCk_dzi_For_Neighbor;
             else
                 fprintf("WARN: Agent %d: No vertex for region partitioning detected \n", obj.ID);
                 CVT = [];
                 dCk_dzi_For_Neighbor = [];
             end
        end
        
        
        function update_partial_derivative_info(obj, info)
            obj.rxPartialDerivativeInfo = info;
        end
    end
end

