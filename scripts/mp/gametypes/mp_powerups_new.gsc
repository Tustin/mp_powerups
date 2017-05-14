#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\demo_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\flagsys_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\mp\powerups\mp_powerups.gsh;

#precache("material", "black");

#precache("fx", "zombie/fx_powerup_on_green_zmb");
#precache("fx", "zombie/fx_powerup_off_green_zmb");
#precache("fx", "zombie/fx_powerup_grab_green_zmb");
#precache("fx", "zombie/fx_powerup_on_red_zmb");
#precache("fx", "zombie/fx_powerup_grab_red_zmb");
#precache("fx", "zombie/fx_powerup_on_solo_zmb");
#precache("fx", "zombie/fx_powerup_grab_solo_zmb");
#precache("fx", "zombie/fx_powerup_on_caution_zmb");
#precache("fx", "zombie/fx_powerup_grab_caution_zmb");

#namespace mp_powerups;

function init()
{	
	// powerup Vars
	level.zombie_vars = [];
	zombie_vars["zombie_timer_offset_interval"] = 30;

	zombie_vars["zombie_powerup_insta_kill_on"] = false;
	zombie_vars["zombie_powerup_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;

	zombie_vars["zombie_powerup_double_points_on"] = false;
	zombie_vars["zombie_powerup_double_points_time"] = N_POWERUP_DEFAULT_TIME;

	zombie_vars["zombie_powerup_drop_increment"] = 2000;
	zombie_vars["zombie_powerup_drop_max_per_round"] = 4;

	// powerups
	level._effect["powerup_on"] 					= "zombie/fx_powerup_on_green_zmb";
	level._effect["powerup_off"] 					= "zombie/fx_powerup_off_green_zmb";
	level._effect["powerup_grabbed"] 				= "zombie/fx_powerup_grab_green_zmb";
	level._effect["powerup_on_solo"]				= "zombie/fx_powerup_on_solo_zmb";
	level._effect["powerup_grabbed_solo"]			= "zombie/fx_powerup_grab_solo_zmb";
	level._effect["powerup_on_caution"]				= "zombie/fx_powerup_on_caution_zmb";
	level._effect["powerup_grabbed_caution"]		= "zombie/fx_powerup_grab_caution_zmb";

	init_powerups();
}
//VARS
//level.active_powerups = array of currently active powerups
//level.mp_powerup_array = array of all possible powerup names
//level.mp_powerups = array of all possible powerup entities
function init_powerups()
{
	if(!isdefined(level.active_powerups))
	{
		level.active_powerups = [];
	}

	randomize_powerups();
	level.mp_powerup_index = 0;
	randomize_powerups();
}
function randomize_powerups()
{
	if (!isdefined(level.mp_powerup_array))
	{
		level.mp_powerup_array = [];
	}
	else
	{
		level.mp_powerup_array = array::randomize(level.mp_powerup_array);
	}
}

function get_next_powerup()
{
	powerup = level.mp_powerup_array[level.mp_powerup_index];

	level.mp_powerup_index++;
	if(level.mp_powerup_index >= level.mp_powerup_array.size)
	{
		level.mp_powerup_index = 0;
		randomize_powerups();
	}

	return powerup;
}

function get_random_powerup_name()
{
	powerup_keys = GetArrayKeys(level.mp_powerups);
	powerup_keys = array::randomize(powerup_keys);
	return powerup_keys[0];
}