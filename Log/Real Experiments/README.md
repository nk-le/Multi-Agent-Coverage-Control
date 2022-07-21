## Data format 

* Raw log file: *.log

AgentID, Timestamp [ms], CoordX [mm], CoordY [mm], Theta [rad], VirtualMassX [mm], VirtualMassY [mm], CVTX [mm], CVTY [mm], W [rad/s], Vk [nounit] (Lyapunov of each agent)

The parser is provided in Log/Parser.m:		ret = [ID, Time, x, y, theta, zx, zy, Cx, Cy, w, V];
