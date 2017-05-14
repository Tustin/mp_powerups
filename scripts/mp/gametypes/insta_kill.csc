#using scripts\codescripts\struct;

#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;

#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;

#namespace mp_powerup_insta_kill;

REGISTER_SYSTEM( "mp_powerup_insta_kill", &__init__, undefined )
	
function __init__()
{
	mp_powerups::include_mp_powerup("insta_kill");
	mp_powerups::add_mp_powerup("insta_kill");
}
