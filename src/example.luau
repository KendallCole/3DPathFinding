local example = {}

local Pathfinding3d = require(game.ReplicatedStorage.Pathfinding3d)

local CACHED_GRAPH = nil
function getCachedGraphOrMakeNew(positionIfNotCached: Vector3)
	local GRAPH_LIFETIME = 3

	if CACHED_GRAPH then
		return CACHED_GRAPH
	end
	local graph = Pathfinding3d:CreateGraph(Vector3.new(100, 100, 100), CFrame.new(positionIfNotCached), 0.075, 1)

	print("Generating new graph...")
    CACHED_GRAPH = graph
	task.delay(GRAPH_LIFETIME, function()
		CACHED_GRAPH = nil
	end)
	return graph
end


function example:Run()
	local enemyObj = createEnemy()

	while task.wait(.1) do
		local targetPart = findNearestPlayerPrimaryPart(enemyObj.enemyModel)
		if not targetPart then
			warn("Player not found")
			continue
		end


		local distance = (targetPart.Position - enemyObj.enemyModel.Position).Magnitude

        -- 
		if not hasSomethingBetweenEnemyAndPlayer(enemyObj.enemyModel, targetPart.Parent) or distance > 100 then
			enemyObj.alignPosition.Position = targetPart.Position
        else
            local averageOfPositions = (enemyObj.enemyModel.Position + targetPart.Position) / 2
	    	local graph = getCachedGraphOrMakeNew(averageOfPositions)
            local startNode = Pathfinding3d:GetNodeNearestPartWithLineOfsite(graph, enemyObj.enemyModel)
            local endNode = Pathfinding3d:GetNodeNearestPartWithLineOfsite(graph, targetPart)
            
            if not startNode or not endNode then
                continue
            end

            local path = Pathfinding3d:FindPath(graph, startNode, endNode)
            if not path then
                warn("Could not pathfind on graph with given nodes")
    			enemyObj.alignPosition.Position = targetPart.Position
                continue
            end
            Pathfinding3d:VisualizeNodes(path, 1.5, Color3.new(0, 1, 1), 3)
            if path then
                for _, node in path do
                    local TIME_BEFORE_GIVING_UP = 3
                    local startTime = os.clock()
                    enemyObj.alignPosition.Position = node.Position
                    while os.clock()-startTime < TIME_BEFORE_GIVING_UP and (enemyObj.enemyModel.Position - node.Position).Magnitude > 2 do
                        task.wait()
                    end
                end
                print("Path complete!")
            end
		end
    end
end

function createEnemy(): { enemyModel: Part, alignPosition: AlignPosition, state: string }
	local enemy = Instance.new("Part")
	enemy.Size = Vector3.new(3, 3, 3)
	enemy.Position = Vector3.new(0, 10, 0)
	enemy.Shape = Enum.PartType.Ball
	enemy.BrickColor = BrickColor.new("Bright red")
	local attachment = Instance.new("Attachment", enemy)

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = attachment
	alignPosition.MaxForce = 10000
	alignPosition.Responsiveness = 50
	alignPosition.MaxVelocity = 8
	alignPosition.Parent = enemy

	enemy.Parent = workspace

	local object = {
		enemyModel = enemy,
		alignPosition = alignPosition,
		state = "idle",
	}
	return object, alignPosition
end

function findNearestPlayerPrimaryPart(enemy: Part): Part?
	local nearestPlayer = nil
	local minDistance = math.huge

	for _, player in game.Players:GetPlayers() do
		if player.Character and player.Character.PrimaryPart then
			local distance = (player.Character.PrimaryPart.Position - enemy.Position).Magnitude
			if distance < minDistance then
				minDistance = distance
				nearestPlayer = player
			end
		end
	end

	return nearestPlayer and nearestPlayer.Character and nearestPlayer.Character.PrimaryPart or nil
end

function hasSomethingBetweenEnemyAndPlayer(enemy: Part, playerCharacter: Model & any, raycastParams: RaycastParams)
  
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {enemy, playerCharacter} -- ignore the parts themselves

    local startPos = enemy.Position
    local endPos = playerCharacter.PrimaryPart.Position
    local directionVector = endPos - startPos

    -- Normalize direction and offset by a small amount
    local dirUnit = directionVector.Unit
    startPos = startPos + dirUnit * 0.1 -- move 0.1 studs away from enemy
    local distance = directionVector.Magnitude - 0.1 -- shrink ray length accordingly

    local raycastResult = workspace:Raycast(startPos, dirUnit * distance, params)

    if raycastResult == nil then
        print("Nothing in the way")
    end
    return not (raycastResult == nil)
end

return example