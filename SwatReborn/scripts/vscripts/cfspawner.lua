--require("playerstats")
if CFSpawner == nil then
	CFSpawner = class({})
end
local DEFAULT_SPAWN_INTERVAL = 0.2
local DEFAULT_SPAWN_COUNT = 80
local DEFAULT_SPAWN_UNIT_LEVEL = 1
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--[[调用方法
	-- 在Think里面循环
	CFSpawner:Think()
	-- 调用一次便可以开始刷怪
	CFSpanwer:SpawnWave()
	-- 获取是否刷完
	CFSpawner:IsFinishedSpawn()
	-- 获取刷的怪是否全部杀死
	CFSpawner:IsWaveClear()
	-- 获取玩家杀怪数量
	CFSpawner:GetPlayerScore()
]]
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--[[	wavedata = {
			name = 单位名字, 必须
			interval = 刷怪时间间隔,可选，默认 DEFAULT_SPAWN_INTERVAL
			count = 刷怪数量,可选，默认 DEFAULT_SPAWN_COUNT
			level = 等级，可选，默认 DEFAULT_SPAWN_UNIT_LEVEL
		}
		spawner = {}
			[1] = {name = 'enemy_spawner_1',waypoint = 'way_point_1'}
			--将会随机选择刷怪点，固定一个刷怪点则只传入一个值
		}]]
function CFSpawner:SpawnWave( round , wavedata, spawner)
	if not self:CheckValid(wavedata,spawner) then tPrint(' CFSpawner data writting, data invalid') return end
	
	-- 读取刷怪信息
	self._sUnitToSpawnName = wavedata.name
	self._fSPawnInterval = wavedata.interval or DEFAULT_SPAWN_INTERVAL
	self._nUnitToSpawnCount = wavedata.count or DEFAULT_SPAWN_COUNT
	self._nCreatureLevel = wavedata.level or DEFAULT_SPAWN_UNIT_LEVEL
	self._szRoundTitle = wavedata.roundtitle or "empty"
	self._szRoundQuestTitle = wavedata.roundquesttitle or "empty"
	
	self._tSpawner = spawner


	-- 初始化变量
	self._bFinishedSpawn = false
	self._nUnitsSpawnedThisRound = 0
	self._nUnitsCurrentlyAlive = 0
	self._nCoreUnitsKilled = 0
	self._flag=0                          --刷怪完成标志   
	self._teEnemyUnitList = {}
	self._playerScore = {}

	-- 更新任务
	self._entQuest = SpawnEntityFromTableSynchronous( "quest", {
		name = self._szRoundTitle,
		title =  self._szRoundQuestTitle
	})
	
	self._entQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, round )

	self._entKillCountSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
		show_progress_bar = true,
		progress_bar_hue_shift = -119
	} )
	self._entQuest:AddSubquest( self._entKillCountSubquest )
	self._entKillCountSubquest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nUnitToSpawnCount )

	-- 监听杀怪
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CFSpawner, 'OnEntityKilled' ), self )
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 循环，如果怪物没刷完，持续刷怪
-- 在GameThink里面调用CFSpawner:Think()即可
function CFSpawner:Think()

	-- 如果怪物已经刷完，不再刷怪
	if self._flag==1 then 
	  return 
	end

	if self._flag==0 then





	  for li=1,8,1 do                                 --8个出生点
	     if li<=4 then
	       tempt=li-1
	     else
	       tempt=li
	     end
	   

	   if PlayerS[tempt][30]==1 then 
       	  

	     local _spawner = self._tSpawner[li] --第li个出生点
	     
	     local _spawnerName = _spawner.name
	     local _spawnerFirstTargetName = _spawner.waypoint
	     local _eSpawner = Entities:FindByName(nil,_spawnerName)
	     

	     
		 local _eFirstTarget = Entities:FindByName(nil,_spawnerFirstTargetName)
		   
		 local _vBaseLocation = _eSpawner:GetAbsOrigin()
		   

	     for lj=1,self._nUnitToSpawnCount,1 do        --产怪

	     	    _vSpawnLocation = _vBaseLocation + RandomVector(100)
	     	 	
	     	 	local _spawnerName = _spawner.name

		        local _eUnitSpawned 	= CreateUnitByName( self._sUnitToSpawnName, _vSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS )
		        
		        _eUnitSpawned:SetTeam(DOTA_TEAM_NEUTRALS)

		        _eUnitSpawned:SetInitialGoalEntity( _eFirstTarget )
		        
		        table.insert( self._teEnemyUnitList , _eUnitSpawned )
		        
		      	self._nUnitsSpawnedThisRound = self._nUnitsSpawnedThisRound + 1
			    self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive + 1
	     end
	     
        
         self._flag=1
       end
	  end

	  for li=1,8,1 do
         print("guyongbing")
         print(PlayerS[25])
         local _spawner = self._tSpawner[li]
         local _spawnerName = _spawner.name
	     local _spawnerFirstTargetName = _spawner.waypoint
	     local _eSpawner = Entities:FindByName(nil,_spawnerName)
	     

	     
		 local _eFirstTarget = Entities:FindByName(nil,_spawnerFirstTargetName)
		   
		 local _vBaseLocation = _eSpawner:GetAbsOrigin()


	     for lj=1,PlayerS[25],1 do                   --产雇佣兵
	       _vSpawnLocation = _vBaseLocation + RandomVector(100)
	       print("csd")
	       print(PlayerS[27][lj])
	       if PlayerS[27][lj]==li then  
	         print("zzz")
	         print(lj)
	         local _spawnerName=PlayerS[28][lj] 
             print(_spawnerName)
		     local _eUnitSpawned = CreateUnitByName( _spawnerName, _vSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS )
		        
		      _eUnitSpawned:SetTeam(DOTA_TEAM_NEUTRALS)
		      _eUnitSpawned:SetInitialGoalEntity( _eFirstTarget )
		      
              table.insert( self._teEnemyUnitList , _eUnitSpawned )
		        
		      self._nUnitsSpawnedThisRound = self._nUnitsSpawnedThisRound + 1
			  self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive + 1

		      PlayerS[26][lj]:SetAbsOrigin(zibao)
		      PlayerS[26][lj]:ForceKill(true)	     


		      PlayerS[25]=PlayerS[25]-1
		   end
		 end  

      end
	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 监听的怪物被杀死的事件响应
function CFSpawner:OnEntityKilled(keys)
	-- 获取被杀死的单位
	local killedUnit = EntIndexToHScript( keys.entindex_killed )

    if killedUnit==wang_1 then
    	GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
    end
    
    if killedUnit==wang_2 then
    	GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
    end



	if killedUnit then
		-- 如果被杀死的单位是刷出来的单位，则移除
		for i, unit in pairs( self._teEnemyUnitList ) do
			if killedUnit == unit then
				table.remove( self._teEnemyUnitList, i )
				self._nCoreUnitsKilled = self._nCoreUnitsKilled + 1
				-- 活着的怪数量 - 1
				self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive - 1
				self._entKillCountSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._nCoreUnitsKilled )
				break
			end
		end
		self._bFinishedSpawn=true;
	end

	
	
	-- 增加杀敌玩家金钱 军功
	local attackerUnit = EntIndexToHScript( keys.entindex_attacker or -1 )
	
	local playerID = tonumber(attackerUnit:GetContext("pid"))
	
	if playerID then
		
		

		--增加金币
		PlayerS[playerID][1]=PlayerS[playerID][1]+1
		--更新ui
		sendinfotoui()
		
		--todo
		
	end
	
  if playerID then
	if PlayerS[playerID][19]==0 then --检查兵种移动flag
		
	  


	  PlayerS[playerID][19]=1
	  
	  --将此玩家所有兵种a向出兵点
	  
	  for i=1,PlayerS[12],1 do

        local pid = PlayerS[14][i]
        
        if pid==playerID then
        
          if (IsValidEntity(PlayerS[13][i])) then
          
            if pid<4 then
              tt=pid+1
            else
              tt=pid
            end
             
          
            local mubiao = Entities:FindByName(nil,"CFSpawner_"..tostring(tt)) --出怪点
          
            local zuobiao = mubiao:GetAbsOrigin() --出怪点坐标
          
            local newOrder = {
          
   	      	      UnitIndex = PlayerS[13][i]:entindex(),       --兵的index       
 	  	          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,    --a到出怪点
 		          TargetIndex = nil,                   
 		          AbilityIndex = 0,                             
 		          Position = zuobiao,                          --a向出怪点
 		          Queue = 0                                    --Optional.  Used for queueing up abilities
 	          }
          
            ExecuteOrderFromTable(newOrder)
          end
             
        end
      
      end
	  
	end
  end
	
end
-------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------
-- 返回刷怪是否完成
function CFSpawner:IsFinishedSpawn()
	return self._bFinishedSpawn
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 返回是否所有怪已经都被杀死
function CFSpawner:IsWaveClear()
  --print(self._nUnitsCurrentlyAlive)
  --print(self._bFinishedSpawn)
	if self._bFinishedSpawn and self._nUnitsCurrentlyAlive == 0 then
		self:FinishRound()
		return true
	end
	return false
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 删除这一轮的任务
function CFSpawner:FinishRound()
	if self._entQuest then
		UTIL_Remove(self._entQuest)
		self._entQuest = nil
	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 返回玩家得分
function CFSpawner:GetPlayerScore()
	return self._playerScore
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
-- 检验传入参数是否合法
function CFSpawner:CheckValid(wavedata,spawner)
	if not wavedata.name then return false end
	if not spawner then return false end
	if not spawner[1].name then return false end
	if not spawner[1].waypoint then return false end
	return true
end