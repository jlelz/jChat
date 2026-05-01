local _, Addon = ...;
local strsub = string.sub;
local issecretvalue = issecretvalue or function()end;

local C_ChatInfo = C_ChatInfo;
local C_Club = C_Club;
local C_PartyInfo = C_PartyInfo;

local ConvertToRaid = ConvertToRaid;
local WrapTextInColorCode = WrapTextInColorCode;
local InCombatLockdown = InCombatLockdown;
local CreateColor = CreateColor;
local UnitName = UnitName;
local BetterDate = BetterDate;

Addon.APP = CreateFrame( 'Frame' );

Addon.APP.PrependTimeStamp = function( self,MessageText )
    -- Timestamp Formats
    local PossibleTimestampFmts = {
        none = 'none',
        hour_min_12 = '%I:%M ',
        hour_min_ext = '%I:%M %p ',
        hour_min_sec_12_ext = '%I:%M:%S %p ',
        hour_min_24 = '%H:%M ',
        hour_min_sec_24 = '%H:%M:%S ',
    };

    -- Timestamp Format
    local SelectedKey = Addon.CONFIG:GetValue( 'showTimestamps' ); 
    local FmtString = PossibleTimestampFmts[ SelectedKey ] or 'none';

    -- Timestamp Color
    local r, g, b = unpack( Addon.CONFIG:GetValue( 'TimeColor' ) );
    local TimeStampColor = CreateColor(r, g, b, 1);
    
    -- Prepend Timestamp
    if( FmtString ~= 'none' ) then
        local RawTime = BetterDate( FmtString,time() );
        local ColoredTime = TimeStampColor:WrapTextInColorCode( RawTime );
        MessageText = ColoredTime .. MessageText
    end

    return MessageText;
end

Addon.APP.CanUnPackArgs = function( self,Value )
    if( Value and type( Value ) == 'table' ) then
        return true;
    end
end

Addon.APP.AddMessage = function( self,MessageText,R,G,B,TypeId,... )
    local MyName = UnitName( 'player' );
    local ChatType = select( 3,... ) or '';
    local WhisperTypeInfo = ChatTypeInfo['WHISPER'];
    local AcceptedTypes = {
        CHAT_MSG_CHANNEL = true,
        CHAT_MSG_COMMUNITIES_CHANNEL = true,
        CHAT_MSG_CHANNEL_NOTICE_USER = true,
        CHAT_MSG_WHISPER = true
    };
    local CannotProcess;
    if( issecretvalue( MessageText ) ) then
        CannotProcess = true;
    end
    if( InCombatLockdown() ) then
        CannotProcess = true;
    end
    if( C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() ) then
        CannotProcess = true;
    end

    -- Stop Early if Cannot Unpack
    if( not Addon.APP:CanUnPackArgs( select( 4,... ) ) ) then
        if( Addon.CHAT.Hooks[self] ) then
            return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
        end
    end

    -- Stop Early for Unrecognized Message Types
    if( not AcceptedTypes[ ChatType ] ) then
        if( Addon.CHAT.Hooks[self] ) then
            return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
        end
    end

    -- Stop Early for Combat
    if( CannotProcess ) then
        if( Addon.CHAT.Hooks[self] ) then
            return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
        end
    end

    -- Not sure why this is a table... lol
    local TableValues = select( 4,... );
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
    IconReplacement = unpack( TableValues );

    -- Stop Early for Invalid Sender
    if( not SenderName or SenderName == nil or SenderName == '' ) then
        if( Addon.CHAT.Hooks[self] ) then
            return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
        end
    end

    -- Stop Early for Secret Sender
    if( issecretvalue( SenderName ) ) then
        if( Addon.CHAT.Hooks[self] ) then
            return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
        end
    end

    -- Retrieve Channel Permission Value
    local Permission;
    if( IntChannelId > 0 ) then
        Permission = Addon.CONFIG:GetValue( 'Channels' )[ ChannelBaseName ] or false;
    end
    if( not Permission ) then
        if( Addon:Minify( ChannelBaseName ):find( 'trade' ) ) then
            Permission = Addon.CONFIG:GetValue( 'Channels' )[ 'Trade' ];
        end
    end

    -- Ignored Message
    local Ignored;
    local IgnoredMessages = Addon.CONFIG:GetIgnores();
    if( #IgnoredMessages > 0 ) then
        for _,IgnoredMessage in pairs( IgnoredMessages ) do
            if( Addon:Minify( TextToFilter ):find( Addon:Minify( IgnoredMessage ) ) ) then
                if( not Addon:Minify( SenderName ):find( Addon:Minify( MyName ) ) ) then
                    Ignored = true;
                end
            end
        end
    end
    if( Permission and Permission.Allowed == false ) then
        Ignored = true;
    end

    -- Watch Check
    local function GetWatched()
        return Watched;
    end
    local function SetWatched( Word )
        Watched = Word;
    end
    local Watched,Mentioned = false,false;
    local WatchedMessages = Addon.CONFIG:GetAlerts();
    if( #WatchedMessages > 0 ) then
        for _,WatchedMessage in pairs( WatchedMessages ) do
            if( Addon:Minify( TextToFilter ):find( Addon:Minify( WatchedMessage ) ) ) then
                Watched = '|Alert:'..WatchedMessage;
            end
        end
    end
    if( Addon.CONFIG:GetValue( 'QuestAlert' ) ) then
        for _,ActiveQuest in pairs( Addon.QUESTS.ActiveQuests ) do
            if( Addon:Minify( TextToFilter ):find( ActiveQuest ) ) then
                Watched = '|Quest:'..ActiveQuest;
            end
        end
    end

    -- Queue Check
    local Dungeons = Addon.DUNGEONS:GetDungeonsF();
    local DungeonQueue = Addon.DB:GetPersistence().DungeonQueue or {};
    for ABBREV,IsQueued in pairs( DungeonQueue ) do
        if( IsQueued ) then
            for _,Abbrev in pairs( Dungeons[ ABBREV ].Abbrevs ) do
                if( Addon:Minify( TextToFilter ):find( Addon:Minify( Abbrev ) ) ) then
                    Watched = '|Dungeon:'..ABBREV..'|Abbrev:'..Abbrev;
                end
            end
            if( Addon:Minify( TextToFilter ):find( Addon:Minify( ABBREV ) ) ) then
                Watched = '|Dungeon:'..ABBREV;
            end
        end
    end
    local Raids = Addon.DUNGEONS:GetRaidsF();
    local RaidQueue = Addon.DB:GetPersistence().RaidQueue or {};
    for ABBREV,IsQueued in pairs( RaidQueue ) do
        if( IsQueued ) then
            for _,Abbrev in pairs( Raids[ ABBREV ].Abbrevs ) do
                if( Addon:Minify( TextToFilter ):find( Addon:Minify( Abbrev ) ) ) then
                    Watched = '|Raid:'..ABBREV..'|Abbrev:'..Abbrev;
                end
            end
            if( Addon:Minify( TextToFilter ):find( Addon:Minify( ABBREV ) ) ) then
                Watched = '|Raid:'..ABBREV;
            end
        end
    end
    SetWatched( Watched );

    -- Mention Check
    local function GetMentioned()
        return Mentioned;
    end
    local function SetMentioned( Word )
        Mentioned = Word;
    end
    if( Addon.CONFIG:GetValue( 'MentionAlert' ) ) then
        if( Addon:Minify( TextToFilter ):find( Addon:Minify( MyName ) ) ) then
            Mentioned = '|Mentioned:'..MyName;
        end
    end
    local AliasList = Addon.CONFIG:GetAliasList();
    if( #AliasList > 0 ) then
        for _,Alias in pairs( AliasList ) do
            if( Addon:Minify( TextToFilter ):find( Addon:Minify( Alias ) ) ) then
                Mentioned = '|Mentioned:'..Alias;
            end
        end
    end
    SetMentioned( Mentioned );

    local Mentioned = GetMentioned();
    local Watched = GetWatched();

    -- Override for Monitored Messages
    if( Watched or Mentioned ) then
        if( Addon.CONFIG:GetValue( 'BypassTypes' ) ) then
            Ignored = false;
        end
    end

    -- Ignored
    if( Ignored ) then
        return true;
    end

    -- URL Copy
    local function GetURLPatterns()
        return {
            { '[a-z]*://[^ >,;]*','%s' },
        };
    end
    if( Addon.CONFIG:GetValue( 'LinksEnabled' ) ) then
        local Color = 'ffffff';
        local ALink = '|cff'..Color..'|Haddon:jChat:url|h[>%1$s<]|h|r';
        if( strlen( TextToFilter ) > 7 ) then
            local Patterns = GetURLPatterns();
            for i = 1, #Patterns do
                local v = Patterns[i];
                MessageText = gsub( MessageText,v[1],function( str )
                    return format( ALink,str );
                end );
            end
        end
    end

    -- Invite Check
    if( ChatType:find( 'WHISPER' ) and Addon.CONFIG:GetValue( 'AutoInvite' ) ) then
        if( Addon:Minify( TextToFilter ) == 'inv' ) then
            if( GetNumGroupMembers and GetNumGroupMembers() > 4 ) then
                if( ConvertToRaid ) then
                    ConvertToRaid();
                elseif( C_PartyInfo and C_PartyInfo.ConvertToRaid ) then
                    C_PartyInfo:ConvertToRaid();
                end
            end
            InviteUnit( SenderName );
        end
    end

    -- Format Timestamp
    MessageText = Addon.APP:PrependTimeStamp( MessageText );

    -- Channel Colors
    local HighLightColor = {};
    local DBChannels = Addon.DB:GetPersistence().Channels;
    if( tonumber( IntChannelId ) > 0 ) then
        if( DBChannels[ ChannelBaseName ] and DBChannels[ ChannelBaseName ].Color ) then
            HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( DBChannels[ ChannelBaseName ].Color );
            MessageText = CreateColor( HighLightColor.r, 
                HighLightColor.g, 
                HighLightColor.b, 
                HighLightColor.a 
            ):WrapTextInColorCode( MessageText );
        end
    end

    -- Sender is Me
    if( Addon:Minify( SenderName ):find( Addon:Minify( MyName ) ) ) then
        if( ( Mentioned or Watched ) and not ChannelBaseName:find( 'jlelz' ) ) then
            if( Mentioned ) then Mentioned = false; end;
            if( Watched ) then Watched = false; end;
        end
    end

    -- Don't Alert for Whisper
    if( Mentioned and ChatType:find( 'WHISPER' ) ) then Mentioned = false; end;
    if( Watched and ChatType:find( 'WHISPER' ) ) then Watched = false; end;

    -- Highlight Colors
    if( Watched ) then
        HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( Addon.CONFIG:GetValue( 'AlertColor' ) );
    end
    if( Mentioned ) then
        if( WhisperTypeInfo and WhisperTypeInfo.r ) then
            HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = WhisperTypeInfo.r,WhisperTypeInfo.g,WhisperTypeInfo.b,WhisperTypeInfo.a;
        end
    end

    -- Watched
    if( Watched ) then
        MessageText = MessageText
            ..CreateColor( HighLightColor.r, HighLightColor.g, HighLightColor.b, HighLightColor.a ):WrapTextInColorCode( tostring( Watched ) );
    end

    -- Mentioned
    if( Mentioned ) then
        MessageText = MessageText
            ..CreateColor( HighLightColor.r, HighLightColor.g, HighLightColor.b, HighLightColor.a ):WrapTextInColorCode( tostring( Mentioned ) );
    end

    -- Audible Alert
    if( Watched or Mentioned ) then
        PlaySound( SOUNDKIT.TELL_MESSAGE,Addon.CONFIG:GetValue( 'AlertChannel' ) );
    end

    --[[
    local Args = { ... };
    local StringArgs = '';
    for k, v in pairs(Args) do
        if( type( v ) == 'table' ) then
            for i,m in pairs( v ) do
                StringArgs = StringArgs .. " v[" .. i .. "] = " .. tostring(m) .. ", "
            end
        end
        StringArgs = StringArgs .. k .. " = " .. tostring(v) .. ", "
    end
    MessageText = StringArgs .. MessageText;
    ]]
    -- Default Handler
    if( Addon.CHAT.Hooks[self] ) then
        return Addon.CHAT.Hooks[self]( self,MessageText,R,G,B,TypeId,... );
    end
end

Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName ~= 'jChat' ) then return end;

    Addon.FRAMES:Notify( 'Prepping..please wait' );

    -- Initialize
    Addon.DB:Init();
    Addon.QUESTS:Init();
    Addon.CHAT:Init();
    Addon.CONFIG:Init();

    -- Callbacks
    Addon.CONFIG:RegisterCallbacks();
    Addon.CHAT:RegisterCallbacks();

    -- Quests
    if( Addon.CONFIG:GetValue( 'QuestAlert' ) ) then
        Addon.QUESTS:EnableQuestEvents();
    else
        Addon.QUESTS:DisableQuestEvents();
    end
    Addon.QUESTS:RebuildQuests();

    -- Joins
    local DBChannels = Addon.DB:GetPersistence().Channels;
    local FrameChannels = Addon.CHAT:GetChannels();

    for i,Channel in pairs( FrameChannels ) do
        Channel.Name = Addon.CHAT:GetClubName( Channel.Name ) or Channel.Name;

        local ClubData = Addon:Explode( Channel.Name,':' );
        if( ClubData and tonumber( #ClubData ) > 0 ) then
            local ClubId = ClubData[2] or 0;
            if( tonumber( ClubId ) > 0 ) then
                local ClubInfo = C_Club.GetClubInfo( ClubId );
                if( ClubInfo ) then
                    Channel.Name = ClubInfo.name;
                    Channel.Name = ChannelData.Name:gsub( '%s+','' );
                end
            end
        end

        local ChannelLink;
        if( tonumber( Channel.Id ) > 0 ) then
            ChannelLink = Addon.CHAT:GetChannelLink( Channel.Id,Channel.Name );
        end

        local HighLightColor = {};
        if( tonumber( Channel.Id ) > 0 ) then
            if( DBChannels[ Channel.Name ] and DBChannels[ Channel.Name ].Color ) then
                HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( DBChannels[ Channel.Name ].Color );
            else
                local ChatInfo = ChatTypeInfo[ 'CHANNEL_JOIN' ];
                HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( ChatInfo );
            end
        end

        local JoinedText = CreateColor( HighLightColor.r or 1, 
            HighLightColor.g or 1, 
            HighLightColor.b or 1, 
            HighLightColor.a or 1 ):WrapTextInColorCode( 'You have joined '..ChannelLink );

        local Frame = _G[ 'ChatFrame'..1 ];
        if( Frame ) then
            Frame:AddMessage( JoinedText );
        end
    end

    Addon.FRAMES:Notify( 'Done' );
end );