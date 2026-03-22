local _, Addon = ...;
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
local JoinPermanentChannel = JoinPermanentChannel;
local LeaveChannelByName = LeaveChannelByName;
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS;
local GetChannelList = GetChannelList;
local CreateColor = CreateColor;
local ChangeChatColor = ChangeChatColor;
local C_Club = C_Club;
local CURRENT_CHAT_FRAME_ID = CURRENT_CHAT_FRAME_ID;
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK;
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame;

Addon.CHAT = CreateFrame( 'Frame' );
Addon.CHAT:RegisterEvent( 'ADDON_LOADED' );
Addon.CHAT:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jChat' ) then

        --
        --  Get default channel colors
        --
        --  @return table
        Addon.CHAT.GetBaseColor = function( self )
            return {
                254 / 255,
                191 / 255,
                191 / 255,
                1,
            };
        end

        --
        --  Is channel joined
        --
        --  @param  string  ChannelName
        --  @return bool
        Addon.CHAT.IsChannelJoined = function( self,ChannelName )
            if( Addon.CONFIG:GetValue( 'Debug' ) ) then
                Addon:Dump( FCF_GetCurrentChatFrame().channelList );
            end

            for Id,Name in pairs( FCF_GetCurrentChatFrame().channelList ) do
                if( Addon:Minify( ChannelName ) == Addon:Minify( Name ) ) then
                    return true;
                end
            end
        end

        --
        --  Join channel
        --  @todo blizz does not expose JoinChannel or LeaveChannel source code. as such, 
        --  i see no clear way to manage joined and left channels in a precise ordering.
        --  for now, this function should not be used until it can be updated to truly allow 
        --  joining a channel in specifc order
        --
        --  @return bool
        Addon.CHAT.JoinChannel = function( self,ChannelName,ChannelId )
            if( ChannelName ) then
                local Type,Name = JoinPermanentChannel( ChannelName );

                local NumEntries = #FCF_GetCurrentChatFrame().channelList or 0;

                local PreviousEntry = FCF_GetCurrentChatFrame().channelList[tonumber( ChannelId )] or nil;

                FCF_GetCurrentChatFrame().channelList[tonumber( ChannelId )] = ChannelName;

                if( PreviousEntry ) then
                    FCF_GetCurrentChatFrame().channelList[NumEntries+1] = PreviousEntry
                end
                if( Addon.CONFIG:GetValue( 'Debug' ) ) then
                    Addon.FRAMES:Debug( 'Joined',ChannelName,'Position',tonumber( ChannelId ) );
                end
                return Addon:Minify( FCF_GetCurrentChatFrame().channelList[tonumber( ChannelId )] ) == Addon:Minify( ChannelName );
            end
        end

        --
        --  Leave channel
        --
        --  @return void
        Addon.CHAT.LeaveChannelByName = function( self,ChannelName )
            if( ChannelName ) then
                if( self:IsChannelJoined( ChannelName ) ) then

                    local ChannelId = self:GetChannelId( ChannelName );

                    if( tonumber( ChannelId ) > 0 ) then
                        LeaveChannelByName( ChannelName );
                        FCF_GetCurrentChatFrame().channelList[tonumber( ChannelId )] = nil;
                    end
                end
            end
        end

        --
        --  Get channel id
        --
        --  @param  string  ChannelName
        --  @return int
        Addon.CHAT.GetChannelId = function( self,ChannelName )
            for Id,Name in pairs( FCF_GetCurrentChatFrame().channelList ) do
                if( Addon:Minify( ChannelName ) == Addon:Minify( Name ) ) then
                    return Id;
                end
            end
        end

        --
        --  Get channel name
        --
        --  @param  string  Id
        --  @return int
        Addon.CHAT.GetChannelName = function( self,ChannelId )
            for Id,Name in pairs( FCF_GetCurrentChatFrame().channelList ) do
                if( tonumber( Id ) == tonumber( ChannelId ) ) then
                    return Name;
                end
            end
        end

        --
        --  Get GetChannelList() results
        --
        --  @return table
        Addon.CHAT.GetChannels = function( self )
            local ChannelList = {};
            local Channels = { GetChannelList() };
            for i = 1,#Channels,3 do
                local Club;
                local ClubData = Addon:Explode( Channels[i+1],':' );
                if( ClubData and tonumber( #ClubData ) > 0 ) then
                    local ClubId = ClubData[2] or 0;
                    if( tonumber( ClubId ) > 0 ) then
                        Club = C_Club.GetClubInfo( ClubId );
                    end
                end
                local LongName = Channels[i+1];
                if( Club ) then
                    LongName = Club.name;
                    LongName = LongName:gsub( '%s+','' );
                end

                ChannelList[ i ] = {
                    Id = Channels[i],
                    Name = Channels[i+1],
                    LongName = LongName,
                    Disabled = Channels[i+2],
                    Color = self:GetBaseColor(),
                };
            end
            return ChannelList;
        end

        --
        --  Get club name
        --
        --  @param  string  ChannelName
        --  @return string
        Addon.CHAT.GetClubName = function( self,ChannelName )
            local ClubData = Addon:Explode( ChannelName,':' );
            if( ClubData and tonumber( #ClubData ) > 0 ) then
                local ClubId = ClubData[2] or 0;
                return Addon.CHAT:GetClubNameForId( ClubId );
            end
        end

        --
        --  Get club name for ID
        --
        --  @param  string  ChannelName
        --  @return string
        Addon.CHAT.GetClubNameForId = function( self,ClubId )
            if( ClubId ) then
                local ClubInfo = C_Club.GetClubInfo( ClubId );
                if( ClubInfo ) then
                    local Name = ClubInfo.shortName;
                    return Name:gsub( '%s+','' );
                end
            end
        end

        -- @todo: review GetClubName and how it functions here
        -- functionality may have gotten broken. check on this
        Addon.CHAT.InitCommunity = function( self,ChatFrame,ClubId,StreamId )
            C_Club.AddClubStreamChatChannel( ClubId,StreamId );
            
            local ChannelName = Chat_GetCommunitiesChannelName( ClubId,StreamId );
            
            local ChannelColor = CreateColor( unpack( self:GetBaseColor() ) );

            local SetEditBoxToChannel;

            local function ChatFrame_AddCommunitiesChannel(chatFrame, channelName, channelColor, setEditBoxToChannel)
                local channelIndex = chatFrame:AddChannel(channelName);
                chatFrame:AddMessage(COMMUNITIES_CHANNEL_ADDED_TO_CHAT_WINDOW:format(channelIndex, ChatFrame_ResolveChannelName(channelName)), channelColor:GetRGB());

                if setEditBoxToChannel then
                    chatFrame.editBox:SetAttribute("channelTarget", channelIndex);
                    chatFrame.editBox:SetAttribute("chatType", "CHANNEL");
                    chatFrame.editBox:SetAttribute("stickyType", "CHANNEL");
                    ChatEdit_UpdateHeader(chatFrame.editBox);
                end
            end

            local Found;
            local NewInfo = C_Club.GetClubInfo( ClubId );
            for ChannelId,CName in pairs( ChatFrame.channelList ) do

                local OldName = self:GetClubName( CName );
                NewInfo.name = NewInfo.name;
                NewInfo.name = NewInfo.name:gsub( '%s+','' );

                if( NewInfo and NewInfo.name and OldName ) then

                    local ClubStreams = C_Club.GetStreams( NewInfo.clubId );
                    if( ClubStreams ) then
                        for v,Stream in pairs( ClubStreams ) do
                            if( Stream.streamId ) then
                                if( OldName == NewInfo.name and Stream.streamId == StreamId ) then
                                    Found = true;
                                end
                            end
                        end
                    end
                end
            end
            if( not Found ) then
                ChatFrame_AddCommunitiesChannel( ChatFrame,ChannelName,ChannelColor,SetEditBoxToChannel );
            end
        end

        Addon.CHAT.GetChannelLink = function( self,... )
            local ChannelId,ChannelBaseName,ChatType = ...;

            local Format;
            if( tonumber( ChannelId ) > 0 ) then
                Format = "|Hchannel:channel:%s|h[%s]%s|h";
                return string.format( Format,ChannelId,ChannelId,ChannelBaseName );
            else
                Format = "|Hchannel:%s|h[%s]|h";
                return string.format( Format,ChatType,ChatType );
            end
        end

        --
        -- Set chat group
        --
        -- @return void
        Addon.CHAT.SetGroup = function( self,Group,Value )
            if ( Value ) then
                ChatFrame_AddMessageGroup( FCF_GetCurrentChatFrame(),Group );
            else
                ChatFrame_RemoveMessageGroup( FCF_GetCurrentChatFrame(),Group );
            end
        end

        --
        --  Module init
        --
        --  @return void
        Addon.CHAT.Init = function( self )
            -- Current Selected Chat Tab
            -- Blizz Code Relies on CURRENT_CHAT_FRAME_ID
            -- /Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua
            local SelectedFrame = FCFDock_GetSelectedWindow( GENERAL_CHAT_DOCK );
            if( SelectedFrame ) then
                CURRENT_CHAT_FRAME_ID = SelectedFrame:GetID();
            else
                CURRENT_CHAT_FRAME_ID = DEFAULT_CHAT_FRAME:GetID();
            end

            -- Update Channel Colors from DB
            for _,Channel in pairs( Addon.DB:GetPersistence().Channels ) do
                if( Channel.Id ) then
                    ChangeChatColor( 'CHANNEL'..Channel.Id,unpack( Channel.Color ) );
                end
            end

            -- Hook All Messages
            self.Hooks = {};
            for i = 1, 10 do
                local Frame = _G[ 'ChatFrame'..i ];
                if( Frame ) then
                    self.Hooks[ Frame ] = Frame.AddMessage;
                    Frame.AddMessage = Addon.APP.AddMessage;
                end
            end

            -- Font
            for i = 1, 10 do
                local Frame = _G[ 'ChatFrame'..i ];
                if( Frame ) then
                    hooksecurefunc( Frame,'SetFont',function( self,FontPath,FontSize )
                        local Font = Addon.CONFIG:GetValue( 'Font' );

                        if( not FontPath:find( Font.Family ) ) then
                            C_Timer.After(0, function()
                                Frame:SetFont( 'Fonts\\'..Font.Family..'.ttf',Font.Size,Font.Flags );
                                Frame:SetShadowColor( Font.Shadow.Color.r,Font.Shadow.Color.g,Font.Shadow.Color.b,Font.Shadow.Color.a );
                                Frame:SetShadowOffset( Font.Shadow.Offset.x,Font.Shadow.Offset.x );
                            end );
                        end
                    end );
                end
            end

            -- Fading
            for i = 1, 10 do
                local Frame = _G[ 'ChatFrame'..i ];
                if( Frame ) then
                    local MyValue = Addon.CONFIG:GetValue( 'FadeOut' );
                    hooksecurefunc( Frame,'SetFading',function( self,YourValue )

                        if( not YourValue == MyValue ) then
                            C_Timer.After(0, function()
                                Frame:SetFading( MyValue );
                            end );
                        end
                    end );
                    Frame:SetFading( MyValue );
                end
            end

            -- Scrolling
            for i = 1, 10 do
                local Frame = _G[ 'ChatFrame'..i ];
                if( Frame ) then
                    local MyValue = Addon.CONFIG:GetValue( 'ScrollBack' );
                    hooksecurefunc( Frame,'SetFading',function( self,YourValue )

                        if( not YourValue == MyValue ) then
                            C_Timer.After(0, function()
                                if( MyValue ) then
                                    Frame:SetMaxLines( 10000 );
                                else
                                    Frame:SetMaxLines( 128 );
                                end
                            end );
                        end
                    end );
                    if( MyValue ) then
                        Frame:SetMaxLines( 10000 );
                    else
                        Frame:SetMaxLines( 128 );
                    end
                end
            end
        end

        Addon.CHAT.RegisterCallbacks = function( self )
            -- Join Channel
            hooksecurefunc( 'JoinPermanentChannel',function( ChannelName,Password,FrameId,Voice )
                if( not Addon.DB:GetPersistence().Channels[ ChannelName ] ) then
                    Addon.DB:GetPersistence().Channels[ ChannelName ] = {};
                    for Id,ChannelData in pairs( self:GetChannels() ) do
                        if( ChannelData.Name == ChannelName ) then
                            Addon.DB:GetPersistence().Channels[ ChannelName ].Id = ChannelData.Id;
                        end
                    end
                    Addon.DB:GetPersistence().Channels[ ChannelName ].Color = self:GetBaseColor();
                    Addon.DB:GetPersistence().Channels[ ChannelName ].Allowed = true;
                end
            end );
            -- Leave Channel
            hooksecurefunc( 'LeaveChannelByName',function( ChannelName )
                if( ChannelName ) then
                    if( Addon.DB:GetPersistence().Channels[ ChannelName ] ) then
                        Addon.DB:GetPersistence().Channels[ ChannelName ] = nil;
                    end
                end
            end );
            -- Editbox Focus
            FCF_GetCurrentChatFrame().editBox:HookScript( 'OnEditFocusGained',function( self,... )

                local ChannelId = self:GetAttribute( 'channelTarget' );
                local ChannelName = Addon.CHAT:GetChannelName( ChannelId );
                local DBChannels = Addon.DB:GetPersistence().Channels;

                for i,v in pairs( DBChannels ) do
                    if( v and v.Id and ChannelId == v.Id ) then
                        if( v.Name ) then
                            self:SetTextColor( unpack( DBChannels[ v.Name ].Color ) );
                        end
                    end
                end
            end );
            -- New Chat Tab
            -- Unfortunately, FCF_OpenNewWindow and FCF_DockFrame does not work for this
            -- that seems super strange to me
            -- so this is a hack
            hooksecurefunc( 'FCF_SetChatWindowFontSize',function( self,Frame,FontSize )
                local Frame = Frame or self;

                -- Fading
                local MyValue = Addon.CONFIG:GetValue( 'FadeOut' );
                Frame:SetFading( MyValue );

                -- Scrolling
                local MyValue = Addon.CONFIG:GetValue( 'ScrollBack' );
                if( MyValue ) then
                    Frame:SetMaxLines( 10000 );
                else
                    Frame:SetMaxLines( 128 );
                end

                -- Scrolling
                local Font = Addon.CONFIG:GetValue( 'Font' );
                Frame:SetFont( 'Fonts\\'..Font.Family..'.ttf',Font.Size,Font.Flags );
                Frame:SetShadowColor( Font.Shadow.Color.r,Font.Shadow.Color.g,Font.Shadow.Color.b,Font.Shadow.Color.a );
                Frame:SetShadowOffset( Font.Shadow.Offset.x,Font.Shadow.Offset.x );

            end );
        end

        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );