format long;
SIM_PARAM = SimulationParameter();
COVERAGE_PARAM = CoverageParameter();
REGION_CONFIG = RegionParameter();
CONTROL_PARAM = ControlParameter();

%% Some adjustable control parameter, will be moved to Simulation_Parameter later
rng(4);
startPose = REGION_CONFIG.generate_start_pose(SIM_PARAM.N_AGENT);
agentHandle = UnicycleSimpleCoverageAgent.empty(SIM_PARAM.N_AGENT, 0);

%% Agent handler
for k = 1 : SIM_PARAM.N_AGENT
    agentHandle(k) = UnicycleSimpleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), startPose(k,:), REGION_CONFIG, CONTROL_PARAM);
end

for i = 1:100
    agentHandle(1).move(0.001); 
   disp(agentHandle(1).AgentPose_3d);
end

