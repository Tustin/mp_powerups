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

//#precache( "material", "specialty_instakill_zombies" );
//#precache( "string", "ZOMBIE_POWERUP_INSTA_KILL" );
#precache("material", "skull_hud");
#precache("string", "POWERUPS_INSTA_KILL_PICKUP");

#namespace mp_powerup_insta_kill;

REGISTER_SYSTEM( "mp_powerup_insta_kill", &__init__, undefined )


//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	mp_powerups::register_powerup( "insta_kill", &grab_insta_kill );
	mp_powerups::add_mp_powerup("insta_kill", 
		"skull_drop", 
		&"ZOMBIE_POWERUP_INSTA_KILL",
		!POWERUP_ONLY_AFFECTS_GRABBER, 
		!POWERUP_ANY_TEAM, 
		undefined);	
}

function grab_insta_kill( player )
{	
	foreach( iplayer in level.players )
	{
		if (iplayer.team != player.team) continue;
		iplayer playsoundtoplayer("mp_insta_kill", iplayer);
		ret = iplayer thread mp_powerups::add_powerup_hud("skull_hud", N_POWERUP_DEFAULT_TIME);
		if (!ret) {
			iplayer.active_huds["insta_kill"] = true;
		}
	}
	
	LUINotifyEvent(&"player_callout", 2, &"POWERUPS_INSTA_KILL_PICKUP", player.entnum);


	level thread insta_kill_powerup(self, player);
	//player thread mp_powerups::powerup_vo("mp_insta_kill", player.team);
}

function remove_hud() {
	self waittill("minigun_time_over");
	self mp_powerups::remove_powerup_hud("minigun_hud");
}

function insta_kill_powerup( drop_item, player )
{
	team = player.team;
	//IPrintLnbold(team);

	//so it wont create a new thread and make the time count down faster
	if (level.zombie_vars[team]["zombie_insta_kill"]) {
		level.zombie_vars[team]["zombie_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;
		return;
	}

	players = GetPlayers(player.team);
	
	//level thread zm_powerups::show_on_hud( team, "insta_kill" );

	level.zombie_vars[team]["zombie_insta_kill"] = true;
	level.zombie_vars[team]["zombie_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;
	//level.players[0] IPrintLnBold("insta kill picked up by " + player.name + " for " + player.team + " and it's " + level.zombie_vars[team]["zombie_insta_kill"]);
	
	//TODO overflow/undefined check
	for (i = 0; i < players.size; i++) {
		if (!isdefined(players[i].insta_kill_timer))
			players[i].insta_kill_timer = players[i] draw_insta_kill();
	}

	while (level.zombie_vars[team]["zombie_insta_kill_time"] > 0)
	{
		WAIT_SERVER_FRAME;
		level.zombie_vars[team]["zombie_insta_kill_time"] = level.zombie_vars[team]["zombie_insta_kill_time"] - 0.05;
		
		for (i = 0; i < players.size; i++) {
			if (!isdefined(players[i].insta_kill_timer)) {
				players[i].insta_kill_timer = players[i] draw_insta_kill();
			}
			players[i].insta_kill_timer setText("Insta-kill: " + Int(level.zombie_vars[team]["zombie_insta_kill_time"])); 
		}
	}

	level.zombie_vars[team]["zombie_insta_kill"] = false;

	foreach (iplayer in players) {
		if (!iplayer.active_huds["insta_kill"]) continue;
		iplayer mp_powerups::remove_powerup_hud("skull_hud");
	}
	
	for (i = 0; i < players.size; i++) {
		players[i].insta_kill_timer Destroy();
	}
}

function draw_insta_kill() {
	self.insta_kill_timer = newClientHudElem(self);
	self.insta_kill_timer.horzAlign = "center";
	self.insta_kill_timer.vertAlign = "bottom";
	self.insta_kill_timer.alignX = "center";
	self.insta_kill_timer.alignY = "bottom";
	self.insta_kill_timer.alpha = 1;
	self.insta_kill_timer.fontScale = 1.8;
	self.insta_kill_timer setText("Insta-kill: " + Int(level.zombie_vars[self.team]["zombie_insta_kill_time"]));
	return self.insta_kill_timer;
}