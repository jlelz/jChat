local _,Library = ...;

local ADDON = LibStub( 'AceAddon-3.0' ):GetAddon( 'jChat' )
local DB = ADDON:GetModule( 'database' )
local CHATFRAME = ADDON:NewModule( 'chatframe','AceHook-3.0' )

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
local ChatFrame = DEFAULT_CHAT_FRAME;

local GetChannelList = GetChannelList
local ChangeChatColor = ChangeChatColor
local C_Club = C_Club

--
--  Get default channel colors
--
--  @return table
function CHATFRAME:GetBaseColor()
    return {
        254 / 255,
        191 / 255,
        191 / 255,
        1,
    }
end

--
--  Get channel name
--
--  @param  string  Id
--  @return int
function CHATFRAME:GetChannelName( ChannelId )
    local FrameChannels = CHATFRAME:GetChannels()

    for _,ChannelData in pairs( FrameChannels ) do
        if( tonumber( ChannelId ) == tonumber( ChannelData.Id ) ) then
            return ChannelData.Name
        end
    end
end

--
--  Get channel id
--
--  @param  string  ChannelName
--  @return int
function CHATFRAME:GetChannelId( ChannelName )
    local FrameChannels = CHATFRAME:GetChannels()

    for _,ChannelData in pairs( FrameChannels ) do
        if( Addon:Minify( ChannelName ) == Addon:Minify( ChannelData.Name ) ) then
            return Id
        end
    end
end

--
--  Get club name for ID
--
--  @param  string  ChannelName
--  @return string
function CHATFRAME:GetClubNameForId( ClubId )
    if( ClubId ) then
        local ClubInfo = C_Club.GetClubInfo( ClubId )
        if( ClubInfo ) then
            local Name = ClubInfo.shortName
            return Name:gsub( '%s+','' )
        end
    end
end

--
--  Get club name
--
--  @param  string  ChannelName
--  @return string
function CHATFRAME:GetClubName( ChannelName )
    local ClubData = Library:Explode( ChannelName,':' )
    if( ( ClubData ) and ( tonumber( #ClubData ) > 0 ) ) then
        local ClubId = ClubData[2] or 0
        return self:GetClubNameForId( ClubId )
    end
end

--
--  Get GetChannelList() results
--
--  @return table
function CHATFRAME:GetChannels()
    local ChannelList = {}
    local Channels = { GetChannelList() }
    for i=1,#Channels,3 do

        local LongName = Channels[ i+1 ]
        local ClubName = self:GetClubName( LongName )
        if( ClubName ) then
            LongName = ClubName
        end

        ChannelList[ i ] = {
            Id = Channels[ i ],
            Name = LongName,
            LongName = LongName,
            Disabled = Channels[ i+2 ],
            Color = self:GetBaseColor(),
            Allowed = true,
        }

    end
    return ChannelList;
end

function CHATFRAME:GetChannelLink( ... )
    local ChannelId,ChannelBaseName,ChatType = ...

    local Format
    if( tonumber( ChannelId ) > 0 ) then
        Format = "|Hchannel:channel:%s|h[%s]%s|h"
        return string.format( Format,ChannelId,ChannelId,ChannelBaseName )
    else
        Format = "|Hchannel:%s|h[%s]|h"
        return string.format( Format,ChatType,ChatType )
    end
end

function CHATFRAME:GetBNetPlayerLink( ... )
    local BNetIDAccount,AccountName = ...
    
    local Format = "|HBNplayer:%d|h[%s]|h"
    return string.format( Format,tonumber( BNetIDAccount ) or 0,AccountName or 'Unknown Friend' )
end

function CHATFRAME:GetBNetChannelLink( ... )
    local ClubId,ClubChannelId,ClubName,ChatType = ...

    local Format
    if( ClubId and ClubChannelId ) then
        Format = "|Hchannel:club:%s:%s|h[%s]|h"
        return string.format( Format,tostring( ClubId ),tostring( ClubChannelId ),tostring( ClubName ) )
    else
        Format = "|Hchannel:%s|h[%s]|h"
        return string.format( Format,tostring( ChatType ),tostring( ChatType ) )
    end
end

function CHATFRAME:GetClubChannelLink( ... )
    local ClubId,ChannelId,ClubName = ...

    local Format = "|Hchannel:club:%s:%s|h[%s]|h"
    return string.format( Format,tostring( ClubId ),tostring( ChannelId ),ClubName or 'Community' )
end

function CHATFRAME:GetClubInviteLink( ... )
    local InviteCode,CommunityName = ...

    -- Format: |Hclubfinder:invite:code|h[Community: Name]|h
    -- This string is what triggers the 'Join Community' confirmation dialog when clicked
    local Format = "|Hclubfinder:invite:%s|h[%s]|h"
    return string.format( Format,tostring( InviteCode ),CommunityName or 'Join Community' )
end

function CHATFRAME:ApplyChatColors()
    local FrameChannels,DBChannels = self:GetChannels(),DB:GetPersistence().Channels

    for Id,ChannelData in pairs( FrameChannels ) do
        for _,Channel in pairs( DBChannels ) do
            if( DBChannels[ ChannelData.Name ] and DBChannels[ ChannelData.Name ].Id ) then
                if( DBChannels[ ChannelData.Name ].Color ) then
                    local R,G,B,A = unpack( DBChannels[ ChannelData.Name ].Color )
                    ChangeChatColor( 'CHANNEL'..ChannelData.Id,R,G,B,true )
                end
            end
        end
    end
end

function CHATFRAME:RefreshChannels()
    local FrameChannels,DBChannels = self:GetChannels(),self:GetChannels()

    for Id,ChannelData in pairs( FrameChannels ) do
        for _,Channel in pairs( DBChannels ) do
            if( not DB:GetPersistence().Channels[ ChannelData.Name ] ) then
                DB:GetPersistence().Channels[ ChannelData.Name ] = {
                    Allowed = ChannelData.Allowed,
                    Id = ChannelData.Id,
                    Color = ChannelData.Cololr,
                    Name = ChannelData.Name,
                    LongName = ChannelData.LongName,
                    Disabled = ChannelData.Disabled,
                }
            end
        end 
    end
end

--
--  Is channel joined
--
--  @param  string  ChannelName
--  @return bool
function CHATFRAME:IsChannelJoined( ChannelName )
    if( DB:GetDBValue( 'Debug' ) ) then
        Library:Dump( ChatFrame.channelList );
    end

    for _,ChannelData in pairs( self:GetChannels() ) do
        if( Library:Minify( ChannelName ) == Library:Minify( ChannelData.Name ) ) then
            return true;
        end
    end
end

function CHATFRAME:RegisterCallbacks()
    self:SecureHook( 'JoinPermanentChannel',function( ChannelName,Password,FrameId,Voice )
        -- Add DB entry
        self:RefreshChannels()

        -- Respect ClassColors pref
        if( DB:GetPersistence().Channels[ ChannelName ] ) then
            local ChannelId = DB:GetPersistence().Channels[ ChannelName ].Id;
            if( ChannelId ) then
                ToggleChatColorNamesByClassGroup( DB:GetPersistence().ClassColors,tostring( 'CHANNEL'..ChannelId ) );
            end
            if( DB:GetDBValue( 'Debug' ) ) then
                Library:Dump( DB:GetPersistence().Channels[ ChannelName ] )
            end
        end
    end )
    self:SecureHook( 'LeaveChannelByName',function( ChannelName )
        -- Reemove DB entry
        if( ChannelName ) then
            if( DB:GetPersistence().Channels[ ChannelName ] ) then
                DB:GetPersistence().Channels[ ChannelName ] = nil;
            end
        end
    end )
    self:SecureHook( 'SetItemRef',function( Pattern,FullText )
        local linkType,addon,param1 = strsplit( ':',Pattern );
        print( addon )
        if( linkType == 'addon' and addon == 'jChat' ) then
            if( param1 == 'url' ) then
                local Frame = _G[ 'ChatFrame'..1 ];
                if( Frame ) then
                    Frame.editBox:SetText( FullText:match( ">(.-)<" ) );

                    ChatEdit_ActivateChat( Frame.editBox );
                    
                    Frame.editBox:HighlightText();
                end
            end
        end
    end );

    ChatFrame.editBox:HookScript( 'OnEditFocusGained',function( self,... )
        local ChannelId = self:GetAttribute( 'channelTarget' );
        local ChannelName = CHATFRAME:GetChannelName( ChannelId );
        local DBChannels = DB:GetPersistence().Channels;

        for i,v in pairs( DBChannels ) do
            if( v and v.Id and ChannelId == v.Id ) then
                if( v.Name ) then
                    self:SetTextColor( unpack( DBChannels[ v.Name ].Color ) );
                end
            end
        end
    end );

    self:SecureHook( 'FCF_SetChatWindowFontSize',function( self,Frame,FontSize )
        local Font = DB:GetDBValue( 'Font' );
        C_Timer.After(0, function()
            if( DB.FONTS[ Font.Family ] ) then
                Frame:SetFont( Addon.DB.FONTS[ Font.Family ],Font.Size,Font.Flags );
            end
            Frame:SetShadowColor( Font.Shadow.Color.r,Font.Shadow.Color.g,Font.Shadow.Color.b,Font.Shadow.Color.a );
            Frame:SetShadowOffset( Font.Shadow.Offset.x,Font.Shadow.Offset.x );
        end );
    end );

    self:SecureHook( 'FCF_CopyChatSettings',function( NewFrame,ExistingFrame )
        local Frame = NewFrame;

        -- Fading
        local MyValue = DB:GetDBValue( 'FadeOut' );
        Frame:SetFading( MyValue );

        -- Scrolling
        local MyValue = DB:GetDBValue( 'ScrollBack' );
        if( MyValue ) then
            Frame:SetMaxLines( 10000 );
        else
            Frame:SetMaxLines( 128 );
        end

        -- Font
        local Font = DB:GetDBValue( 'Font' );
        if( DB.FONTS[ Font.Family ] ) then
            Frame:SetFont( DB.FONTS[ Font.Family ],Font.Size,Font.Flags );
        end
        Frame:SetShadowColor( Font.Shadow.Color.r,Font.Shadow.Color.g,Font.Shadow.Color.b,Font.Shadow.Color.a );
        Frame:SetShadowOffset( Font.Shadow.Offset.x,Font.Shadow.Offset.x );
    end );

    self:SecureHook( 'FCF_ResetAllWindows',function()
        -- Colors
        CHATFRAME:ApplyChatColors();

        -- Font
        for i = 1, 10 do
            local Frame = _G[ 'ChatFrame'..i ];
            if( Frame and DB:GetPersistence().Font[ Info.arg ] ~= nil ) then
                DB:GetPersistence().Font[ Info.arg ] = Value

                local Font = DB:GetDBValue( 'Font' )
                if( DB.FONTS[ Font.Family ] ) then
                    Frame:SetFont( DB.FONTS[ Font.Family ],Font.Size,Font.Flags )
                end

                if( Frame.RefreshLayout ) then
                    Frame:RefreshLayout()
                end
            end
        end

        -- Fading
        for i = 1, 10 do
            local Frame = _G[ 'ChatFrame'..i ];
            if( Frame ) then
                if( Value and DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    DB:GetPersistence()[ Info.arg ] = Value

                    Frame:SetFading( true );
                elseif( not Value and DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    DB:GetPersistence()[ Info.arg ] = Value

                    Frame:SetFading( false );
                end
            end
        end

        -- Scrolling
        for i = 1, 10 do
            local Frame = _G[ 'ChatFrame'..i ]
            if( Frame ) then
                if( Value and DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    DB:GetPersistence()[ Info.arg ] = Value

                    Frame:SetMaxLines( 10000 )
                elseif( not Value and DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    DB:GetPersistence()[ Info.arg ] = Value

                    Frame:SetMaxLines( 128 )
                end
            end
        end
    end );

    self:SecureHook( 'ChangeChatColor',function( ChannelName,R,G,B,Internal )
        if( not Internal ) then
            if( DB:GetPersistence().Channels[ ChannelName ] ) then
                DB:GetPersistence().Channels[ ChannelName ].Color = R,G,B;
            end
        end
    end );
    self:SecureHook( 'ToggleChatColorNamesByClassGroup',function( Checked,Group,Internal )
        if( not Internal ) then
            -- We don't care
        end
    end );

    self:SecureHook( 'ToggleChatMessageGroup',function( Checked,Group )
        if( ChatFrame_ContainsMessageGroup and ChatFrame_ContainsMessageGroup( ChatFrame,Group ) ~= nil ) then
            if( DB:GetPersistence().ChatGroups[ Group ] ~= nil ) then
                DB:GetPersistence().ChatGroups[ Group ] = Checked;
            end
        end
    end );
end

function CHATFRAME:RefreshFont()
    for i = 1, 10 do
        local Frame = _G[ 'ChatFrame'..i ];
        local Font = DB:GetDBValue( 'Font' );

        if( Frame and Font ) then
            C_Timer.After(0, function()
                if( DB.FONTS[ Font.Family ] ) then
                    Frame:SetFont( DB.FONTS[ Font.Family ],Font.Size,Font.Flags );
                end

                if( Frame.RefreshLayout ) then
                    Frame:RefreshLayout();
                end
            end )
        end
    end
end

function CHATFRAME:RefreshFade()
    for i = 1, 10 do
        local Frame = _G[ 'ChatFrame'..i ];
        local Fade = DB:GetDBValue( 'FadeOut' );

        if( Fade ~= nil ) then
            C_Timer.After(0, function()
                if( Frame and Fade ) then
                    Frame:SetFading( Fade );
                end
            end )
        end
    end
end

function CHATFRAME:RefreshScroll()
    for i = 1, 10 do
        local Frame = _G[ 'ChatFrame'..i ];
        local Scroll = DB:GetDBValue( 'ScrollBack' );

        if( Frame ) then
            C_Timer.After(0, function()
                if( Scroll ) then
                    Frame:SetMaxLines( 10000 );
                else
                    Frame:SetMaxLines( 128 );
                end
            end )
        end
    end
end

function CHATFRAME:Refresh()
    self:RefreshFont()
    self:RefreshFade()
    self:RefreshScroll()
end

function CHATFRAME:OnEnable()
    self.Hooks = {};
    self:RefreshChannels()
    self:ApplyChatColors()
    self:RegisterCallbacks()
end