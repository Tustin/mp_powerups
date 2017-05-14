#using scripts\codescripts\struct;

#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;

#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;

#namespace mp_powerup_nuke;

REGISTER_SYSTEM( "mp_powerup_nuke", &__init__, undefined )
	
function __init__()
{
	mp_powerups::include_mp_powerup( "nuke" );
	mp_powerups::add_mp_powerup( "nuke" );
	
	//clientfield::register( "actor", "zm_nuked", VERSION_TU1, 1, "counter", &zombie_nuked, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	//clientfield::register( "vehicle", "zm_nuked", VERSION_TU1, 1, "counter", &zombie_nuked, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
}

function zombie_nuked( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	//self zombie_death::flame_death_fx( localClientNum );
}

