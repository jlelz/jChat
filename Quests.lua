local _,Library = ...

local ADDON = LibStub( 'AceAddon-3.0' ):GetAddon( 'jChat' )
local DB = ADDON:GetModule( 'database' )
local QUESTS = ADDON:NewModule( 'quests','AceEvent-3.0' )

local C_QuestLog = C_QuestLog
local GetQuestLogTitle = GetQuestLogTitle

--
--  Rebuild Quest Watch
--
--  @return void
function QUESTS:RebuildQuests()
    self.ActiveQuests = {}
    local NumEntries,NumQuests
    if( C_QuestLog and C_QuestLog.GetNumQuestLogEntries ) then
        NumEntries,NumQuests = C_QuestLog.GetNumQuestLogEntries()
    else
        NumEntries,NumQuests = GetNumQuestLogEntries()
    end
    local QuestTitle
    for i=1, NumEntries do
        if( C_QuestLog and C_QuestLog.GetTitleForQuestID ) then
            QuestTitle = C_QuestLog.GetTitleForQuestID( i )
        else
            QuestTitle,_,_,IsHeader = GetQuestLogTitle( i )
        end
        if( QuestTitle ) then
            self.ActiveQuests[ Library:Minify( QuestTitle ) ] = Library:Minify( QuestTitle )
        end
    end
end

--
--  Accept Quest
--
--  @param  list
--  @return void
function QUESTS:QUEST_ACCEPTED( Event,... )
	local QuestId = tonumber( select( 1,... ) )
	if( QuestId and QuestId > 0 ) then
	    local QuestTitle = Library:Minify( C_QuestLog.GetTitleForQuestID( QuestId ) )
	    if( QuestTitle ) then
	        self.ActiveQuests[ QuestTitle ] = QuestTitle
	    end
	end
end

--
--  Disable Quest Events
--
--  @return void
function QUESTS:QUEST_TURNED_IN( Event,... )
    self:UnregisterEvent( 'QUEST_ACCEPTED' )
    self:UnregisterEvent( 'QUEST_TURNED_IN' )
    self:RebuildQuests()
end

--
--  Enable Quest Events
--
--  @return void
function QUESTS:RegisterCallbacks()
	self:RegisterEvent( 'QUEST_ACCEPTED' )
	self:RegisterEvent( 'QUEST_TURNED_IN' )
end

function QUESTS:OnEnable()
    if( DB:GetDBValue( 'QuestAlert' ) ) then
        self:RegisterCallbacks()
    else
        self:DisableQuestEvents()
    end
    self:RebuildQuests()
end