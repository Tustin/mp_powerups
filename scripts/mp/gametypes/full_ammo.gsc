#using scripts\codescripts\struct;

#using scripts\shared\clientfield_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;

#precache("string", "POWERUPS_MAX_AMMO_PICKUP");
//#precache( "eventstring", "zombie_notification" );
//#precache( "eventstring", "show_gametype_objective_hint" );
#namespace mp_powerup_full_ammo;

REGISTER_SYSTEM("mp_powerup_full_ammo", &__init__, undefined)


//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	mp_powerups::register_powerup("full_ammo", &grab_full_ammo);
	mp_powerups::add_mp_powerup("full_ammo", 
		"ammocan", 
		&"ZOMBIE_POWERUP_MAX_AMMO", 
		!POWERUP_ONLY_AFFECTS_GRABBER, 
		!POWERUP_ANY_TEAM,
		undefined);
}

function grab_full_ammo( player )
{	
	level thread full_ammo_powerup(self, player);
	player thread mp_powerups::powerup_vo("mp_max_ammo", player.team);
}

function full_ammo_powerup( drop_item , player)
{
	players = GetPlayers(player.team);
	/*
	if(isDefined(level._get_game_module_players))
	{
		players = [[level._get_game_module_players]](player);
	}
	*/

	level notify("zmb_max_ammo_level");
	
	for (i = 0; i < players.size; i++)
	{
		primary_weapons = players[i] GetWeaponsList(); //todo true

		players[i] notify("zmb_max_ammo");
		for(x = 0; x < primary_weapons.size; x++)
		{
			//Give ammo but only if it's not an alt-mode weapon (so it doesnt give killstreaks)
			if (players[i] HasWeapon(primary_weapons[x]) && !primary_weapons[x].isaltmode && !primary_weapons[x].iskillstreak){
				players[i] GiveMaxAmmo(primary_weapons[x]);
			}
		}
	}

	level thread full_ammo_on_hud(drop_item, player);
}

function full_ammo_on_hud(drop_item, player)
{
	players = GetPlayers(player.team);
	
	players[0] playsoundToTeam("zmb_full_ammo", player.team);

	LUINotifyEvent(&"player_callout", 2, &"POWERUPS_MAX_AMMO_PICKUP", player.entnum);
}
