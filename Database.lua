local _,Library = ...;

local ADDON = LibStub( 'AceAddon-3.0' ):NewAddon( 'jChat' )
local DB = ADDON:NewModule( 'database' )

function DB:SetDBValue( Index,Value )
    if( self:GetPersistence()[ Index ] ~= nil ) then
        self:GetPersistence()[ Index ] = Value;
    end
end

function DB:GetDBValue( Index )
    if( self:GetPersistence()[ Index ] ~= nil ) then
        return self:GetPersistence()[ Index ];
    end
end

function DB:GetPersistence()
    return self.db.global;
end


--
-- Set watch list
--
-- @param string
--
-- @return void
function DB:SetAlerts( Watch )
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
function DB:GetAlerts()
    return DB:GetPersistence().AlertList;
end

--
-- Set ignore list
--
-- @param string
--
-- @return void
function DB:SetIgnores( Ignore )
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
function DB:GetIgnores()
    return DB:GetPersistence().IgnoreList;
end

--
-- Set alias list
--
-- @param string
--
-- @return void
function DB:SetAliasList( Alias )
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
function DB:GetAliasList()
    return DB:GetPersistence().AliasList;
end

function DB:Reset()
    -- Wipe Database
    wipe( self.db.global ); 

    -- Reset Profile
    self.db:ResetProfile();

    -- Refresh Settings
    if( C_UI and C_UI.Reload ) then
        C_UI.Reload();
    else
        ReloadUI();
    end
end

function DB:OnEnable()
    local Defaults = {
        global = {
            Font = {
                Family = 'FRIZQT__',
                Size = 14,
                Flags = 'THINOUTLINE',
                Shadow = {
                    Color = {
                        r = 101/255,
                        g = 68/255,
                        b = 96/255,
                        a = 1,
                    },
                    Offset = {
                        x = 0,
                        y = -0,
                    },
                },
            },
            FadeOut = false,
            IgnoreList = {
                'boost',
            },
            MentionAlert = true,
            MentionDrop = {
            },
            MentionMove = 0,
            MentionAlpha = .5,
            AliasList = {
            },
            ScrollBack = true,
            QuestAlert = true,
            ChannelColor = {
                254/255,
                191/255,
                191/255,
                1,
            },
            AlertColor = {
                224/255,
                157/255,
                240/255,
                1,
            },
            AlertChannel = 'SFX',
            AlertVolume = .5,
            AlertList = {
            },
            LinksEnabled = true,
            Channels = {},
            ShortChannelNames = true;
            ChatGroups = {
                BATTLEGROUND = true,
                TRADESKILLS = false,
                SAY = true,
                EMOTE = true,
                YELL = true,
                GUILD = true,
                WHISPER = true,
                BN = true,
                PARTY = true,
                RAID = true,
                COMBAT = true,
                SKILL = true,
                LOOT = true,
                MONEY = true,
                OPENING = true,
                PET = false,
                ERRORS = true,
                IGNORED = true,
            },
            BypassTypes = true,
            showTimestamps = 'none',
            TimeColor = {
                143/255,
                140/255,
                143/255,
                1,
            },
            ClassColors = true,
            AutoInvite = true,
            RespectLocks = true,
            Debug = false,
        },
    };
    self.db = LibStub( 'AceDB-3.0' ):New( ADDON:GetName(),Defaults,'global' );

    self.db.RegisterCallback( self,'OnProfileChanged','Reset' );
    self.db.RegisterCallback( self,'OnProfileCopied','Reset' );
    self.db.RegisterCallback( self,'OnProfileReset','Reset' );

    self.FONTS = {
        Enigmatic = "Interface\\AddOns\\" .. ADDON:GetName() .. "\\Fonts\\Enigma__2.TTF",
        ARIALN = "Fonts\\ARIALN.TTF",
        FRIZQT__ = "Fonts\\FRIZQT__.TTF",
        MORPHEUS = "Fonts\\MORPHEUS.TTF",
        skurri = "Fonts\\skurri.TTF",
    };
end