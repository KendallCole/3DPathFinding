# Pathfinding3d
A module for creating and navigating a 3D graph.

Currently, Roblox’s built-in PathfindingService is mainly intended for ground-based agents that walk on surfaces. This module was created for situations where you have agents that arbitrarily travel in 3D such as flying agents. 

The operations are costly and exponentially scale as graphs get larger. Don't use in a hotpath. Cache/reuse paths when possible!  

![PathfindingGif](https://github.com/user-attachments/assets/e895af4a-e6f8-49fb-a773-7391cfc2c2c6)


## Basic usage:
```

local Pathfinding3d = require(game.ReplicatedStorage.Pathfinding3d)

-- Create a graph
local graph = Pathfinding3d:CreateGraph(
    Vector3.new(50, 20, 50),    -- Size
    CFrame.new(0, 10, 0),       -- Position/orientation
    1,                          -- Nodes per stud
    1,                          -- Node size scale
    nil                         -- Optional overlap params
)

-- Find nearest start and end nodes
local startNode = Pathfinding3d:GetNodeNearestVector3(graph, Vector3.new(0, 10, 0))
local endNode = Pathfinding3d:GetNodeNearestVector3(graph, Vector3.new(20, 10, 20))

-- Find path
-- Returns ordered array of nodes
local path = Pathfinding3d:FindPath(graph, startNode, endNode)

-- Visualize nodes
Pathfinding3d:VisualizeNodes(graph, 10)

```
