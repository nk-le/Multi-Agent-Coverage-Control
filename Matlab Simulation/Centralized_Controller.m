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
        v                                       % Current List of Voronoi vertexes
        c                                       % Current List of Voronoi vertexes index
   
        % State variable
        agentList
        CurPose
        CurPoseVM
        CurPoseCVT
        adjacentMat
        CVTpartialDerivativeMat
        CoverageStateInfo % Some information here
        dV_Info
        CurAngularVel
        
        %% Tmp
        lastPoseVM 
        lastPoseCVT 
        LyapunovCost 
        lastV
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
            obj.CurPose = zeros(obj.nAgent, 3);
            obj.CurPoseCVT = zeros(obj.nAgent, 2);
            obj.CurPoseVM = zeros(obj.nAgent, 2);
            obj.adjacentMat = zeros(obj.nAgent, obj.nAgent);
            obj.CurAngularVel = zeros(obj.nAgent, 1);
            
            % record of last timestamp
            obj.lastPoseVM = zeros(nAgent, 3);
            obj.lastPoseCVT = zeros(nAgent, 2);
            obj.lastV = zeros(nAgent,1);
            obj.LyapunovCost = zeros(nAgent, 1);
            
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
        %       - infoOut           --> total required coverage
        %                           information, which is ...
        %                           ...
        %                           ...
        %       - LypOut            --> Current Lyapunov cost
        %       - CVTsOut           --> List of new centroids asnew target for each agent
        function [AgentReport, LypOut] = updateCoverage(obj, newPoseVM)
            % Save all the current VM
            obj.CurPoseVM = newPoseVM;          
            %% The used methods were developed by Aaron_Becker
            [obj.v,rawC]= Function_VoronoiBounded(obj.CurPoseVM(:,1), obj.CurPoseVM(:,2), obj.boundariesVertexes);
            
            %% Added a layer to outlier the duplicated vertexes
            obj.c = outlierVertexList(obj.v, rawC, [0 obj.xrange], [0 obj.yrange]);
            
            %% Compute the new setpoint for each agent
            for i = 1:obj.nAgent
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundariesVertexes(:,1), obj.boundariesVertexes(:,2))
                    obj.CurPoseCVT(i,1) = cx;  %don't update if goal is outside the polygon
                    obj.CurPoseCVT(i,2) = cy;
                end
            end
            
            %% Update the partial derivativ of each cells and construct the broadcased information matrix
            [AgentReport] = ComputeVoronoiProperty(obj.CurPoseVM, obj.CurPoseCVT, obj.v, obj.c);
            
            %% Update Lyapunov Value 
            newV = zeros(obj.nAgent, 1);
            for k = 1:obj.nAgent
                zk = obj.CurPoseVM(k,:);
                ck = obj.CurPoseCVT(k,:);
                [newV(k)] = obj.computeVLyp(zk, ck);
            end   
            obj.lastPoseVM = obj.CurPoseVM;
            obj.lastPoseCVT = obj.CurPoseCVT;
            obj.LyapunovCost = newV;
        
            %% Return the global info to be published and evaluation
            LypOut = sum(obj.LyapunovCost);
        end
        
        %% Partial dervivative of Lyapunov function
        function out_dV_struct = ComputeLyapunovDerivative(obj, Info)
            out_dV_struct(obj.nAgent) = struct();
            % CVTCoord      : CVT information of each agent
            % adjacentList  : 
            for thisAgent = 1: obj.nAgent
                %% One shot computation before scanning over the adjacent matrix
                Q = eye(2);
                Ci = obj.CurPoseCVT(thisAgent,:)';
                zi = obj.CurPoseVM(thisAgent, :)';
                sumHj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    tol = 0; % Tolerance to relax the state constraint
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1)*zi(1) + obj.boundariesCoeff(j,2)*zi(2) + tol)); 
                    sumHj = sumHj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.boundariesCoeff(j,1); obj.boundariesCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_hj = Q * (zi - Ci) / sumHj;
                 
                %% Compute the Partial dVi_dzi of itself
                dCi_dzi = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMy;
                           Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMx, Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMy];
                
                tmp = (eye(2) - dCi_dzi')*Q_zDiff_hj + sum_aj_HjSquared * (zi - Ci)' * Q * (zi - Ci);
                out_dV_struct(thisAgent).myInfo.dV_dVMx = tmp(1);
                out_dV_struct(thisAgent).myInfo.dV_dVMy = tmp(2);
                %outdV(thisAgent, thisAgent, 1) = true;   %% REMEMBER THIS
               
                %% Scan over the adjacent list and compute the corresponding partial derivative
                for friendID = 1: obj.nAgent
                    out_dV_struct(thisAgent).FriendInfo(friendID).isVoronoiNeighbor = false; % Declaration makes the output structure consistent
                    FriendInfo = Info.AgentReport(thisAgent).FriendAgentInfo(friendID);
                    isNeighbor = (friendID ~= thisAgent) && FriendInfo.isVoronoiNeighbor; 
                    if(isNeighbor)
                        dCi_dzk = [FriendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_x, FriendInfo.VoronoiInfo.partialCVT.dCx_dVMFriend_y;
                                   FriendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_x, FriendInfo.VoronoiInfo.partialCVT.dCy_dVMFriend_y];
                        dVidj = -dCi_dzk' * Q_zDiff_hj;
                        % Assign the new adjacent partial derivative
                        out_dV_struct(thisAgent).FriendInfo(friendID).isVoronoiNeighbor = true;
                        out_dV_struct(thisAgent).FriendInfo(friendID).dV_dVMFriend_x = dVidj(1);
                        out_dV_struct(thisAgent).FriendInfo(friendID).dV_dVMFriend_y = dVidj(2);
                    end
                end
            end 
        end
    
        function [Vk] = computeVLyp(obj, Zk, Ck)
            tol = 0;
            Vk = 0;
            for j = 1 : size(obj.boundariesCoeff, 1)
                Vk = Vk +  1 / (obj.boundariesCoeff(j,3) - (obj.boundariesCoeff(j,1)*Zk(1) + obj.boundariesCoeff(j,2)* Zk(2) + tol)) / 2 ;
            end
            if(Vk < 0)
                error("State constraint is violated. Check inital position of virtual centers or the control algorithm");
            end
            Vk =  (norm(Zk - Ck))^2 * Vk;
        end
        
        function [LyapunovState] = controlCentralize(obj, AgentReport)
            %% Compute the Lyapunov partial derivative according to the latest state of Agents
            LyapunovState = obj.ComputeLyapunovDerivative(AgentReport);
            
            %% Compute the control policy
            for thisAgent = 1 : obj.nAgent
                w0 = obj.agentList(thisAgent).wOrbit;
                cosTheta = cos(obj.agentList(thisAgent).curPose(3));   % agentStatus.curPose(3): Actual Orientation
                sinTheta = sin(obj.agentList(thisAgent).curPose(3));

                % Compute the Lyapunov feedback from adjacent agents
                sumdVj_diX = LyapunovState(thisAgent).myInfo.dV_dVMx;     % Note that the adjacent agent affects this agent, so the index is dVj/dVi <--> obj.CoverageStateInfo(Agent_J, Agent_I, :)
                sumdVj_diY = LyapunovState(thisAgent).myInfo.dV_dVMy;
                for friendID = 1 : obj.nAgent % Scan to see which are the adjacent agents
                    % If the considering cell affects us, add it to the gradient
                    if(LyapunovState(thisAgent).FriendInfo(friendID).isVoronoiNeighbor == true)
                        % NOTE: The index is reverse here according to the
                        % control law
                        sumdVj_diX = sumdVj_diX + LyapunovState(friendID).FriendInfo(thisAgent).dV_dVMFriend_x; % dVj_dzix
                        sumdVj_diY = sumdVj_diY + LyapunovState(friendID).FriendInfo(thisAgent).dV_dVMFriend_y; % dVj_dziy
                    end
                end      
                % Compute the control input
                epsSigmoid = 10;
                mu = 1; % Control gain %% ADJUST THE CONTROL GAIN HERE
                w = w0 + mu * w0 * (sumdVj_diX * cosTheta + sumdVj_diY * sinTheta)/(abs(sumdVj_diX * cosTheta + sumdVj_diY * sinTheta) + epsSigmoid); 
                % Send control output to each agent
                obj.CurAngularVel(thisAgent) = w;
                obj.agentList(thisAgent).setAngularVel(w);
                % disp(w);
            end
        end

        %% MAIN
        % Main loop of the simulation 
        % [@in]  --
        % [@out]:    
        %       Current pose of agents for simulation      
        %       
        %
        function [botPose, outLypCost, AgentReport, LyapunovState] = loop(obj)
            %% Update dynamic - Each agents move according to the updated control policy
            % This method should be called independent from centralized
            % controller (inside the loop), however put it here for
            % simplicity
            for i = 1:obj.nAgent
               obj.CurPose(i,:) = obj.agentList(i).move();
            end
            
            %% Update the new coordinate feedback (Virtual center) and update Voronoi partitions
            newPoseVM = zeros(obj.nAgent,2);
            for i = 1:obj.nAgent
                newPoseVM(i,:) =  obj.agentList(i).updateVirtualCenter();
            end
            
            %% Update the broadcasted information
            [AgentReport, curLypCost] = obj.updateCoverage(newPoseVM);
            
            %% Update the control policy for each agent
            LyapunovState = obj.controlCentralize(AgentReport);
            
            %% Final update for the next process
            % ...
            % disp(curLypCost)
            
            outLypCost = curLypCost;
            botPose = obj.CurPose;
        end
    end

end

