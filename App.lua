local _, Addon = ...;

local ChatFrameUtil = ChatFrameUtil;
local C_Club = C_Club;
local C_ChatInfo = C_ChatInfo;
local C_PartyInfo = C_PartyInfo;
local GetPlayerInfoByGUID = GetPlayerInfoByGUID;
local GMChatFrame_IsGM = GMChatFrame_IsGM;
local GetChannelName = GetChannelName;
local BetterDate = BetterDate;
local PlaySound = PlaySound;
local CreateColor = CreateColor;
local RemoveExtraSpaces = RemoveExtraSpaces;
local SOUNDKIT = SOUNDKIT;
local InviteUnit = InviteUnit;
local ChatEdit_ActivateChat = ChatEdit_ActivateChat;
local ToggleChatColorNamesByClassGroup = ToggleChatColorNamesByClassGroup;
local ChatTypeInfo = ChatTypeInfo;
local InCombatLockdown = InCombatLockdown;

local strsub = strsub;
local unpack = unpack;
local tonumber = tonumber;
local tostring = tostring;
local ipairs = ipairs;
local pairs = pairs;

-- fallbacks
local ChatFrame_ReplaceIconAndGroupExpressions = ChatFrame_ReplaceIconAndGroupExpressions;

Addon.APP = CreateFrame( 'Frame' );
Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jChat' ) then

        --
        -- Set chant filter
        --
        -- @return void
        Addon.APP.SetFilter = function( self,Filter,Value )
            if( Value ) then
                ChatFrame_AddMessageEventFilter( Filter,self.Filter );
            else
                ChatFrame_RemoveMessageEventFilter( Filter,self.Filter );
            end
        end

        Addon.APP.GetAlertFrame = function( self,MessageText,Type )
            local BGA,TextA = Addon.APP:GetValue( 'MentionAlpha' ),1;
            local Frame = Addon.FRAMES:AddAcknowledge( { Name='jChatMention',Label=Type,Value=MessageText,BGA=BGA,TextA=TextA },nil );
            Frame:HookScript( 'OnDragStop',function( self )
                self:StopMovingOrSizing();
                self:SetUserPlaced( true );
            end );
            Frame:HookScript( 'OnUpdate',function( self )

                local BGAlpha = self.Texture:GetAlpha();

                if( self:IsMouseOver() ) then
                    if( BGAlpha <= 0 ) then
                        if( self.Label ) then
                            self.Label:SetAlpha( TextA );
                        end
                        self.Texture:SetAlpha( BGA );
                        self.Butt:SetAlpha( TextA );
                    end
                else
                    if( BGAlpha >= 0 ) then
                        if( self.Label ) then
                            self.Label:SetAlpha( 0 );
                        end
                        self.Texture:SetAlpha( 0 );
                        self.Butt:SetAlpha( 0 );
                    end
                end
            end );
            return Frame;
        end

        Addon.APP.GetURLPatterns = function()
            return {
                { '[a-z]*://[^ >,;]*','%s' },
            };
        end

        Addon.APP.GetChannelLink = function( self,ChannelId,ChannelBaseName,ChatType )
            local ChannelLink = '';
            if( tonumber( ChannelId ) > 0 ) then
                ChannelLink = "|Hchannel:channel:"..ChannelId.."|h["..ChannelId..']'..ChannelBaseName.."]|h"    -- "|Hchannel:channel:2|h[2) Trade - City]|h"
            elseif( ChatType == 'PARTY' ) then
                ChannelLink = "|Hchannel:PARTY|h[Party]|h";
            elseif( ChatType == 'PARTY_LEADER' ) then
                ChannelLink = "|Hchannel:PARTY|h[Party Leader]|h";
            elseif( ChatType == 'INSTANCE_CHAT' ) then
                ChannelLink = "|Hchannel:INSTANCE_CHAT|h[Instance]|h";
            elseif( ChatType == 'INSTANCE_CHAT_LEADER' ) then
                ChannelLink = "|Hchannel:INSTANCE_CHAT|h[Instance Leader]|h";
            elseif( ChatType == 'RAID' ) then
                ChannelLink = "|Hchannel:RAID|h[Raid]|h";
            elseif( ChatType == 'RAID_LEADER' or ChatType == 'RAID_WARNING' ) then
                ChannelLink = "|Hchannel:RAID|h[Raid Leader]|h";
            elseif( ChatType == 'GUILD' ) then
                ChannelLink = "|Hchannel:GUILD|h[Guild]|h";
            end
            return ChannelLink;
        end

        --
        --  Format Chat Message
        --
        --  @param  string  Event
        --  @param  string  MessageText
        --  @param  string  PlayerRealm
        --  @param  string  LangHeader
        --  @param  string  ChannelNameId
        --  @param  string  PlayerName
        --  @param  string  GMFlag
        --  @param  string  ChannelId
        --  @param  string  PlayerId
        --  @param  string  IconReplacement
        --  @param  string  Watched
        --  @param  bool    Mentioned
        --  @return list
        local AlertLayer = 1;
        Addon.APP.Format = function( Event,MessageText,PlayerRealm,LangHeader,ChannelNameId,PlayerName,GMFlag,Arg7,ChannelId,ChannelBaseName,UnUsed,LineId,PlayerId,BNId,Arg14,LBox,IconReplacement,Watched,Mentioned )
            local OriginalText = MessageText;
            local ChatType = strsub( Event,10 );
            local Info = ChatTypeInfo[ ChatType ];
            if( not Info ) then
                Info = {
                    colorNameByClass = true,r = 255/255,g = 255/255,b = 255/255,id = nil,
                };
            end
            local _, ChannelName = GetChannelName( ChannelId );

            local GetName = function( Id )
                local Channels = Addon.DB:GetPersistence().Channels;
                for _,ChannelData in pairs( Channels ) do
                    if( ChannelData.Id == Id ) then
                        return ChannelData.Name;
                    end
                end
            end
            ChannelName = GetName( ChannelId ) or ChannelName;
            local ChatGroup = ChatFrameUtil.GetChatCategory( ChatType );

            -- Player info
            local LocalizedClass,EnglishClass,LocalizedRace,EnglishRace,Sex,Name,Server;
            if( PlayerId ) then
                LocalizedClass,EnglishClass,LocalizedRace,EnglishRace,Sex,Name,Server = GetPlayerInfoByGUID( PlayerId );
                if( PlayerName == '' ) then
                    PlayerName = Name;
                end
            end
            --print( C_FriendList.SendWho( PlayerRealm ) );

            -- Class color
            if( PlayerName and Addon.APP:GetValue( 'ColorNamesByClass' ) ) then
                PlayerName = ChatFrameUtil.GetDecoratedSenderName( Event,MessageText,PlayerRealm,LangHeader,ChannelNameId,PlayerName,GMFlag,Arg7,ChannelId,ChannelBaseName,UnUsed,LineId,PlayerId,BNId,Arg14,LBox,IconReplacement );
            end

            -- Replace icon and group tags like {rt4} and {diamond}
            if( C_ChatInfo and C_ChatInfo.ReplaceIconAndGroupExpressions ) then
                MessageText = C_ChatInfo.ReplaceIconAndGroupExpressions( MessageText, IconReplacement, not C_ChatInfo.ReplaceIconAndGroupExpressions( ChatGroup ) );                
            else
                MessageText = ChatFrame_ReplaceIconAndGroupExpressions( MessageText, IconReplacement, not ChatFrame_CanChatGroupPerformExpressionExpansion( ChatGroup ) );
            end
            MessageText = RemoveExtraSpaces( MessageText );

            -- Add AFK/DND flags
            local PFlag = ChatFrameUtil.GetPFlag( GMFlag,ChannelId,ChannelBaseName );
            if ( ChatType == 'WHISPER_INFORM' and GMChatFrame_IsGM and GMChatFrame_IsGM( PlayerRealm ) ) then
                return;
            end

            local PlayerAction = '';
            if( ChatType == 'YELL' ) then
                PlayerAction = ' yells';
            end
            if ( ChatType == 'WHISPER' ) then
                PlayerAction = ' whispers';
            end

            -- Timestamp
            local TimeStamp = '';
            local chatTimestampFmt = Addon.APP:GetValue( 'showTimestamps' );
            if ( chatTimestampFmt ~= 'none' ) then
                TimeStamp = BetterDate( chatTimestampFmt,time() );
            end
            if( GetCVar( 'showTimestamps' ) ~= chatTimestampFmt ) then
                SetCVar( 'showTimestamps',chatTimestampFmt );
            end

            TimeStamp = CreateColor( unpack( Addon.APP:GetValue( 'TimeColor' ) ) ):WrapTextInColorCode( TimeStamp );

            -- Set Channel Color via DB Colors
            local ChannelColor = {
                r = Info.r,
                g = Info.g,
                b = Info.b,
                a = 1,
            };
            local Channels = Addon.DB:GetPersistence().Channels;
            if( tonumber( ChannelId ) > 0 ) then
                if( Channels[ ChannelName ] and Channels[ ChannelName ].Color ) then
                    ChannelColor.r,ChannelColor.g,ChannelColor.b,ChannelColor.a = unpack( Channels[ ChannelName ].Color );
                end
            end
            ChatTypeInfo[ ChatType ] = ChatTypeInfo[ ChatType ] or {
                r = Info.r,
                g = Info.g,
                b = Info.b,
                a = 1,
            };
            ChatTypeInfo[ ChatType ].r,
            ChatTypeInfo[ ChatType ].g,
            ChatTypeInfo[ ChatType ].b,
            ChatTypeInfo[ ChatType ].a = ChannelColor.r,ChannelColor.g,ChannelColor.b,ChannelColor.a;

            -- Channel link
            -- https://wowpedia.fandom.com/wiki/Hyperlinks
            -- https://wowwiki-archive.fandom.com/wiki/ItemLink
            -- Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ItemRef.lua
            if( ChatType == 'COMMUNITIES_CHANNEL' ) then
                -- Pattern: "^community%:%d*%:%d*$"
                local MessageInfo,ClubId,StreamId,ClubType = C_Club.GetInfoFromLastCommunityChatLine();
                local ClubDisplayName = Addon.CHAT:GetClubName( StreamId..':'..ClubId );
                ChannelBaseName = ClubDisplayName;
            end
            local ChannelLink = Addon.APP:GetChannelLink( ChannelId,ChannelBaseName,ChatType );

            -- Now we have a link, color it
            local TypeColor = ChatTypeInfo[ ChatType ];
            if( TypeColor ) then
                ChannelLink = CreateColor( TypeColor.r,TypeColor.g,TypeColor.b ):WrapTextInColorCode( ChannelLink );
            end

            -- Player link
            local PlayerLink = "|Hplayer:"..PlayerRealm.."|h".."["..PlayerName.."]|h"; -- |Hplayer:Blasfemy-Grobbulus|h was here

            -- Player level
            local PlayerLevel = '';--'['..UnitLevel( PlayerId )..']';

            -- Blizz format()'s Special Event Messages
            -- e.g. CHAT_MSG_CHANNEL_NOTICE_USER 
            -- for full list of global strings, either extract it via game files or visit PTR:
            -- https://www.townlong-yak.com/framexml/ptr/Helix/GlobalStrings.lua
            local UserActions = '';
            --GetFixedLink( )
            if( ChatType == 'CHANNEL_JOIN' ) then
                MessageText = CHAT_CHANNEL_JOIN_GET:format( PlayerName );
            elseif( ChatType == 'CHANNEL_LEAVE' ) then
                MessageText = CHAT_CHANNEL_LEAVE_GET:format( PlayerName );
            elseif( Event == 'CHAT_MSG_CHANNEL_NOTICE_USER' ) then
                local GlobalString = _G["CHAT_"..ChatType.."_NOTICE_BN"];
                if( not GlobalString ) then
                    GlobalString = _G["CHAT_"..ChatType.."_NOTICE"];
                end
                if( not GlobalString ) then
                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        --Addon.FRAMES:Debug( 'Missing global string',"CHAT_"..ChatType.."_NOTICE" );
                    end
                    return;
                end
                MessageText = GlobalString:format( ChannelBaseName,PlayerName );
            else
                UserActions = PFlag..PlayerLink..PlayerAction..PlayerLevel;
            end

            -- Message Prefix
            local MessagePrefix = TimeStamp..ChannelLink..UserActions..': ';

            -- url copy
            if( Addon.APP:GetValue( 'LinksEnabled' ) ) then
                local Color = 'ffffff';
                local ALink = '|cff'..Color..'|Haddon:jChat:url|h[>%1$s<]|h|r';
                if( strlen( MessageText ) > 7 ) then
                    local Patterns = Addon.APP:GetURLPatterns();
                    for i = 1, #Patterns do
                        local v = Patterns[i];
                        MessageText = gsub( MessageText,v[1],function( str )
                            return format( ALink,str );
                        end );
                    end
                end
            end
            -- Questie support
            local QuestieText = Addon.QUESTS:QuestieFilter( Addon.CHAT.ChatFrame,
                MessagePrefix..MessageText,
                PlayerRealm,
                LangHeader,
                ChannelNameId,
                PlayerName,
                GMFlag,
                ChannelNameId,
                ChannelId,
                ChannelBaseName,
                UnUsed,
                LineId,
                PlayerId,
                BNId 
            );
            if( QuestieText ) then
                return;
            end

            -- Highlight colors
            local HighLightColor = {};
            if( Watched or Mentioned ) then
                HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a = unpack( Addon.APP:GetValue( 'AlertColor' ) );
            end

            -- Partial highlight
            if( Watched and ChatType ~= 'WHISPER' ) then
                MessageText = Addon:GiSub( MessageText,Watched,CreateColor( HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a ):WrapTextInColorCode( Watched ) );
            end
            if( Mentioned ) then
                MessageText = Addon:GiSub( MessageText,Mentioned,CreateColor( HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a ):WrapTextInColorCode( Mentioned ) );
            end

            -- Full highlight
            if( Watched and Addon.APP:GetValue( 'FullHighlight' ) and ChatType ~= 'WHISPER' ) then
                MessageText = MessageText..' : '..CreateColor( HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a ):WrapTextInColorCode( Watched );
                PlaySound( SOUNDKIT.TELL_MESSAGE,Addon.APP:GetValue( 'AlertChannel' ) );

                return MessagePrefix..MessageText,HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a,Info.id;
            end

            -- Partial highlight
            if( Watched and ChatType ~= 'WHISPER') then
                MessageText = MessageText..' : '..CreateColor( HighLightColor.r,HighLightColor.g,HighLightColor.b,HighLightColor.a ):WrapTextInColorCode( Watched );
                PlaySound( SOUNDKIT.TELL_MESSAGE,Addon.APP:GetValue( 'AlertChannel' ) );
            end

            return MessagePrefix..MessageText,ChannelColor.r,ChannelColor.g,ChannelColor.b,Info.id;
        end

        --
        --  Time Cache Rules
        --
        --  @param  list    ...
        --  @return string
        Addon.APP.GetCacheKey = function( self,... )
            local ChatType = strsub( Event,10 );
            local MessageText = select( 1,... );
            local PlayerName = select( 5,... );
            local PlayerId = select( 12,... );

            local MyPlayerName,MyRealm = UnitName( 'player' );
            local Player = PlayerId or PlayerName;

            local OncePerMinute = "%H:%M";
            local OncePerSecond = "%H:%M:%S";
            local OncePerMillisecond = tostring( GetTime() );

            -- My own messages
            if( Addon:Minify( PlayerName ):find( Addon:Minify( MyPlayerName ) ) ) then
                return Addon:Minify( Player..MessageText..OncePerMillisecond );

            -- Guild messages
            elseif( Addon:Minify( ChatType ):find( 'guild' ) ) then
                return Addon:Minify( Player..MessageText..date( OncePerSecond ) )

            -- Everyone else
            else
                return Addon:Minify( Player..MessageText..date( OncePerMinute ) );
            end
        end

        Addon.APP.CheckDiscardedMessage = function( self,Event,... )
            local shouldDiscardMessage = false;
                shouldDiscardMessage = ChatFrameUtil.ProcessMessageEventFilters( self,Event,... );

            if shouldDiscardMessage then
                return true;
            end
            return false;
        end
        --
        --  Filter Chat Message
        --
        --  @param  string  Event
        --  @param  list    ...
        --  @return bool
        Addon.APP.Filter = function( self,Event,... )
            local ChatType = strsub( Event,10 );
            local MessageText = select( 1,... );
            local OriginalText = MessageText;
            local PlayerRealm = select( 2,... );
            local LangHeader = select( 3,... );
            local ChannelNameId = select( 4,... );
            local PlayerName = select( 5,... );
            local GMFlag = select( 6,... );
            local Arg7 = select( 7,... ); 
            local ChannelId = select( 8,... );
            local ChannelBaseName = select( 9,... );
            local UnUsed = select( 10,... );
            local LineId = select( 11,... );
            local PlayerId = select( 12,... );
            local BNId = select( 13,... );
            local Arg14 = select( 14,... );
            local LBox = select( 16,... );
            local IconReplacement = select( 17,... );
            local MyPlayerName,MyRealm = UnitName( 'player' );

            -- During lockdown, don't filter. Instead, send back to default chat system
            if( ( Addon:IsRetail() and InCombatLockdown() ) or ( C_ChatInfo and C_ChatInfo.InChatMessagingLockdown() ) ) then
                if( Addon.APP:GetValue( 'Debug' ) ) then
                    Addon.FRAMES:Debug( 'InCombatLockdown','Sending Back/Not Filtering:',tostring( MessageText ) );
                end
                return false,MessageText,PlayerName,...
            end

            -- todo: review
            -- especially review any data that gets updated/tainted such as links
            -- Retail Chat /Interface/AddOns/Blizzard_ChatFrameBase/Mainline/ChatFrameOverrides.lua 
            -- https://www.google.com/search?q=in+retail+wow+midnight+12.0%2C+how+should+i+update+ChatFrame_AddMessageEventFilter+calls+to+prevent+tainting+of+chat+text%3F&rlz=1C5CHFA_enUS1174US1174&oq=in+retail+wow+midnight+12.0%2C+how+should+i+update+ChatFrame_AddMessageEventFilter+calls+to+prevent+tainting+of+chat+text%3F&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQIRiPAjIHCAIQIRiPAtIBCTM0NDM5ajBqOagCALACAA&sourceid=chrome&ie=UTF-8
            -- Some of the code below was copied from blizz and probably needs some love so they will likely udpate it quickly
            
            -- Cinematic
            if( LBox) then
                return true;
            end
            -- Discarded
            local DiscardMessage = Addon.APP:CheckDiscardedMessage( self,Event,... );
            if( DiscardMessage ) then
                return true;
            end
            -- Supressed
            local ChatGroup = ChatFrameUtil.GetChatCategory( ChatType );
            local ChatTarget = FCFManager_GetChatTarget( ChatGroup,PlayerRealm,ChannelId );
            if( FCFManager_ShouldSuppressMessage( self,ChatGroup,ChatTarget ) ) then
                return true;
            end
            -- God Awful
            if ( ChatGroup == "WHISPER" or ChatGroup == "BN_WHISPER" ) then
                if ( self.privateMessageList and not self.privateMessageList[strlower(PlayerRealm)] ) then
                    return true;
                elseif ( self.excludePrivateMessageList and self.excludePrivateMessageList[strlower(PlayerRealm)]
                    and ( (ChatGroup == "WHISPER" and GetCVar("whisperMode") ~= "popout_and_inline") or (ChatGroup == "BN_WHISPER" and GetCVar("whisperMode") ~= "popout_and_inline") ) ) then
                    return true;
                end
            end
            if (self.privateMessageList) then
                -- Dedicated BN whisper windows need online/offline messages for only that player
                if ( (ChatGroup == "BN_INLINE_TOAST_ALERT" or ChatGroup == "BN_WHISPER_PLAYER_OFFLINE") and not self.privateMessageList[strlower(PlayerRealm)] ) then
                    return true;
                end

                -- HACK to put certain system messages into dedicated whisper windows
                if ( ChatGroup == "SYSTEM") then
                    local matchFound = false;
                    local message = strlower(MessageText);
                    for playerName, _ in pairs(self.privateMessageList) do
                        local playerNotFoundMsg = strlower(format(ERR_CHAT_PLAYER_NOT_FOUND_S, PlayerName));
                        local charOnlineMsg = strlower(format(ERR_FRIEND_ONLINE_SS, PlayerName, PlayerName));
                        local charOfflineMsg = strlower(format(ERR_FRIEND_OFFLINE_S, PlayerName));
                        if ( message == playerNotFoundMsg or message == charOnlineMsg or message == charOfflineMsg) then
                            matchFound = true;
                            break;
                        end
                    end

                    if (not matchFound) then
                        return true;
                    end
                end
            end

            -- Prevent ignored messages
            local IgnoredMessages = Addon.CONFIG:GetIgnores();
            if( #IgnoredMessages > 0 ) then
                for i,IgnoredMessage in ipairs( IgnoredMessages ) do
                    if( Addon:Minify( OriginalText ):find( Addon:Minify( IgnoredMessage ) ) ) then
                        if( not Addon:Minify( PlayerName ):find( Addon:Minify( MyPlayerName ) ) ) then
                            return true;
                        end
                    end
                end
                for i,IgnoredIdiot in ipairs( IgnoredMessages ) do
                    if( Addon:Minify( PlayerName ):find( Addon:Minify( IgnoredIdiot ) ) ) then
                        return true;
                    end
                end
            end

            -- Prevent toggled off message types
            local PossibleTypes = {};
            for Type,MessageTypes in pairs( Addon.CONFIG:GetChatFilters() ) do
                for i,MessageType in pairs( MessageTypes ) do
                    PossibleTypes[ MessageType ] = Type;
                end
            end
            local Values = Addon.APP:GetValue( 'ChatGroups' );
            if( PossibleTypes[ Event ] and not Values[ PossibleTypes[ Event ] ] ) then
                --print( 'stopped sending',Event,MessageText )
                return true;
            end

            -- GM check
            if( GMFlag == 'GM' and ChatType == 'WHISPER' ) then
                return;
            end

            -- Prevent repeat messages
            local CacheKey = Addon.APP:GetCacheKey( ... );
            if( Addon.APP.Cache[ CacheKey ] ) then
                return true;
            end

            -- Prevent toggled off channels
            local Allowed = true;
            local Permission;
            if( ChannelId > 0 ) then
                Permission = Addon.APP:GetValue( 'Channels' )[ ChannelBaseName ] or false;

                if( not Permission ) then
                    if( Addon:Minify( ChannelBaseName ):find( 'trade' ) ) then
                        Permission = Addon.APP:GetValue( 'Channels' )[ 'Trade' ];
                    end
                end

                if( Permission and Permission.Allowed == false ) then
                    --print( 'blocking',ChannelBaseName )
                    Allowed = false;
                end

                -- Override for monitored messages
                if( Watched or Mentioned ) then
                    if( Addon.APP:GetValue( 'BypassTypes' ) ) then
                        Allowed = true;
                    end
                end

                if( not Allowed ) then
                    return true;
                end
            end

            -- Invite check
            if( ChatType == 'WHISPER' and Addon.APP:GetValue( 'AutoInvite' ) ) then
                if( Addon:Minify( OriginalText ) == 'inv' ) then
                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        Addon.FRAMES:Debug( 'jChat:App','found "inv"' );
                    end
                    if( GetNumGroupMembers and GetNumGroupMembers() > 4 ) then
                        if( Addon.APP:GetValue( 'Debug' ) ) then
                            Addon.FRAMES:Debug( 'jChat:App','GetNumGroupMembers',GetNumGroupMembers() );
                        end
                        if( ConvertToRaid ) then
                            ConvertToRaid();
                        elseif( C_PartyInfo and C_PartyInfo.ConvertToRaid ) then
                            C_PartyInfo:ConvertToRaid();
                        end
                    end
                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        print( 'jChat:App','Inviting Player',PlayerName );
                    end
                    InviteUnit( PlayerName );
                end
            end

            -- Watch check
            local Watched,Mentioned = false,false;
            local WatchedMessages = Addon.CONFIG:GetAlerts();
            if( #WatchedMessages > 0 ) then
                for i,WatchedMessage in ipairs( WatchedMessages ) do
                    if( Addon:Minify( OriginalText ):find( Addon:Minify( WatchedMessage ) ) ) then
                        Watched = '|Alert:'..WatchedMessage;
                    end
                end
            end
            if( Addon.APP:GetValue( 'QuestAlert' ) ) then
                for i,ActiveQuest in pairs( Addon.QUESTS.ActiveQuests ) do
                    if( Addon:Minify( OriginalText ):find( ActiveQuest ) ) then
                        Watched = '|Quest:'..ActiveQuest;
                    end
                end
            end
            local Prefix,ABBREV,Queued,_,_,_,Tank,Healer,DPS = strsplit( ':',MessageText );
            if( Addon.APP:GetValue( 'MentionAlert' ) ) then
                if( Addon:Minify( OriginalText ):find( Addon:Minify( MyPlayerName ) ) ) then
                    Mentioned = MyPlayerName;
                end
                if( Prefix and Prefix == Addon.DUNGEONS.PREFIX ) then
                    Mentioned = false;
                end
            end
            local AliasList = Addon.CONFIG:GetAliasList();
            if( #AliasList > 0 ) then
                for i,Alias in ipairs( AliasList ) do
                    if( Addon:Minify( OriginalText ):find( Addon:Minify( Alias ) ) ) then
                        Mentioned = Alias;
                    end
                end
                if( Prefix and Prefix == Addon.DUNGEONS.PREFIX ) then
                    Mentioned = false;
                end
            end

            -- Queue check
            local Dungeons = Addon.DUNGEONS:GetDungeonsF();
            for ABBREV,IsQueued in pairs( Addon.APP:GetDungeonQueue() ) do
                if( IsQueued ) then
                    for _,Abbrev in pairs( Dungeons[ ABBREV ].Abbrevs ) do
                        if( Addon:Minify( OriginalText ):find( Addon:Minify( Abbrev ) ) ) then
                            Watched = '|Dungeon:'..ABBREV..'|Abbrev:'..Abbrev;
                        end
                    end
                    if( Addon:Minify( OriginalText ):find( Addon:Minify( ABBREV ) ) ) then
                        Watched = '|Dungeon:'..ABBREV;
                    end
                end
            end
            local Raids = Addon.DUNGEONS:GetRaidsF();
            for ABBREV,IsQueued in pairs( Addon.APP:GetRaidQueue() ) do
                if( IsQueued ) then
                    for _,Abbrev in pairs( Raids[ ABBREV ].Abbrevs ) do
                        if( Addon:Minify( OriginalText ):find( Addon:Minify( Abbrev ) ) ) then
                            Watched = '|Raid:'..ABBREV..'|Abbrev:'..Abbrev;
                        end
                    end
                    if( Addon:Minify( OriginalText ):find( Addon:Minify( ABBREV ) ) ) then
                        Watched = '|Raid:'..ABBREV;
                    end
                end
            end

            -- Format message
            MessageText,r,g,b,a,id = Addon.APP.Format(
                Event,
                MessageText,
                PlayerRealm,
                LangHeader,
                ChannelNameId,
                PlayerName,
                GMFlag,
                Arg7,
                ChannelId,
                ChannelBaseName,
                UnUsed,
                LineId,
                PlayerId,
                BNId,
                Arg14,
                LBox,
                IconReplacement,
                Watched,
                Mentioned
            );

            -- Always sound whispers
            if ( ChatType == 'WHISPER' ) then
                PlaySound( SOUNDKIT.TELL_MESSAGE,Addon.APP:GetValue( 'AlertChannel' ) );
            end

            -- Whispers while afk
            if( ChatType == 'WHISPER' and Addon.APP.Notices[ Addon:Minify( MessageText ) ] ~= true ) then

                if( Addon.APP:GetValue( 'AFKAlert' ) and UnitIsAFK( 'player' ) ) then
                    local F = Addon.APP:GetAlertFrame( MessageText,'AFK-Whisper' );
                    local MentionDrop = Addon.APP:GetValue( 'MentionDrop' );
                    if( MentionDrop.x and MentionDrop.y ) then
                        F:SetPoint( MentionDrop.p,MentionDrop.x,MentionDrop.y );
                    else
                        F:SetPoint( 'center' );
                    end
                    AlertLayer = AlertLayer+1;
                    F:SetFrameLevel( AlertLayer );

                    F.Butt:HookScript( 'OnClick',function( self )
                        if( Addon.APP.Notices and Addon.APP.Notices[ Addon:Minify( MessageText ) ] ) then
                            Addon.APP.Notices[ Addon:Minify( MessageText ) ] = nil;
                        end
                        self:GetParent():Hide();
                    end );

                    Addon.APP.Notices[ Addon:Minify( MessageText ) ] = true;
                end
            end

            -- Mentions
            if( Mentioned and Addon.APP.Notices[ Addon:Minify( MessageText ) ] ~= true ) then

                if( Addon.APP:GetValue( 'MentionAlert' ) ) then
                    PlaySound( SOUNDKIT.TELL_MESSAGE,Addon.APP:GetValue( 'AlertChannel' ) );

                    local F = Addon.APP:GetAlertFrame( MessageText,'Mention' );
                    local MentionDrop = Addon.APP:GetValue( 'MentionDrop' );
                    if( MentionDrop.x and MentionDrop.y ) then
                        F:SetPoint( MentionDrop.p,MentionDrop.x,MentionDrop.y );
                    else
                        F:SetPoint( 'center' );
                    end
                    AlertLayer = AlertLayer+1;
                    F:SetFrameLevel( AlertLayer );

                    F.Butt:HookScript( 'OnClick',function( self )
                        if( Addon.APP.Notices and Addon.APP.Notices[ Addon:Minify( MessageText ) ] ) then
                            Addon.APP.Notices[ Addon:Minify( MessageText ) ] = nil;
                        end
                        self:GetParent():Hide();
                    end );

                    Addon.APP.Notices[ Addon:Minify( MessageText ) ] = true;
                end
            end

            Addon.CHAT.ChatFrame:AddMessage( MessageText,r,g,b,id );
            Addon.APP.Cache[ CacheKey ] = true;
            return true;
        end;

        --
        -- Set DB value
        --
        -- @return void
        Addon.APP.SetValue = function( self,Index,Value )
            Addon.DB:SetValue( Index,Value );
        end

        --
        -- Get DB value
        --
        -- @return mixed
        Addon.APP.GetValue = function( self,Index )
            return Addon.DB:GetValue( Index );
        end

        --
        -- Get dungeon queue
        --
        -- @return table
        Addon.APP.GetDungeonQueue = function( self )
            return Addon.DB:GetPersistence().DungeonQueue or {};
        end

        --
        -- Get raid queue
        --
        -- @return table
        Addon.APP.GetRaidQueue = function( self )
            return Addon.DB:GetPersistence().RaidQueue or {};
        end

        --
        --  Module init
        --
        --  @return void
        Addon.APP.Init = function( self )
            if( not Addon.DB:GetPersistence() ) then
                return;
            end

            -- Message cache
            self.Cache = {};

            -- Notice cache
            self.Notices = {};

            -- Chat text
            Addon.CHAT:SetFont( self:GetValue( 'Font' ),Addon.CHAT.ChatFrame);

            -- Fading
            Addon.CHAT:SetFading( self:GetValue( 'FadeOut' ),Addon.CHAT.ChatFrame );

            -- Scrolling
            Addon.CHAT:SetScrolling( self:GetValue( 'ScrollBack' ),Addon.CHAT.ChatFrame );

            -- Quests
            if( self:GetValue( 'QuestAlert' ) ) then
                Addon.QUESTS:EnableQuestEvents();
            else
                Addon.QUESTS:DisableQuestEvents();
            end
            Addon.QUESTS:RebuildQuests();
            --[[
            Addon:Dump( {
                ActiveQuests = Addon.QUESTS.ActiveQuests,
            } );
            ]]

            -- Chat link clicks
            hooksecurefunc( 'SetItemRef',function( Pattern,FullText )
                local linkType,ThisAddon,Param = strsplit( ':',Pattern );
                if( linkType == 'addon' and ThisAddon == 'jChat' ) then
                    if( Param == 'url' ) then
                        local EditBox = ChatEdit_ChooseBoxForSend( Addon.CHAT.ChatFrame );
                        ChatEdit_ActivateChat( EditBox );
                        EditBox:SetText( FullText:match( ">(.-)<" ) );
                    end
                end
            end );

            -- Chat types
            for Group,GroupData in pairs( Addon.CONFIG:GetMessageGroups() ) do
                for _,GroupName in pairs( GroupData ) do
                    -- Always allow outgoing whispers
                    if( Addon:Minify( GroupName ):find( 'whisperinform' ) ) then
                        Addon.CHAT:SetGroup( GroupName,true );
                    -- Respect checked options
                    else
                        local Groups = self:GetValue( 'ChatGroups' );
                        if( Groups ) then
                            local Boolean = Groups[ Group ];
                            Addon.CHAT:SetGroup( GroupName,Boolean );
                            ToggleChatColorNamesByClassGroup( Groups[ Group ],GroupName );
                        end
                    end
                end
            end

            -- Chat filter
            for Filter,FilterData in pairs( Addon.CONFIG:GetChatFilters() ) do
                for _,FilterName in pairs( FilterData ) do
                    local Filters = self:GetValue( 'ChatFilters' );
                    if( Filters ) then
                        self:SetFilter( FilterName,Filters[ Filter ] );
                    end
                end
            end

            -- Communities
            local Clubs = C_Club.GetSubscribedClubs();
            for i,Club in pairs( Clubs ) do
                if( Club.clubType ~= 2 ) then -- guild
                    local ClubStreams = C_Club.GetStreams( Club.clubId );
                    local ClubInfo = C_Club.GetClubInfo( Club.clubId );
                    for v,Stream in pairs( ClubStreams ) do
                        if( Stream.streamId ) then
                            Addon.CHAT:InitCommunity( Addon.CHAT.ChatFrame,Club.clubId,Stream.streamId );
                        end
                    end
                end
            end

            -- List channels
            for i,Channel in pairs( Addon.CHAT:GetChannels() ) do
                Channel.Name = Addon.CHAT:GetClubName( Channel.Name ) or Channel.Name;

                -- club
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

                local ChannelLink = Channel.Id..')'..Channel.Name;
                if( tonumber( Channel.Id ) > 0 ) then
                    ChannelLink = "|Hchannel:channel:"..Channel.Id.."|h[["..Channel.Id..']'..Channel.Name.."]|h"    -- "|Hchannel:channel:2|h[2. Trade - City]|h"s
                end

                local r,g,b,a,id = 1,1,1,1,nil;
                local Channels = Addon.DB:GetPersistence().Channels;
                if( tonumber( Channel.Id ) > 0 ) then
                    if( Channels[ Channel.Name ] and Channels[ Channel.Name ].Color ) then
                        r,g,b,a = unpack( Channels[ Channel.Name ].Color );
                    end
                end

                Addon.CHAT.ChatFrame:AddMessage( 'You have joined '..ChannelLink,r,g,b,a,id );
            end

            -- Requeue
            --[[
                    -- blizz disabled this functionality

                    -- see Dungeons:OnCommReceived() for more details

            C_Timer.After( 5,function()
                for ABBREV,Instance in pairs( Addon.DUNGEONS:GetDungeonsF( UnitLevel( 'player' ) ) ) do
                    if( Addon.DB:GetPersistence().DungeonQueue[ ABBREV ] ) then
                        local ReqLevel = Addon.DUNGEONS:GetDungeons()[ ABBREV ].LevelBracket[1];
                        local Roles = Addon.DB:GetPersistence().Roles;
                        local Queued = Addon.DB:GetPersistence().DungeonQueue[ ABBREV ] or false;

                        Addon.DUNGEONS:SendAddonMessage( ABBREV,ReqLevel,Roles,Queued );
                    end
                end
            end );
            ]]

            -- Config callbacks
            Addon.CONFIG:RegisterCallbacks();
            Addon.CHAT:RegisterCallbacks();

            Addon.FRAMES:Notify( 'Done' );
        end

        Addon.FRAMES:Notify( 'Prepping...please wait' );
        Addon.APP:RegisterEvent( 'PLAYER_LOGIN' );
        Addon.APP:HookScript( 'OnEvent',function( self,Event,AddonName )
            if( Event == 'PLAYER_LOGIN' ) then
                C_Timer.After( 5,function()
                    Addon.DB:Init();
                    --Addon.DB:Reset();
                    Addon.CHAT:Init();
                    Addon.CONFIG:Init();
                    Addon.APP:Init();
                    Addon.APP:UnregisterEvent( 'PLAYER_LOGIN' );
                end );
            end
        end );
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );