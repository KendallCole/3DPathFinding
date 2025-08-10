
local Dijkstra = {}
local Types = require(script.Parent.Types)

type Node = Types.Node

local function getSmallestDistanceNode(unvisited: {[Node]: boolean}, distances: {[Node]: number}): Node?
    local minDist = math.huge
    local minNode = nil
    for node, _ in pairs(unvisited) do
        if distances[node] and distances[node] < minDist then
            minDist = distances[node]
            minNode = node
        end
    end
    return minNode
end


function Dijkstra:Solve(nodes: {Node}, startNode: Node, endNode: Node): {Node}?
    local distances: {[Node]: number} = {}
    local previous: {[Node]: Node?} = {}
    local unvisited: {[Node]: boolean} = {}

    for _, node in nodes do
        distances[node] = math.huge
        previous[node] = nil
        unvisited[node] = true
    end
    distances[startNode] = 0

    while next(unvisited) do
        local current = getSmallestDistanceNode(unvisited, distances)
        if not current then break end
        if current == endNode then break end
        unvisited[current] = nil

        for _, neighbor in current.Neighbors do
            if unvisited[neighbor] then
                local alt = distances[current] + (current.Position - neighbor.Position).Magnitude
                if alt < distances[neighbor] then
                    distances[neighbor] = alt
                    previous[neighbor] = current
                end
            end
        end
    end

    -- Reconstruct path
    local path: {Node} = {}
    local node = endNode
    if not previous[node] and node ~= startNode then
        return nil 
    end

    while node do
        table.insert(path, 1, node)
        node = previous[node]
    end
    return path
end

return Dijkstra
