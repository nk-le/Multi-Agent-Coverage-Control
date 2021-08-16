function Print_Voronoi_Info(InfoStruct, AgentID)  
    thisAgentInfo = InfoStruct.AgentReport(AgentID).MyInfo;

    fprintf("\n INFO Agent %d ***********************\n", AgentID);
    fprintf("Coord: [%.8f %.8f] \n", thisAgentInfo.Coord.x, thisAgentInfo.Coord.y);
    fprintf("CVT: [%.8f %.8f] \n", thisAgentInfo.VoronoiInfo.CVTCoord.x, thisAgentInfo.VoronoiInfo.CVTCoord.y);
    fprintf("PartialCVT dC%d_dVM%d: [%.8f %.8f ; %.8f %.8f] \n", AgentID, AgentID, thisAgentInfo.VoronoiInfo.partialCVT.dCx_dVMx, thisAgentInfo.VoronoiInfo.partialCVT.dCx_dVMy, thisAgentInfo.VoronoiInfo.partialCVT.dCy_dVMx, thisAgentInfo.VoronoiInfo.partialCVT.dCy_dVMy);
    fprintf("=== Neighbor Info === \n");
    
    for friendID = 1:InfoStruct.Common.nAgent
        friendInfo = InfoStruct.AgentReport(AgentID).FriendAgentInfo(friendID);
        if(friendInfo.isVoronoiNeighbor)
            fprintf("Friend ID: %d \n", friendID);
            fprintf("Coord: [%.8f %.8f]\n", friendInfo.Coord.x, friendInfo.Coord.y);
            fprintf("CVT: [%.8f %.8f] \n" , friendInfo.VoronoiInfo.CVTCoord.x, friendInfo.VoronoiInfo.CVTCoord.y);
            fprintf("Common Vertexex: V1 [%.8f %.8f] V2 [%.8f %.8f]\n", friendInfo.VoronoiInfo.CommonVertex.Vertex1.x, friendInfo.VoronoiInfo.CommonVertex.Vertex1.y, friendInfo.VoronoiInfo.CommonVertex.Vertex2.x, friendInfo.VoronoiInfo.CommonVertex.Vertex2.y);
            fprintf("PartialCVT dC%d_dVM%d: [%.8f %.8f ; %.8f %.8f] \n",AgentID, friendID, friendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_x, friendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_y, friendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_x, friendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_y);
            fprintf("\n")
        end
    end
    
    fprintf("END *********************************\n")
end

