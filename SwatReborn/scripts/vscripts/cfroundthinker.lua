--require('playerstats')
shoubo={}
shouwang={}
    for i=1,30 do
	  shoubo[i]=5*i+75
	  shouwang[i]=3*i+30
    end

-------------------------------------------------------------------------------------------
if CFRoundThinker == nil then
	CFRoundThinker = class({})
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
local ROUND_STATE_PREPARE  = 0
local ROUND_STATE_FIGHTING = 1
local ROUND_STATE_REST     = 2

local ROUND_REST_TIME_BASE = 30
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:InitPara(kv)
    roundnum=1
	self._nCurrRound = 0
	self._currentState = ROUND_STATE_PREPARE
	self._nRoundRestTime = GameRules:GetGameTime() + ROUND_REST_TIME_BASE
	self._tAllEnemies = {}
	-- 读取所有的怪信息，赋给self._tAllEnemies
	self:ReadAllEnemiesFromKv()
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:Think()
	local cs = self._currentState
	--现在处于什么游戏阶段？ 游戏还没开始？ 正在一轮中？ 还是结束了？ 调用不同的函数
	if cs == ROUND_STATE_PREPARE then
		self:ThinkPrepare()
	elseif cs == ROUND_STATE_FIGHTING then
		self:ThinkFighting()
	elseif cs == ROUND_STATE_REST then
		self:ThinkRest()
	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:ThinkPrepare()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- 游戏时间变为0，就开始第一轮
		self._currentState = ROUND_STATE_FIGHTING
		self:StartNextRound()
	else
		--TODO
	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:ThinkFighting()
	-- 允许core/CFSpawner.lua 开始刷怪/检测循环
	CFSpawner:Think()

	-- 判断这一轮的怪物是否都被干掉了
	if CFSpawner:IsWaveClear() then
        	
        setherobac()        --英雄找回技能
        clearallunit()      --杀光所有兵
	    rebuildunit()       --重建所有兵
	    setunitstop()       --静止所有兵移动
        jiesuan()           --为玩家结算收入
        roundnum=roundnum+1


		-- 如果每一轮的怪物都被干掉了
		if self._nCurrRound > #self._tAllEnemies then

			-- 让主程序addon_game_mode.lua结束游戏
			legiontdGameMode:FinishedGame()
		else
			-- 如果还有下一轮，那么久
			self._currentState = ROUND_STATE_REST
			self._nRoundRestTime = GameRules:GetGameTime() + ROUND_REST_TIME_BASE

			-- 启动倒计时条
			if self._entCountDown == nil then
				self._entCountDown = SpawnEntityFromTableSynchronous( "quest", {
					name = "LegionTD RoundCountingDown",
					title =  "LegionTD Round_Next_Round_Count_Down"
				})
				self._entCountDown:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nCurrRound )

				self._entCountDownBar = SpawnEntityFromTableSynchronous( "subquest_base", {
					show_progress_bar = true,
					progress_bar_hue_shift = -119
				} )
				self._entCountDown:AddSubquest( self._entCountDownBar )
				self._entCountDownBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nRoundRestTime - GameRules:GetGameTime() )
				self._entCountDownBar:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._nRoundRestTime - GameRules:GetGameTime() )
				print('round conter started '..self._nRoundRestTime - GameRules:GetGameTime())
			end
		end

	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:ThinkRest()
	-- 休息时间结束，就开始下一轮
	if GameRules:GetGameTime() >= self._nRoundRestTime then
		self._currentState = ROUND_STATE_FIGHTING

        stopall()

		self:StartNextRound()
		UTIL_RemoveImmediate(self._entCountDown)
		self._entCountDown = nil 
	else
		print(self._nRoundRestTime - GameRules:GetGameTime())
		-- 减少倒计时条
		self._entCountDownBar:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._nRoundRestTime - GameRules:GetGameTime() )
	end
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:ReadAllEnemiesFromKv()
	local kv = LoadKeyValues( "scripts/maps/legiontd.txt" )
	
	if not kv then print('Runtime error, maybe you havent put a mapName KV file in maps/ directory') end
	for k,v in pairs(kv["wave_data"]) do

		-- 读取单位名称，刷怪间隔，数量，等级信息
		local tSingleWaveData = {}
		tSingleWaveData.wavedata = {}
		tSingleWaveData.wavedata.name = v.name
		tSingleWaveData.wavedata.interval = v.spawn_interval
		tSingleWaveData.wavedata.count = v.count
		tSingleWaveData.wavedata.level = v.level
		tSingleWaveData.wavedata.roundtitle = v.RoundTitle
		tSingleWaveData.wavedata.roundquesttitle = v.RoundQuestTitle

		-- 读取刷怪点信息
		if not v["spawner"] then
			print('ERROR: spawner not defined for unit %s in maps/cloudforged.txt')
		else
			-- 读取刷怪点名字和第一个路径点
			tSingleWaveData.spawner = {}
			for sk,sv in pairs(v["spawner"]) do
				local index = tonumber(sk)
				tSingleWaveData.spawner[index] = {}
				tSingleWaveData.spawner[index].name = sv.SpawnerEntityName
				tSingleWaveData.spawner[index].waypoint = sv.FirstPathCorner
			end
		end
		-- 存入self.tAllEnemies
		local i = tonumber(k)
		self._tAllEnemies[i] = tSingleWaveData
	end

end
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
function CFRoundThinker:ReadRoundData(round)
	return self._tAllEnemies[round]
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:StartNextRound()
	-- 轮数 + 1
	self._nCurrRound = self._nCurrRound + 1
	
	-- 读出这一轮怪的信息
	local tRoundData = self:ReadRoundData(self._nCurrRound)
	-- 调用core/CFSpawner.lua开始这一轮刷怪
	
	CFSpawner:SpawnWave(self._nCurrRound,tRoundData.wavedata,tRoundData.spawner)
	setherosil();
	setunitmove();
	
	

	
end
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function CFRoundThinker:IncreaseRestTime(duration)
	self._nRoundRestTime = self._nRoundRestTime or 0
	self._nRoundRestTime = self._nRoundRestTime + duration
	if self._entCountDownBar then
		SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nRoundRestTime - GameRules:GetGameTime() )
	end
end
-------------------------------------------------------------------------------------------


function stopall()
  for i=1,PlayerS[12],1 do
  
    if IsValidEntity( PlayerS[13][i] ) then
    
      PlayerS[13][i]:Stop()
      
    end
    
  end

   for i=0,8 do
     if (not(i==4)) and (PlayerS[i][30]==1) then

       yx[i]:Stop()
     end
   end
end



function clearallunit()

  for i=1,PlayerS[12],1 do
  
    if IsValidEntity( PlayerS[13][i] ) then
    
      PlayerS[13][i]:SetAbsOrigin(zibao)

      PlayerS[13][i]:ForceKill(true)
      
    end
    
  end

end

function rebuildunit()

 for i=1,PlayerS[12],1 do
 
 
    local temp = PlayerS[16][i]
    
    PlayerS[13][i]=CreateUnitByName(temp, PlayerS[15][i], false, PlayerS[17][i], PlayerS[17][i], PlayerS[18][i] )
    
     --todo 也许需要重复building全部过程
    
    PlayerS[13][i]:SetContext("name",tostring(i),0)
		PlayerS[13][i]:SetContext("pid",tostring(PlayerS[14][i]),0)
    
    
    PlayerS[13][i]:SetControllableByPlayer(PlayerS[14][i],true)
  end
end


function setherosil()

   for i=0,8 do
     if (not(i==4)) and (PlayerS[i][30]==1)then

       PlayerS[i][19]=0                  --清理出兵flag
       
       if yx[i] then
      
          for j = 0,15,1 do
           
            local temp1=yx[i]:GetAbilityByIndex(j) --获取技能实体
            if temp1 then  
              temp1:SetLevel(0)                     --设置技能等级
            end

          end
     
       end
     end

   end


end

function setherobac()

   for i=0,8 do
     if (not(i==4)) and (PlayerS[i][30]==1)then
       
       local j=0
      
        for j = 0,15,1 do
          local temp1=yx[i]:GetAbilityByIndex(j) --获取技能实体
          if temp1 then
            temp1:SetLevel(1)                     --设置技能等级
          end
        end
     end

   end


end

function setunitstop()
  for i=1,PlayerS[12] do
    PlayerS[13][i]:AddNewModifier(caster, nil, "modifier_rooted", nil)
  end

end

function setunitmove()

  for i=1,PlayerS[12] do
    PlayerS[13][i]:RemoveModifierByName("modifier_rooted")
    
    giveUnitDataDrivenModifier(PlayerS[13][i], PlayerS[13][i], "modifier_zhandouzhong",-1)

  end

end

function jiesuan()
   for i=0,8 do
     if (not(i==4)) and (PlayerS[i][30]==1)then
          PlayerS[i][1]=PlayerS[i][1]+shoubo[roundnum]+shouwang[roundnum]+PlayerS[i][12]
          local temp="You have gained "..shoubo[roundnum].." gold from finishing the wave; You have gained "..shouwang[roundnum].." gold from successfully defending the king; You have gained "..PlayerS[i][12].." gold from your income!"
          FireGameEvent( 'custom_error_show', { player_ID = i, _error = temp} )  
     end

   end


end







function giveUnitDataDrivenModifier(source, target, modifier,dur)
    --source and target should be hscript-units. The same unit can be in both source and target
    local item = CreateItem( "item_apply_modifiers", source, source)
    item:ApplyDataDrivenModifier( source, target, modifier, {duration=dur} )
end