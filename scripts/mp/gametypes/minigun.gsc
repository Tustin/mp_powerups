#using scripts\codescripts\struct;

#using scripts\shared\clientfield_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;

#precache("material", "minigun_hud");
#precache("string", "POWERUPS_MINIGUN_PICKUP");

#namespace mp_powerup_weapon_minigun;

REGISTER_SYSTEM("mp_powerup_weapon_minigun", &__init__, undefined)

//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	mp_powerups::register_powerup("minigun", &grab_minigun);
	mp_powerups::register_powerup_weapon("minigun", &minigun_countdown);
	//mp_powerups::set_weapon_ignore_max_ammo("minigun");
	//
	mp_powerups::add_mp_powerup("minigun", 
	    "minigun_drop", 
        &"ZOMBIE_POWERUP_MINIGUN",
        POWERUP_ONLY_AFFECTS_GRABBER, 
        !POWERUP_ANY_TEAM, 
        undefined);

	level.zombie_powerup_weapon["minigun"] = GetWeapon("minigun");
	
	callback::on_connect(&init_player_zombie_vars);
}

function grab_minigun(player)
{	
	level thread minigun_weapon_powerup(player);
	player playsoundtoplayer("mp_minigun", player);

	LUINotifyEvent(&"player_callout", 2, &"POWERUPS_MINIGUN_PICKUP", player.entnum);

	ret = player thread mp_powerups::add_powerup_hud("minigun_hud", N_POWERUP_DEFAULT_TIME);
	if (!ret) {
		player thread remove_hud();
	}
/*
	if(IsDefined(level._grab_minigun))
	{
		level thread [[level._grab_minigun]](player);
	}
	*/
}

function remove_hud() {
	self waittill("minigun_time_over");
	self mp_powerups::remove_powerup_hud("minigun_hud");
}
//	Creates zombie_vars that need to be tracked on an individual basis rather than as
//	a group.
function init_player_zombie_vars()
{	
	self.zombie_vars["zombie_powerup_minigun_on"] = false;
	self.zombie_vars["zombie_powerup_minigun_time"] = 0;
}

//******************************************************************************
// Minigun powerup
//******************************************************************************
function minigun_weapon_powerup( ent_player, time )
{
	ent_player endon("disconnect");
	ent_player endon("death");
	ent_player endon("minigun_time_over");
	
	if (!IsDefined(time))
	{
		time = 30;
	}

	if(isDefined(level._minigun_time_override))
	{
		time = level._minigun_time_override;
	}

	// Just replenish the time if it's already active
	if (ent_player.zombie_vars[ "zombie_powerup_minigun_on" ] && 
		 (level.zombie_powerup_weapon[ "minigun" ] == ent_player GetCurrentWeapon() || (IsDefined(ent_player.has_powerup_weapon[ "minigun" ]) && ent_player.has_powerup_weapon[ "minigun" ]) ))
	{
		if ( ent_player.zombie_vars["zombie_powerup_minigun_time"] < time )
		{
			ent_player.zombie_vars["zombie_powerup_minigun_time"] = time;
		}
		return;
	}
		
	stance_disabled = false;
	//powerup cannot be switched to if player is in prone
	if(ent_player GetStance() === "prone")
	{
		ent_player AllowCrouch(false);
		ent_player AllowProne(false);
		stance_disabled = true;
		
		while(ent_player GetStance() != "stand")
		{
			WAIT_SERVER_FRAME;
		}
	}
	
	mp_powerups::weapon_powerup( ent_player, time, "minigun", true );
	
	if( stance_disabled )
	{
		ent_player AllowCrouch( true );
		ent_player AllowProne( true );
	}
}


function minigun_countdown( ent_player, str_weapon_time )
{
	while ( ent_player.zombie_vars[str_weapon_time] > 0)
	{
		WAIT_SERVER_FRAME;
		ent_player.zombie_vars[str_weapon_time] = ent_player.zombie_vars[str_weapon_time] - 0.05;
	}

}

function minigun_weapon_powerup_off()
{
	self.zombie_vars["zombie_powerup_minigun_time"] = 0;
}

function minigun_damage_adjust(inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, sHitLoc, psOffsetTime, boneIndex, surfaceType  ) //self is an enemy
{
	if ( weapon.name != "minigun" )
	{
		// Don't affect damage dealt if the weapon isn't the minigun, allow other damage callbacks to be evaluated - mbettelman 1/28/2016
		return -1;
	}

	n_percent_damage = self.health * (RandomFloatRange(.34, .75) );

	if ( isdefined (level.minigun_damage_adjust_override) )
	{
		n_override_damage = thread [[ level.minigun_damage_adjust_override ]](  inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, sHitLoc, psOffsetTime, boneIndex, surfaceType  );
		if( isdefined( n_override_damage ) )
		{
			n_percent_damage = n_override_damage;
		}
	}

	
	if( isdefined( n_percent_damage ) ) 
	{
		damage += n_percent_damage;	
	}
	return damage;
}

