local _,Library = ...

local ADDON = LibStub( 'AceAddon-3.0' ):GetAddon( 'jChat' )
local CHATFRAME = ADDON:GetModule( 'chatframe' )
local QUESTS = ADDON:GetModule( 'quests' )
local DB = ADDON:GetModule( 'database' )
local APP = ADDON:NewModule( 'app' )

local CreateColor = CreateColor
local TimeUtil = TimeUtil
local BetterDate = BetterDate
local ChatTypeInfo = ChatTypeInfo
local C_ChatInfo = C_ChatInfo

function APP:CanUnPackArgs( Value )
    if( Value and type( Value ) == 'table' ) then
        return true
    end
end

function APP:PrependTimeStamp( MessageText )
    -- Timestamp Formats
    local PossibleTimestampFmts = {
        none = 'none',
        hour_min_12 = '%I:%M ',
        hour_min_ext = '%I:%M %p ',
        hour_min_sec_12_ext = '%I:%M:%S %p ',
        hour_min_24 = '%H:%M ',
        hour_min_sec_24 = '%H:%M:%S ',
    }

    -- Timestamp Format
    local SelectedKey = DB:GetDBValue( 'showTimestamps' )
    local FmtString = PossibleTimestampFmts[ SelectedKey ] or 'none'

    -- Timestamp Color
    local r, g, b = unpack( DB:GetDBValue( 'TimeColor' ) )
    local TimeStampColor = CreateColor(r, g, b, 1)
    
    -- Prepend Timestamp
    if( FmtString ~= 'none' ) then
        local RawTime
        if( TimeUtil and TimeUtil.BetterDate ) then
            RawTime = TimeUtil.BetterDate( FmtString,time() )
        else
            RawTime = BetterDate( FmtString,time() )
        end
        local ColoredTime = TimeStampColor:WrapTextInColorCode( RawTime )
        MessageText = ColoredTime .. MessageText
    end

    return MessageText
end

function APP:AddMessage( MessageText,R,G,B,TypeId,... )
    local MyName = UnitName( 'player' )
    local ChatType = select( 3,... ) or ''
    local WhisperTypeInfo = ChatTypeInfo['WHISPER']

    local CannotProcess
    if( issecretvalue( MessageText ) ) then
        CannotProcess = true
    end
    if( C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() ) then
        CannotProcess = true
    end

    -- Stop Early if Cannot Unpack
    if( not APP:CanUnPackArgs( select( 4,... ) ) ) then
        if( CHATFRAME.Hooks[self] ) then
            return CHATFRAME.Hooks[self]( self,MessageText,R,G,B,TypeId,... )
        end
    end

    -- Stop Early for Combat
    if( CannotProcess ) then
        if( CHATFRAME.Hooks[self] ) then
            return CHATFRAME.Hooks[self]( self,MessageText,R,G,B,TypeId,... )
        end
    end

    -- Not sure why this is a table... lol
    local TableValues = select( 4,... )
    local TextToFilter,SenderName,
        LangHeader,
        ChannelNameId,
        _,
        GMFlag,
        BckUpChannelId,
        IntChannelId,
        ChannelBaseName,
        UnUsed,
        LineId,
        PlayerId,
        BNId,
        IsMobile,
        _,
        LBox,
    IconReplacement = unpack( TableValues )

    -- Stop Early for Invalid Sender
    if( not SenderName or SenderName == nil or SenderName == '' ) then
        if( CHATFRAME.Hooks[self] ) then
            return CHATFRAME.Hooks[self]( self,MessageText,R,G,B,TypeId,... )
        end
    end

    -- Stop Early for Secret Sender
    if( issecretvalue( SenderName ) ) then
        if( CHATFRAME.Hooks[self] ) then
            return CHATFRAME.Hooks[self]( self,MessageText,R,G,B,TypeId,... )
        end
    end

    -- Retrieve Channel Permission Value
    local Permission
    if( IntChannelId > 0 ) then
        Permission = DB:GetDBValue( 'Channels' )[ ChannelBaseName ] or false
    end
    if( not Permission ) then
        if( Library:Minify( ChannelBaseName ):find( 'trade' ) ) then
            Permission = DB:GetDBValue( 'Channels' )[ 'Trade' ]
        end
    end

    -- Ignored Message
    local Ignored
    local IgnoredMessages = DB:GetIgnores()
    if( #IgnoredMessages > 0 ) then
        for _,IgnoredMessage in pairs( IgnoredMessages ) do
            if( Library:Minify( TextToFilter ):find( Library:Minify( IgnoredMessage ) ) ) then
                if( not Library:Minify( SenderName ):find( Library:Minify( MyName ) ) ) then
                    Ignored = true
                end
            end
        end
    end
    if( Permission and Permission.Allowed == false ) then
        Ignored = true
    end

    -- Watch Check
    local function GetWatched()
        return Watched
    end
    local function SetWatched( Word )
        Watched = Word
    end
    local Watched,Mentioned = false,false
    local WatchedMessages = DB:GetAlerts()
    if( #WatchedMessages > 0 ) then
        for _,WatchedMessage in pairs( WatchedMessages ) do
            if( Library:Minify( TextToFilter ):find( Library:Minify( WatchedMessage ) ) ) then
                Watched = '|Alert:'..WatchedMessage
            end
        end
    end

    if( DB:GetDBValue( 'QuestAlert' ) ) then
        for _,ActiveQuest in pairs( QUESTS.ActiveQuests ) do
            if( Library:Minify( TextToFilter ):find( ActiveQuest ) ) then
                Watched = '|Quest:'..ActiveQuest
            end
        end
    end

    -- Mention Check
    local function GetMentioned()
        return Mentioned
    end
    local function SetMentioned( Word )
        Mentioned = Word
    end
    if( DB:GetDBValue( 'MentionAlert' ) ) then
        if( Library:Minify( TextToFilter ):find( Library:Minify( MyName ) ) ) then
            Mentioned = '|Mentioned:'..MyName
        end
    end
    local AliasList = DB:GetAliasList()
    if( #AliasList > 0 ) then
        for _,Alias in pairs( AliasList ) do
            if( Library:Minify( TextToFilter ):find( Library:Minify( Alias ) ) ) then
                Mentioned = '|Mentioned:'..Alias
            end
        end
    end
    SetMentioned( Mentioned )

    local Mentioned = GetMentioned()
    local Watched = GetWatched()

    -- Override for Monitored Messages
    if( Watched or Mentioned ) then
        if( DB:GetDBValue( 'BypassPerms' ) ) then
            Ignored = false
        end
    end

    -- Ignored
    if( Ignored ) then
        return true
    end

    -- URL Copy
    local function GetURLPatterns()
        return {
            { '[a-z]*://[^ >,;]*','%s' },
        }
    end
    if( DB:GetDBValue( 'LinksEnabled' ) ) then
        local Color = 'ffffff'
        local ALink = '|cff'..Color..'|Haddon:jChat:url|h[>%1$s<]|h|r'
        if( strlen( TextToFilter ) > 7 ) then
            local Patterns = GetURLPatterns()
            for i = 1, #Patterns do
                local v = Patterns[i]
                MessageText = gsub( MessageText,v[1],function( str )
                    return format( ALink,str )
                end )
            end
        end
    end

    -- Invite Check
    if( ChatType:find( 'WHISPER' ) and DB:GetDBValue( 'AutoInvite' ) ) then
        if( Library:Minify( TextToFilter ) == 'inv' ) then
            if( GetNumGroupMembers and GetNumGroupMembers() > 4 ) then
                if( ConvertToRaid ) then
                    ConvertToRaid()
                elseif( C_PartyInfo and C_PartyInfo.ConvertToRaid ) then
                    C_PartyInfo:ConvertToRaid()
                end
            end
            InviteUnit( SenderName )
        end
    end

    -- Format Timestamp
    MessageText = APP:PrependTimeStamp( MessageText )

    -- Channel Colors
    local HighLightColor = {}
    local DBChannels = DB:GetPersistence().Channels
    if( tonumber( IntChannelId ) > 0 ) then
        if( DBChannels[ ChannelBaseName ] and DBChannels[ ChannelBaseName ].Color ) then
            HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( DBChannels[ ChannelBaseName ].Color )
            MessageText = CreateColor( HighLightColor.r, 
                HighLightColor.g, 
                HighLightColor.b, 
                HighLightColor.a 
            ):WrapTextInColorCode( MessageText )
        end
    end

    -- Sender is Me
    if( Library:Minify( SenderName ):find( Library:Minify( MyName ) ) ) then
        if( ( Mentioned or Watched ) and not ChannelBaseName:find( 'jlelz' ) ) then
            if( Mentioned ) then Mentioned = false end
            if( Watched ) then Watched = false end
        end
    end

    -- Don't Alert for Whisper
    if( Mentioned and ChatType:find( 'WHISPER' ) ) then Mentioned = false end
    if( Watched and ChatType:find( 'WHISPER' ) ) then Watched = false end

    -- Highlight Colors
    if( Watched ) then
        HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( DB:GetDBValue( 'AlertColor' ) )
    end
    if( Mentioned ) then
        if( WhisperTypeInfo and WhisperTypeInfo.r ) then
            HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = WhisperTypeInfo.r,WhisperTypeInfo.g,WhisperTypeInfo.b,WhisperTypeInfo.a
        end
    end

    -- Watched
    if( Watched ) then
        MessageText = MessageText
            ..CreateColor( HighLightColor.r, HighLightColor.g, HighLightColor.b, HighLightColor.a ):WrapTextInColorCode( tostring( Watched ) )
    end

    -- Mentioned
    if( Mentioned ) then
        MessageText = MessageText
            ..CreateColor( HighLightColor.r, HighLightColor.g, HighLightColor.b, HighLightColor.a ):WrapTextInColorCode( tostring( Mentioned ) )
    end

    -- Audible Alert
    if( Watched or Mentioned ) then
        PlaySound( SOUNDKIT.TELL_MESSAGE,DB:GetDBValue( 'AlertChannel' ) )
    end

    --[[
    local Args = { ... }
    local StringArgs = ''
    for k, v in pairs(Args) do
        if( type( v ) == 'table' ) then
            for i,m in pairs( v ) do
                StringArgs = StringArgs .. " v[" .. i .. "] = " .. tostring(m) .. ", "
            end
        end
        StringArgs = StringArgs .. k .. " = " .. tostring(v) .. ", "
    end
    MessageText = StringArgs .. MessageText
    ]]
    if( DB:GetDBValue( 'ShortChannelNames' ) ) then
        if( ChannelBaseName and IntChannelId > 0 ) then
            -- This looks for string combinations like '[1. General - Orgrimmar]' or '|h[1. General]|h'
            if ChannelBaseName:find("General") then
                MessageText = MessageText:gsub( "General%s?-%s?[^%]]+",'GEN' )
            elseif ChannelBaseName:find("LocalDefense") then
                MessageText = MessageText:gsub( "LocalDefense",'LDEF' )
            elseif ChannelBaseName:find("WorldDefense") then
                MessageText = MessageText:gsub( "WorldDefense",'WDEF' )
            elseif ChannelBaseName:find("LookingForGroup") then
                MessageText = MessageText:gsub( "LookingForGroup",'LFG' )
            elseif ChannelBaseName:find("Trade") then
                MessageText = MessageText:gsub( "Trade%s?-%s?[^%]]+",'TRADE' )
            end
        end
    end

    -- Default Handler
    if( CHATFRAME.Hooks[self] ) then
        return CHATFRAME.Hooks[self]( self,MessageText,R,G,B,TypeId,... )
    end
end

function APP:OnEnable()
    for Name,Module in self:IterateModules() do
    	self:EnableModule( Name )
    end

    for i = 1, 10 do
        local Frame = _G[ 'ChatFrame'..i ]

        if( Frame ) then
            CHATFRAME.Hooks[ Frame ] = Frame.AddMessage
            Frame.AddMessage = APP.AddMessage
        end
    end

    CHATFRAME:Refresh()
end