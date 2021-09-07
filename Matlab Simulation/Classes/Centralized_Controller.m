%% Centralized_Controller
% Centralized controller for multiple unicycle agents, which contains a
% list of agent_controller handles to send command to unicycle
% Brief
% - The unicycle kinmematic is implmented directly in class
%  "agent_controller", which is performed by method "move()". Whenever
%  "agent_controller.move()" method is called, the unicycle simulates the next time step position
%   according to the commaned control input. 
% - Centralized_controllers update the desired control input to
%   agent_controller by calling "agent_controller.setAngularVel()"
%   The work flow of centralized_controller is described further in the
%   method "loop(obj)"

classdef Centralized_Controller < handle
    properties
        % Agents configuration
        nAgent                                 % amount of agents
        
        % Coverage region - Voronoi computation
        boundariesVertexes          
        boundariesCoeff                         % Line function of coverage region: [axj ayj bj]: axj*x + ayj*y <= b
        xrange                                  % Max range of x Axis
        yrange                                  % Max range of y Axis
   
        % State variable
        lastInfo
        currentInfo
        
        % Control Parameter
        P
        Q_2x2
        EPS_SIGMOID
    end

    methods
        %% Initialization constant variables
        function obj = Centralized_Controller(nAgent, bndCoeff, bndVertexes, Q_2x2, P, EPS_SIGMOID)
            % Default empty variables
            obj.nAgent = nAgent;
            obj.boundariesVertexes = bndVertexes;
            obj.boundariesCoeff = bndCoeff;
            obj.xrange = max(bndVertexes(:,1));
            obj.yrange = max(bndVertexes(:,2));
            obj.Q_2x2 = Q_2x2;
            obj.P = P;
            obj.EPS_SIGMOID = EPS_SIGMOID;
        end   
        
        %% Assign the parameters for each controller
        function setupControlParameter(obj, eps, gamma, Q_2x2)
            % TBD
        end
        
        %% Methods related to coverage control       
        % This method updates all neccessary states of the agents and
        % [@newPoseVM]  Current coordinates of virtual center of all agents
        % [@out]:  
        %      
        %                           information, which is ...
        %                           ...
        %                           ...
        %                   
        %       
        function [Info, poseCVT_2D, ControlInput, V_BLF_List] = updateCoverage(obj, curPose_3D, newPoseVM_2D, wOrbitList)
            format long;
            V_BLF_List = zeros(obj.nAgent, 1);
            
            % Save all the current VM   
            %% The used methods were developed by Aaron_Becker
            [v, c]= Function_VoronoiBounded(newPoseVM_2D(:,1), newPoseVM_2D(:,2), obj.boundariesVertexes);
            
            %% Added a layer to outlier the duplicated vertexes
            c = outlierVertexList(v, c, [0 obj.xrange], [0 obj.yrange]);
            
            %% Compute the new setpoint for each agent
            poseCVT_2D = zeros(obj.nAgent, 2);
            for i = 1:obj.nAgent
                [cx,cy] = Function_PolyCentroid(v(c{i},1),v(c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundariesVertexes(:,1), obj.boundariesVertexes(:,2))
                    poseCVT_2D(i,1) = cx;  %don't update if goal is outside the polygon
                    poseCVT_2D(i,2) = cy;
                end
            end
           
            %% Update the partial derivative of each cells and construct the broadcased information matrix
            Info = ComputeVoronoiProperty(newPoseVM_2D, poseCVT_2D, v, c);

            %% Update the Lyapunov state 
            for thisAgent = 1: Info.Common.nAgent
                %% One shot computation before scanning over the adjacent matrix
                Ck = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.x, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.y]';
                zk = [Info.AgentReport(thisAgent).MyInfo.Coord.x, Info.AgentReport(thisAgent).MyInfo.Coord.y]';
                sum_1_div_Hj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1)*zk(1) + obj.boundariesCoeff(j,2)*zk(2))); 
                    sum_1_div_Hj = sum_1_div_Hj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.boundariesCoeff(j,1); obj.boundariesCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_div_hj = obj.Q_2x2 * (zk - Ck) * sum_1_div_Hj;
                 
                %% Compute the Partial dVi_dzi of itself
                dCi_dzi = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMy;
                           Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMy];
                
                Vk = (zk - Ck)' * obj.Q_2x2 * (zk - Ck) * sum_1_div_Hj / 2;
                %% If Vk >= 0, the state constraint is already violated. Assert
                assert(Vk >= 0);
                V_BLF_List(thisAgent) = Vk;
                
                dVkdzk = (eye(2) - dCi_dzi')*Q_zDiff_div_hj + sum_aj_HjSquared * (zk - Ck)' * obj.Q_2x2 * (zk - Ck);
                % Assign to the Info handle
                Info.AgentReport(thisAgent).MyInfo.LyapunovState.V = Vk;
                Info.AgentReport(thisAgent).MyInfo.LyapunovState.dV_dVM.x = dVkdzk(1);
                Info.AgentReport(thisAgent).MyInfo.LyapunovState.dV_dVM.y = dVkdzk(2);
               
                %% Scan over the adjacent list and compute the corresponding partial derivative
                for friendID = 1: Info.Common.nAgent
                    FriendInfo = Info.AgentReport(thisAgent).FriendAgentInfo(friendID);
                    isNeighbor = (friendID ~= thisAgent) && FriendInfo.isVoronoiNeighbor; 
                    if(isNeighbor)
                        dCi_dzk = [FriendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_x, FriendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_y;
                                   FriendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_x, FriendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_y];
                        dVkdzi = -dCi_dzk' * Q_zDiff_div_hj;
                        % Assign the new adjacent partial derivative
                        Info.AgentReport(thisAgent).FriendAgentInfo(friendID).LyapunovState.dV_dVMFriend.x = dVkdzi(1);
                        Info.AgentReport(thisAgent).FriendAgentInfo(friendID).LyapunovState.dV_dVMFriend.y = dVkdzi(2);
                    end
                end
            end
            
            %% Compute the Lyapunov partial derivative for each agents
            for thisAgent = 1: Info.Common.nAgent
                % Initialize the Lyapunov Gradient of itself
                sumdVi_dzkx = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dV_dVM.x;     % Note that the adjacent agent affects this agent, so the index is dVj/dVi <--> obj.CoverageStateInfo(Agent_J, Agent_I, :)
                sumdVi_dzky = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dV_dVM.y;
                for friendID = 1 : Info.Common.nAgent
                    % If the considering cell affects us, add it to the
                    % gradient dV_k
                    isNeighbor = (friendID ~= thisAgent) && Info.AgentReport(thisAgent).FriendAgentInfo(friendID).isVoronoiNeighbor; 
                    if(isNeighbor)
                        % NOTE: The index is reverse here according to the control law
                        sumdVi_dzkx = sumdVi_dzkx + Info.AgentReport(friendID).FriendAgentInfo(thisAgent).LyapunovState.dV_dVMFriend.x;
                        sumdVi_dzky = sumdVi_dzky + Info.AgentReport(friendID).FriendAgentInfo(thisAgent).LyapunovState.dV_dVMFriend.y; 
                    end
                end
                Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.x = sumdVi_dzkx;
                Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.y = sumdVi_dzky;
            end
            
            %% Compute the control output
            %% Adjustable variable
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            
            %% Compute the control policy
            ControlInput = zeros(obj.nAgent, 1);
            for thisAgent = 1 : obj.nAgent
                w0 = wOrbitList(thisAgent);
                cosTheta = cos(curPose_3D(thisAgent,3));   % agentStatus.curPose(3): Actual Orientation
                sinTheta = sin(curPose_3D(thisAgent,3)); 
                dVkx = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.x;
                dVky = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.y;
                ControlInput(thisAgent) = w0 + obj.P * w0 * sigmoid_func(dVkx * cosTheta + dVky * sinTheta, obj.EPS_SIGMOID); 
                Info.AgentReport(thisAgent).MyInfo.ControlInput.w = ControlInput(thisAgent);
            end
        end
        
    end

end

