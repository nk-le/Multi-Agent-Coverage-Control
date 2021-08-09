# Optimal Constrained Control of a Multi-Unicycle System
Folder Structure:


# Execute
1) Setup the simulation environment by editting Config.m file
2) Run the main.m function
/// Explaination of main.m
object "simulator" carries the information of agents, which is able to:
	- Simulate the moving behaviour of agents, which return the robots' coordinate
	- Compute the Voronoi property according to the simulated coordinate
	- Send control commands to each agent
All of the above steps are called inside method loop() of the simulator (class Centralized_Controller.m)





 

