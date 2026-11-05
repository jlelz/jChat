local _,Library = ...;

local ADDON = LibStub( 'AceAddon-3.0' ):GetAddon( 'jChat' )
local DB = ADDON:GetModule( 'database' )
local CHATFRAME = ADDON:GetModule( 'chatframe' )
local CONFIG,NAME = ADDON:NewModule( 'config','AceConsole-3.0' ),'jChat'

function CONFIG:GetChannels()
  	return DB:GetPersistence().Channels
end

--
-- Set watch list
--
-- @param string
--
-- @return void
function CONFIG:SetAlerts( Watch )
    Watch = Library:Explode( Watch,',' );
    if( type( Watch ) == 'table' ) then
        DB:GetPersistence().AlertList = {};
        for i,v in pairs( Watch ) do
            if( string.len( v ) > 0 ) then
                table.insert( DB:GetPersistence().AlertList,Library:Minify( v ) );
            end
        end
    else
        DB:GetPersistence().AlertList = { Library:Minify( Watch ) };
    end
end

--
-- Get watch list
--
-- @return table
function CONFIG:GetAlerts()
    return DB:GetPersistence().AlertList;
end

--
-- Set ignore list
--
-- @param string
--
-- @return void
function CONFIG:SetIgnores( Ignore )
    Ignore = Library:Explode( Ignore,',' );
    if( type( Ignore ) == 'table' ) then
        DB:GetPersistence().IgnoreList = {};
        for i,v in pairs( Ignore ) do
            if( string.len( v ) > 0 ) then
                table.insert( DB:GetPersistence().IgnoreList,Library:Minify( v ) );
            end
        end
    else
        DB:GetPersistence().IgnoreList = { Library:Minify( Ignore ) };
    end
end

--
-- Get ignore list
--
-- @return table
function CONFIG:GetIgnores()
    return DB:GetPersistence().IgnoreList;
end

--
-- Set alias list
--
-- @param string
--
-- @return void
function CONFIG:SetAliasList( Alias )
    Alias = Library:Explode( Alias,',' );
    if( type( Alias ) == 'table' ) then
        DB:GetPersistence().AliasList = {};
        for i,v in pairs( Alias ) do
            if( string.len( v ) > 0 ) then
                table.insert( DB:GetPersistence().AliasList,Library:Minify( v ) );
            end
        end
    else
        DB:GetPersistence().AliasList = { Library:Minify( Alias ) };
    end
end

--
-- Get alist list
--
-- @return table
function CONFIG.GetAliasList()
    return DB:GetPersistence().AliasList;
end

function CONFIG:WindowOps()
	return {
        FirstSeparator = {
            type = 'header',
            order = 0,
            name = 'FONTS',
        },
		FontFamily = {
			order = 1,
            type = 'select',
            name = 'Font Family',
            desc = 'Chat Font Family',
            arg = 'Family',
			get = function( Info )
			    if( DB:GetPersistence().Font[ Info.arg ] ~= nil ) then
			        return DB:GetPersistence().Font[ Info.arg ]
			    end
			end,
            set = function( Info,Value )
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
            end,
            values = {
                skurri = 'skurri',
                Enigmatic = 'Enigmatic',
                ARIALN = 'ARIALN',
                MORPHEUS = 'MORPHEUS',
                FRIZQT__ = 'FRIZQT__',
            },
		},
		FontShadow = {
			order = 2,
            name = 'Font Shadow Color',
            desc = 'Chat Font text shadow color',
            type = 'color',
            get = function( Info )
                if( DB:GetPersistence().Font.Shadow.Color ~= nil ) then
                    local Color = DB:GetPersistence().Font.Shadow.Color
                    return Color.r,Color.g,Color.b,Color.a
                end
            end,
            set = function( Info,R,G,B,A )

                for i = 1, 10 do
                    local Frame = _G[ 'ChatFrame'..i ];
                    if( Frame and DB:GetPersistence().Font.Shadow.Color ~= nil ) then
                        DB:GetPersistence().Font.Shadow.Color = { r=R,g=G,b=B,a=A }

                        local Font = DB:GetDBValue( 'Font' )
                        Frame:SetShadowColor( Font.Shadow.Color.r,Font.Shadow.Color.g,Font.Shadow.Color.b,Font.Shadow.Color.a )
                    end
                end
            end,
		},
		FontSize = {
			order = 3,
            name = 'Font Size',
            desc = 'Chat Font Size',
            arg = 'Size',
            type = 'select',
			get = function( Info )
			    if( DB:GetPersistence().Font[ Info.arg ] ~= nil ) then
			        return DB:GetPersistence().Font[ Info.arg ]
			    end
			end,
            set = function( Info,Value )
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
            end,
            values = {
                [10] = 10,
                [12] = 12,
                [14] = 14,
                [16] = 16,
                [18] = 18,
            },
		},
        SecondSeparator = {
            type = 'header',
            order = 4,
            name = 'TOGGLES',
        },
    	ScrollBack = {
			order = 5,
	        type = 'toggle',
	        name = 'Scroll Back',
	        desc = 'Extend chat history to 10,000 lines',
	        arg = 'ScrollBack',
	        set = function( Info,Value )
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
	        end,
	    },
    	FadeOut = {
			order = 6,
	        type = 'toggle',
	        name = 'Fade Out',
	        desc = 'Enable/disable chat fading',
	        arg = 'FadeOut',
	        set = function( Info,Value )
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
	        end,
	    },
	}
end

function CONFIG:FilterOps()
	return {
        FirstSeparator = {
            type = 'header',
            order = 0,
            name = 'CUSTOM',
        },
		CustomAlerts = {
			order = 1,
	        type = 'input',
	        multiline = true,
	        get = function( Info )
	            return Library:Implode( DB:GetAlerts(),',' )
	        end,
	        set = function( Info,Value )
	            self:SetAlerts( Value );
	        end,
	        name = 'Alert List',
	        desc = 'Words or phrases to be alerted on when they are mentioned in chat. Seperate individual things to alert on with a comma: e.g. healer,spriest,sfk,really cool',
	        arg = 'AlertList',
	        width = 'full',
	    },
		CustomIgnores = {
			order = 2,
	        type = 'input',
	        multiline = true,
	        get = function( Info )
	            return Library:Implode( DB:GetIgnores(),',' )
	        end,
	        set = function( Info,Value )
	            self:SetIgnores( Value )
	        end,
	        name = 'Ignore List',
	        desc = 'Words or phrases which should be omitted in chat. Seperate individual things to ignore with a comma: e.g. boost,spam,anidiot,absolutely terrible',
	        arg = 'IgnoreList',
	        width = 'full',
	    },
	    AlertColors = {
            type = 'color',
            order = 3,
            get = function( Info )
                if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    return unpack( DB:GetPersistence()[ Info.arg ] )
                end
            end,
            set = function( Info,R,G,B,A )
                if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
                    DB:GetPersistence()[ Info.arg ] = { R,G,B,A }
                end
            end,
            name = 'Alert Color',
            desc = 'Set the color of Alerts chat',
            arg = 'AlertColor',
            --hasAlpha = true,
        },
        SecondSeparator = {
            type = 'header',
            order = 4,
            name = 'PERSONAL',
        },
        AlertMention = {
            type = 'toggle',
            order = 5,
            name = 'Personal Mention Alert',
            desc = 'Enable/disable alerting if anyone mentions your name. Note that mentions always produce an alert sound and have the whisper color',
            arg = 'MentionAlert',
        },
        AliasList = {
            type = 'input',
            order = 6,
            multiline = true,
            get = function( Info )
                return Library:Implode( self:GetAliasList(),',' );
            end,
            set = function( Info,Value )
                self:SetAliasList( Value );
            end,
            name = 'Alert Alias List',
            desc = 'Comma seperated list of aliases for your character name, to be used in mention alerts',
            arg = 'Aliases',
            width = 'normal',
            multiline = false,
        },
	}
end

function CONFIG:FormatOps()
	local Order = 1
	local ChannelPrefs = {
        FirstSeparator = {
            type = 'header',
            order = 0,
            name = 'COLORS',
        },
	}
	for _,Channel in pairs( self:GetChannels() ) do 
		if( Channel.Name ) then
			Order = Order+1
            ChannelPrefs[ Channel.Name..'Color' ] = {
                type = 'color',
                order = Order,
                get = function( Info )
                    if( DB:GetPersistence().Channels[ Info.arg ] and not DB:GetPersistence().Channels[ Info.arg ].Color ) then
                        DB:GetPersistence().Channels[ Info.arg ].Color = CHATFRAME:GetBaseColor()
                    end
                    return unpack( DB:GetPersistence().Channels[ Info.arg ].Color )
                end,
                set = function( Info,R,G,B,A )
                    local InternalCall = true;
                    if( DB:GetPersistence().Channels[ Info.arg ] ~= nil ) then

                        -- Change color
                        DB:GetPersistence().Channels[ Info.arg ].Color = { R,G,B,A }

                        -- Apply to Chat
                        CHATFRAME:ApplyChatColors()
                        
                    end
                end,
                name = '[['..Channel.Id..']'..Channel.Name..']',
                desc = 'Set the color of '..Channel.Name..' chat',
                arg = Channel.Name,
                --hasAlpha = true,
            }
		end
	end

	Order = Order+1
    ChannelPrefs.SecondSeparator = {
        type = 'header',
        order = Order,
        name = 'TIMESTAMPS',
    }
	Order = Order+1
	ChannelPrefs.TimeStamps = {
        type = 'select',
        values = {
            none = 'none',
            hour_min_12 = 'hour_min_12',
            hour_min_ext = 'hour_min_ext',
            hour_min_sec_12_ext = 'hour_min_sec_12_ext',
            hour_min_24 = 'hour_min_24',
            hour_min_sec_24 = 'hour_min_sec_24',
        },
        order = Order,
        name = 'Timestamps',
        desc = 'Timestamp format',
        arg = 'showTimestamps',
    }

	Order = Order+1
	ChannelPrefs.TimeColor = {
        type = 'color',
        order = Order,
        get = function( Info )
            if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
                return unpack( DB:GetPersistence()[ Info.arg ] );
            end
        end,
        set = function( Info,R,G,B,A )
            if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
                DB:GetPersistence()[ Info.arg ] = { R,G,B,A };
            end
        end,
        name = 'Timestamps',
        desc = 'Timestamp Color',
        arg = 'TimeColor',
        --hasAlpha = true,
    }

	Order = Order+1
    ChannelPrefs.ThirdSeparator = {
        type = 'header',
        order = Order,
        name = 'TOGGLES',
    }

	Order = Order+1
	ChannelPrefs.ShortNames = {
        type = 'toggle',
        order = Order,
        name = 'Short Channel Names',
        desc = 'For channels with long names, shorten them with abbreviation',
        arg = 'ShortChannelNames',
	}

	Order = Order+1
	ChannelPrefs.Links = {
        type = 'toggle',
        order = Order,
        name = 'Links',
        desc = 'Automatically convert links to clickable',
        arg = 'LinksEnabled',
	}

	Order = Order+1
	ChannelPrefs.ClassColors = {
        type = 'toggle',
        order = Order,
		get = function( Info )
		    if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
		        return DB:GetPersistence()[ Info.arg ]
		    end
		end,
        set = function( Info,Value )
        	if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
            	DB:GetPersistence()[ Info.arg ] = Value

	            for i,ChannelData in pairs( CHATFRAME:GetChannels() ) do
	                if( ChannelData.Id ) then
	                    ToggleChatColorNamesByClassGroup( Value,tostring( 'CHANNEL'..ChannelData.Id ) );
	                end
	            end
            end
        end,
        name = 'Class Colors',
        desc = 'Enable/Disable Chat Class Colors',
        arg = 'ClassColors',
	}
	return ChannelPrefs
end

function CONFIG:QuestOps()
	return {
        FirstSeparator = {
            type = 'header',
            order = 0,
            name = 'QUESTS',
        },
		Quests = {
	        type = 'toggle',
	        order = 1,
	        name = 'Quests',
	        desc = 'Enable/disable alerting if anyone mentions a quest you are on',
	        arg = 'QuestAlert',
		}
	}
end

function CONFIG:DebugOps()
	return {
        FirstSeparator = {
            type = 'header',
            order = 0,
            name = 'DEBUG',
        },
		Debug = {
	        type = 'toggle',
	        order = 1,
	        name = 'Enabled',
	        desc = 'Enable/disable debug',
	        arg = 'Debug',
		}
	}
end

function CONFIG:OpenConfig( Input )
    LibStub( 'AceConfigDialog-3.0' ):Open( NAME )
end

function CONFIG:Refresh()
	local Options = {
		get = function( Info )
		    if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
		        return DB:GetPersistence()[ Info.arg ]
		    end
		end,
        set = function( Info,Value )
        	if( DB:GetPersistence()[ Info.arg ] ~= nil ) then
            	DB:GetPersistence()[ Info.arg ] = Value
            end
        end,
        --name = 'jChat Settings',
        childGroups = 'tree',
		type = 'group',
		args = {
			WindowOptions = {
				order = 1,
				name = 'Windows',
				type = 'group',
				width = 'full',
				args = self:WindowOps()
			},
			FormattingOptions = {
				order = 2,
				name = 'Formats',
				type = 'group',
				width = 'full',
				args = self:FormatOps()
			},
			FilterOptions = {
				order = 3,
				name = 'Filters',
				type = 'group',
				width = 'full',
				args = self:FilterOps()
			},
			QuestOptions = {
				order = 4,
				name = 'Quests',
				type = 'group',
				width = 'full',
				args = self:QuestOps()
			},
			DebugOptions = {
				order = 5,
				name = 'Debug',
				type = 'group',
				width = 'full',
				args = self:DebugOps()
			},
		},
	};

    -- Register our options table with AceConfig
    LibStub( 'AceConfigRegistry-3.0' ):RegisterOptionsTable( NAME,Options )
    self.optionsFrame = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( NAME,NAME )
    
    -- Slash command to open the standalone AceConfig Dialog GUI directly
    self:RegisterChatCommand( 'jc','OpenConfig' )
    self:RegisterChatCommand( 'jchat','OpenConfig' )
end

function CONFIG:OnEnable()
	self:Refresh()
end