local Pathfinding3d = {}


local Dijkstra = require(script.Dijkstra)
local Types = require(script.Types) 
Pathfinding3d.Types = Types


local function hasSomethingBlocking(start: Vector3, endPos: Vector3, overlapParams: OverlapParams?)
    local raycast = workspace:Raycast(
        start,
        (endPos - start).Unit * (start - endPos).Magnitude,
        overlapParams
    )
    return raycast ~= nil
end

function Pathfinding3d:GetNodeNearestPartWithLineOfsite(
    graph: {Types.Node}, part: BasePart
    ): Types.Node?
    local nearestNode = nil
    local minDistance = math.huge

    for _, node in graph do
        local distance = (node.Position - part.Position).Magnitude
        local overlapParams = RaycastParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {part.Parent}
        if distance < minDistance and not hasSomethingBlocking(node.Position, part.Position, overlapParams) then
            minDistance = distance
            nearestNode = node
        end
    end

    return nearestNode
end
function Pathfinding3d:GetNodeNearestVector3(
    graph: {Types.Node}, position: Vector3
    ): Types.Node?

    local nearestNode = nil
    local minDistance = math.huge

    for _, node in graph do
        local distance = (node.Position - position).Magnitude
        if distance < minDistance then
            minDistance = distance
            nearestNode = node
        end
    end

    return nearestNode
end

function Pathfinding3d:FindPath(graph: {Types.Node}, startNode: Types.Node, endNode: Types.Node): {Types.Node}?
    if graph == nil or #graph == 0 then
        warn("Graph is empty or nil")
        return nil
    end
    return Dijkstra:Solve(graph, startNode, endNode)
end

function Pathfinding3d:CreateGraph(
    size: Vector3, cFrame: CFrame,
    nodesPerStud: number,
    nodesSize: number,
    overlapParams: OverlapParams?    
    ): {Types.Node}

    local nodes: {Types.Node} = {}
    local grid = {}
    local HALF_STUD = 0.5
    local xCount = math.floor(size.X * nodesPerStud)
    local yCount = math.floor(size.Y * nodesPerStud)
    local zCount = math.floor(size.Z * nodesPerStud)

    -- Create nodes, store in 3d array for lookup stuff later
    local gridOffset = Vector3.new(
        size.X / 2,
        size.Y / 2,
        size.Z / 2
    )

    for i = 1, xCount do
        grid[i] = {}
        for j = 1, yCount do
            grid[i][j] = {}
            for k = 1, zCount do
                local localPos = Vector3.new(
                    (i - HALF_STUD) / nodesPerStud,
                    (j - HALF_STUD) / nodesPerStud,
                    (k - HALF_STUD) / nodesPerStud
                ) - gridOffset

                local position = cFrame:PointToWorldSpace(localPos)

                local partsBlocking = workspace:GetPartBoundsInRadius(position, nodesSize, overlapParams)
                if partsBlocking and #partsBlocking >= 1 then 
                    continue
                end

                local node = {
                    Position = position,
                    CFrame = CFrame.new(position),
                    Size = nodesSize,
                    Neighbors = {},
                    _i = i, _j = j, _k = k, -- for neighbor lookup (optional, can remove later)
                }
                grid[i][j][k] = node
                table.insert(nodes, node)
            end
        end
    end

    -- Maybe we should ignore corners at some point? We can change this if we like...
    local directions = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            for dz = -1, 1 do
                if not (dx == 0 and dy == 0 and dz == 0) then
                    table.insert(directions, {dx, dy, dz})
                end
            end
        end
    end

    -- Assign neighbors / edges. No weights for now  
    for i = 1, xCount do
        for j = 1, yCount do
            for k = 1, zCount do
                local node = grid[i][j][k]
                if node == nil then
                    continue
                end

                for _, dir in directions do
                    local ni, nj, nk = i + dir[1], j + dir[2], k + dir[3]
                    if grid[ni] and grid[ni][nj] and grid[ni][nj][nk] then
                        local neighborNode = grid[ni][nj][nk]
                        
                        --Just dont add it to the neighbors for now if somethings blocking it
                        if hasSomethingBlocking(node.Position, neighborNode.Position, overlapParams) then
                            continue
                        end

                        table.insert(node.Neighbors, neighborNode)
                    end
                end
            end
        end
    end

    return nodes
end


function Pathfinding3d:VisualizeNodes(grid: {Types.Node}, lifetime: number?, partProperties: {[string]: any}?): ({[Types.Node]: Part}, Model)
    local nodeToPartMap = {}
   
    

    local model = Instance.new("Model")
    model.Parent = workspace
    model.Name = "NodeVisualizer"

    for _, node in grid do
        
     
        local part = Instance.new("Part")
        part.Size = Vector3.new(1,1,1) * node.Size 
        part.Position = node.Position
        part.Anchored = true
        part.CanCollide = false
        part.Color = Color3.new(0, 1, 0)
        part.Parent = model
        nodeToPartMap[node] = part

        if partProperties then
            for key, val in partProperties do
                part[key] = val
            end
        end
        if lifetime ~= nil then
            task.delay(lifetime, function()
                if model and model:IsDescendantOf(workspace) then
                    model:Destroy()
                end                
            end)
        end
        -- @DEBUG way to also check a node's neigbors... 
        -- for _, neighbor in node.Neighbors do

        --     local neighborPart = nodeToPartMap[neighbor]
        --     if neighborPart then
        --         neighborPart.BrickColor = BrickColor.Black()
        --     end
        -- end
    end
    return nodeToPartMap, model
end



return Pathfinding3d