format long;
SIM_PARAM = SimulationParameter();
COVERAGE_PARAM = CoverageParameter();
REGION_CONFIG = RegionParameter(3);
CONTROL_PARAM = ControlParameter();

%% Some adjustable control parameter, will be moved to Simulation_Parameter later
rng(4);
startPose = REGION_CONFIG.generate_start_pose(SIM_PARAM.N_AGENT);
agentHandle = AgentController.empty(SIM_PARAM.N_AGENT, 0);

%% Agent handler
for k = 1 : SIM_PARAM.N_AGENT
    agentHandle(k) = AgentController(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), startPose(k,:), REGION_CONFIG, CONTROL_PARAM);
end

tmp = FixedWingBase(CONTROL_PARAM, startPose(1,:));
for i = 1:100
   tmp.move(40, 0.1); 
   disp(tmp.AgentPose_3d);
end

agentHandle(1).move(0,1);