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
   
        % Handler
        agentList
        
        % State variable
        lastInfo
        currentInfo
      
    end

    methods
        %% Initialization constant variables
        function obj = Centralized_Controller(nAgent, dt, bndCoeff, bndVertexes, initPose, vConstList, wOrbitList)
            % Default empty variables
            obj.nAgent = nAgent;
            obj.boundariesVertexes = bndVertexes;
            obj.boundariesCoeff = bndCoeff;
            obj.xrange = max(bndVertexes(:,1));
            obj.yrange = max(bndVertexes(:,2));

            % Init list of controller
            obj.agentList = Agent_Controller.empty(obj.nAgent, 0);
            for i = 1 : obj.nAgent
                botID = i;
                obj.agentList(i) = Agent_Controller(dt);
                obj.agentList(i).begin(botID, obj.boundariesCoeff, initPose(i, :), vConstList(i), wOrbitList(i));
            end
        end   
        
        %% Assign the parameters for each controller
        function setupControlParameter(obj, eps, gamma, Q)
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
        function [Info, poseCVT_2D] = updateCoverage(obj, newPoseVM_3D)
            format long;
            % Save all the current VM   
            %% The used methods were developed by Aaron_Becker
            [v, c]= Function_VoronoiBounded(newPoseVM_3D(:,1), newPoseVM_3D(:,2), obj.boundariesVertexes);
            
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
            Info = ComputeVoronoiProperty(newPoseVM_3D, poseCVT_2D, v, c);

            %% Compute the Lyapunov partial derivative according to the latest state of Agents            
            assert(isfield(Info, "Common"));
            assert(isfield(Info, "AgentReport"));
            assert(isfield(Info.AgentReport(:), "MyInfo"));
            assert(isfield(Info.AgentReport(:), "FriendAgentInfo"));
            %% Update the Lyapunov state 
            for thisAgent = 1: Info.Common.nAgent
                %% One shot computation before scanning over the adjacent matrix
                %% Some adjustable variables Parameter
                Q = eye(2);
                tol = 1; % Tolerance to relax the state constraint

                %% Computation
                Ck = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.x, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.y]';
                zk = [Info.AgentReport(thisAgent).MyInfo.Coord.x, Info.AgentReport(thisAgent).MyInfo.Coord.y]';
                sumHj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1)*zk(1) + obj.boundariesCoeff(j,2)*zk(2) + tol)); 
                    sumHj = sumHj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.boundariesCoeff(j,1); obj.boundariesCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_div_hj = Q * (zk - Ck) / sumHj;
                 
                %% Compute the Partial dVi_dzi of itself
                dCi_dzi = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMy;
                           Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMy];
                
                Vk = (zk - Ck)' * Q * (zk - Ck) / sumHj;
                dVkdzk = (eye(2) - dCi_dzi')*Q_zDiff_div_hj + sum_aj_HjSquared * (zk - Ck)' * Q * (zk - Ck);
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
        end
           
        function [Info, ControlInput] = controlCentralize(obj, Info)
            assert(isfield(Info, "Common"));
            assert(isfield(Info, "AgentReport"));
            assert(isfield(Info.AgentReport(:), "MyInfo"));
            assert(isfield(Info.AgentReport(:), "FriendAgentInfo"));
            
            %% Adjustable variable
            epsSigmoid = 2;
            mu = 1; % Control gain %% ADJUST THE CONTROL GAIN HERE
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            
            %% Compute the control policy
            ControlInput = zeros(obj.nAgent, 1);
            for thisAgent = 1 : obj.nAgent
                w0 = obj.agentList(thisAgent).wOrbit;
                cosTheta = cos(obj.agentList(thisAgent).curPose(3));   % agentStatus.curPose(3): Actual Orientation
                sinTheta = sin(obj.agentList(thisAgent).curPose(3)); 
                dVkx = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.x;
                dVky = Info.AgentReport(thisAgent).MyInfo.LyapunovState.dVk.y;
                ControlInput(thisAgent) = w0 + mu * w0 * sigmoid_func(dVkx * cosTheta + dVky * sinTheta, epsSigmoid); 
                
                % Send control output to each agent
                holdingOtherAgents = 0;
                %% This part hold another agents' movement to evaluate the compuatation of Voronoi partial derivative. Will be removed later
                if(holdingOtherAgents)
                    if(thisAgent == 1)
                        Info.AgentReport(thisAgent).MyInfo.ControlInput.w = ControlInput(thisAgent);
                        obj.agentList(thisAgent).setAngularVel(ControlInput(thisAgent));
                    else
                        w = w0;
                        Info.AgentReport(thisAgent).MyInfo.ControlInput.w = w0;
                        obj.agentList(thisAgent).setAngularVel(w0);
                        obj.agentList(thisAgent).setHeadingVel(0)
                    end
               %% Here is the normal input setup
                else 
                    Info.AgentReport(thisAgent).MyInfo.ControlInput.w = ControlInput(thisAgent);
                    % Send the control input to agent
                    obj.agentList(thisAgent).setAngularVel(ControlInput(thisAgent));
                end
                
            end
        end

        %% MAIN
        % Main loop of the simulation 
        % [@in]  --
        % [@out]:    
        %       Current pose of agents for simulation      
        %       
        %
        function [Info, BLF, loggedTopics] = loop(obj)
            %% Update dynamic - Each agents move according to the updated control policy
            % This method should be called independent from centralized
            % controller (inside the loop), however put it here for
            % simplicity
            agentPose = zeros(obj.nAgent,3);
            for i = 1:obj.nAgent
               agentPose(i, :) = obj.agentList(i).move();
            end
            
            %% Update the new coordinate feedback (Virtual center) and update Voronoi partitions
            newPoseVM = zeros(obj.nAgent,2);
            for i = 1:obj.nAgent
                newPoseVM(i,:) =  obj.agentList(i).updateVirtualCenter();
            end
            
            %% Update the broadcasted information
            [AgentReport, poseCVT_2D] = obj.updateCoverage(newPoseVM);
            
            %% Update the control policy for each agent
            [Info, ControlInput] = obj.controlCentralize(AgentReport);
            
            %% Final update for the next process
            % ...
            % disp(curLypCost)
            
            %% Save the last Info Sample before updating the control input
            
            %% Update Lyapunov Value 
            newV = zeros(obj.nAgent, 1);
            for thisAgent = 1:obj.nAgent
                [newV(thisAgent)] = Info.AgentReport(thisAgent).MyInfo.LyapunovState.V;
                if(newV(thisAgent) < 0)
                    error("State constraint is violated. Check inital position of virtual centers or the control algorithm");
                end
            end   
            BLF = sum(newV);

            %% Update the Info structure for debugging
            obj.lastInfo = obj.currentInfo;
            obj.currentInfo = Info;
            
            % Logging for post processing
            loggedTopics.CurPose = agentPose;
            loggedTopics.CurPoseVM = newPoseVM;
            loggedTopics.CurPoseCVT = poseCVT_2D;
            loggedTopics.CurAngularVel = ControlInput;
            loggedTopics.LyapunovCost = newV;

        end
    end

end

