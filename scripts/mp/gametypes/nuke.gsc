#using scripts\codescripts\struct;

#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;


#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;


#precache("string", "POWERUPS_NUKE_PICKUP");

#namespace mp_powerup_nuke;

REGISTER_SYSTEM( "mp_powerup_nuke", &__init__, undefined )

#define N_NUKE_SPAWN_DELAY 3


//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	mp_powerups::register_powerup( "nuke", &grab_nuke );
	mp_powerups::add_mp_powerup("nuke", 
		"bomb_drop", 
		&"ZOMBIE_POWERUP_NUKE", 
		!POWERUP_ONLY_AFFECTS_GRABBER, 
		!POWERUP_ANY_TEAM, 
		undefined);
}

function grab_nuke( player )
{
	level thread nuke_powerup( self, player );
	
	player notify("nuke_triggered");	

	//wait(1);
	//We want to play it for ALL players (so the enemies know what happened)
	foreach(iplayer in level.players)
	{
		iplayer playsoundtoplayer("mp_kaboom", iplayer);
	}

	LUINotifyEvent(&"player_callout", 2, &"POWERUPS_NUKE_PICKUP", player.entnum);


}

// kill them all!
function nuke_powerup( drop_item, player)
{	
	location = drop_item.origin;

	if( isdefined( drop_item.fx ) )
	{
		PlayFx( drop_item.fx, location );
	}
	level thread nuke_flash(player.team);

	wait(0.5);

	//Shows a skull in the killfeed
	t_wep = GetWeapon("gadget_heat_wave");

	for (i = 0; i < level.players.size; i++) {
		if (level.players[i].team == player.team || !IsAlive(level.players[i])) {
			continue;
		}
		//Kill them!
		level.players[i] kill(level.players[i].origin, player, t_wep, t_wep);
		//level.players[0] IPrintLnBold("killed " + level.players[i].name);
	}
	level notify( "nuke_complete" );
}

function nuke_flash(team)
{
	if (IsDefined(team))
		GetPlayers()[0] PlaySoundToTeam("evt_nuke_flash", team);
	else
		GetPlayers()[0] PlaySound("evt_nuke_flash");

	lui::screen_flash( 0.2, 0.5, 1.0, 0.8, "white" ); // flash
}
