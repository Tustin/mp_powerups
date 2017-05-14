#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\hostmigration_shared;
#using scripts\shared\hud_message_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\math_shared;
#using scripts\shared\rank_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\sound_shared;
#using scripts\shared\util_shared;
#using scripts\shared\weapons_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\flagsys_shared;
#using scripts\shared\clientfield_shared;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_globallogic_ui;
#using scripts\mp\gametypes\_loadout;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\_teamops;
#using scripts\mp\_util;
#using scripts\mp\teams\_teams;
#using scripts\mp\bots\_bot_loadout;

#using scripts\mp\gametypes\full_ammo;
#using scripts\mp\gametypes\nuke;
#using scripts\mp\gametypes\insta_kill;
#using scripts\mp\gametypes\free_perk;
#using scripts\mp\gametypes\minigun;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\statstable_shared.gsh;
#insert scripts\mp\gametypes\mp_powerups.gsh;
#insert scripts\shared\version.gsh;



#precache( "string", "POWERUPS_OBJECTIVES_POWERUPS" );
#precache( "string", "POWERUPS_OBJECTIVES_POWERUPS_HINT" );
#precache( "string", "POWERUPS_OBJECTIVES_POWERUPS_SCORE" );

#namespace mp_powerups;

function main()
{	
	globallogic::init();

	util::registerRoundSwitch( 0, 9 );
	util::registerTimeLimit( 0, 1440 );
	util::registerScoreLimit( 0, 50000 );
	util::registerRoundLimit( 0, 10 );
	util::registerRoundWinLimit( 0, 10 );
	util::registerNumLives( 0, 100 );

	globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );

	level.teamBased = true;
	level.overrideTeamScore = true;

	level.onStartGameType = &onStartGameType;

	// powerup Vars
	level.zombie_vars = [];
	level.zombie_vars["zombie_timer_offset_interval"] = 30;

	level.zombie_vars["zombie_powerup_insta_kill_on"] = false;
	level.zombie_vars["zombie_powerup_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;

	level.zombie_vars["zombie_powerup_double_points_on"] = false;
	level.zombie_vars["zombie_powerup_double_points_time"] = N_POWERUP_DEFAULT_TIME;

	level.zombie_vars["zombie_powerup_drop_increment"] = 2000;
	level.zombie_vars["zombie_powerup_drop_max_per_round"] = 4;

	level.zombie_vars["allies"]["zombie_insta_kill"] = false;
	level.zombie_vars["axis"]["zombie_insta_kill"] = false;

	level.zombie_vars["allies"]["zombie_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;
	level.zombie_vars["axis"]["zombie_insta_kill_time"] = N_POWERUP_DEFAULT_TIME;

	// powerups
	level._effect["powerup_on"] 					= "zombie/fx_zombie_powerup_on";
	level._effect["powerup_off"] 					= "zombie/fx_zombie_powerup_on";
	level._effect["powerup_grabbed"] 				= "zombie/fx_zombie_powerup_grab";
	level._effect["powerup_on_solo"]				= "zombie/fx_zombie_powerup_grab";
	level._effect["powerup_grabbed_solo"]			= "zombie/fx_zombie_powerup_grab";
	level._effect["powerup_on_caution"]				= "zombie/fx_zombie_powerup_grab";
	level._effect["powerup_grabbed_caution"]		= "zombie/fx_zombie_powerup_grab";

	init_powerups();

	level.onPlayerKilled = &onPlayerKilled;
	level.onPlayerDamage = &onPlayerDamage;
	
	callback::on_connect( &on_player_connect ); // force teams on connecting
	callback::on_disconnect( &on_player_disconnect ); // player disconnected watcher
	callback::on_joined_team( &on_joined_team ); // update score info
	callback::on_spawned(&on_player_spawned);

	gameobjects::register_allowed_gameobject( level.gameType );

	globallogic_audio::set_leader_gametype_dialog ( undefined, undefined, "gameBoost", "gameBoost" );

	// Sets the scoreboard columns and determines with data is sent across the network
	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "kdratio", "assists" );

}

function on_player_connect() {
	if (!isdefined(level.availablePerks)) {
		level.availablePerks = [];
		//Query all the perks that the game uses and set those in an array
		//Store them in seperate arrays in case I decide to do something with them later
		perkSlot1 = self get_table_items("specialty1");
		perkSlot2 = self get_table_items("specialty2");
		perkSlot3 = self get_table_items("specialty3");
		level.availablePerks = ArrayCombine(level.availablePerks, perkSlot1, false, false);
		level.availablePerks = ArrayCombine(level.availablePerks, perkSlot2, false, false);
		level.availablePerks = ArrayCombine(level.availablePerks, perkSlot3, false, false);
	}
}

function on_player_disconnect() {
	
}

function on_joined_team() {
	
}
function on_player_spawned(predictedSpawn)
{
	spawn_index = 0;
	foreach (powerup in level._custom_powerups) {
		mp_powerups::specific_powerup_drop(powerup.powerup_name, (spawn_index * 50, -10, 0), self.team, (spawn_index * 50, -10, 0), 0, self, true);
		spawn_index++;
	}

	if(self IsHost())
		self thread test();

	//self thread mp_powerup_free_perk::perk_test();

	if (isdefined(self.free_perks)) {
		if (self.free_perks.size > 0) {
			foreach (perk in self.free_perks) {
				perk_temp = strtok(perk, "|");
				foreach (newperk in perk_temp) {
					if (!self HasPerk(newperk)) {
						self SetPerk(newperk);
					}
				}

			}
			self IPrintLnBold("Gave back " + self.free_perks.size + " perks");
 		}
	}
}

function onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
		if (sMeansOfDeath == "MOD_SUICIDE" || 
			sMeansOfDeath == "MOD_FALLING" ||
			sMeansOfDeath == "MOD_DROWN" ||
			attacker.name == self.name)
	{
		return;
	}
	dead = self.origin;
	mp_powerups::powerup_drop(attacker.team, dead);
}

function onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	//ettacker = person DOING the damage
	if (isdefined(level.zombie_vars[eAttacker.team]["zombie_insta_kill"]) && level.zombie_vars[eAttacker.team]["zombie_insta_kill"]) {
		return 999999;
	}
}

function onStartGameType()
{
	setClientNameMode("auto_change");

	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}
	
	level.displayRoundEndText = false;
	
	// now that the game objects have been deleted place the influencers
	spawning::create_map_placed_influencers();
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	foreach( team in level.teams )
	{
		util::setObjectiveText( team, &"POWERUPS_OBJECTIVES_POWERUPS" );
		util::setObjectiveHintText( team, &"POWERUPS_OBJECTIVES_POWERUPS_HINT" );
	
		if ( level.splitscreen )
		{
			util::setObjectiveScoreText( team, &"POWERUPS_OBJECTIVES_POWERUPS" );
		}
		else
		{
			util::setObjectiveScoreText( team, &"POWERUPS_OBJECTIVES_POWERUPS_SCORE" );
		}
			
		spawnlogic::add_spawn_points( team, "mp_tdm_spawn" );

	}

	spawnlogic::place_spawn_points(spawning::getTDMStartSpawnName(team));
		
	spawning::updateAllSpawnPoints();
	
	level.spawn_start = [];
	
	foreach( team in level.teams )
	{
		level.spawn_start[ team ] =  spawnlogic::get_spawnpoint_array(spawning::getTDMStartSpawnName(team));
	}

	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	spawnpoint = spawnlogic::get_random_intermission_point();
	setDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	if ( !util::isOneRound() )
	{
		level.displayRoundEndText = true;
		if( level.scoreRoundWinBased )
		{
			globallogic_score::resetTeamScores();
		}
	}
}

function init_powerups()
{
	level flag::init("mp_drop_powerups");	// As long as it's set, powerups will be able to spawn
	
	level flag::set("mp_drop_powerups");

	if(!isdefined(level.active_powerups))
	{
		level.active_powerups = [];
	}
	
	// Randomize the order
	randomize_powerups();
	level.mp_powerup_index = 0;
	randomize_powerups();

	// Rare powerups
	level.rare_powerups_active = 0;
}

function test() {
	self endon("death");
	self endon("disconnect");

	while (true) {
		if (self UseButtonPressed() && self AttackButtonPressed()) {
			bot = AddTestClient();
			
			if(IsDefined(bot))
				bot BotSetRandomCharacterCustomization();
		}
		WAIT_SERVER_FRAME
	}
}


function randomize_powerups()
{
	if(!isdefined(level.mp_powerup_array))
	{
		level.mp_powerup_array = [];
	}
	else
	{
		level.mp_powerup_array = array::randomize(level.mp_powerup_array);
	}
}

//
// Get the next powerup in the list
//
function get_next_powerup()
{
	//just return the only result if theres only one powerup or else it wont return a powerup
	if (level.mp_powerup_array.size == 1) {
		return level.mp_powerup_array[0];
	}

	powerup = level.mp_powerup_array[level.mp_powerup_index];

	level.mp_powerup_index++;
	if(level.mp_powerup_index >= level.mp_powerup_array.size)
	{
		level.mp_powerup_index = 0;
		randomize_powerups();
	}

	return powerup;
}


function get_valid_powerup()
{
	p_arr = array::randomize(level.mp_powerup_array);
	//powerup = get_next_powerup();
	return p_arr[0];
}

function get_random_powerup_name()
{
	powerup_keys = GetArrayKeys(level.mp_powerups);
	powerup_keys = array::randomize(powerup_keys);
	return powerup_keys[0];
}

function add_mp_powerup(powerup_name, 
	model_name, 
	hint, 
	only_affects_grabber, 
	any_team, 
	fx, 
	clientfield_version = VERSION_SHIP, 
	player_specific = false)
{
	if(isdefined(level.mp_include_powerups) && !IS_TRUE(level.mp_include_powerups[powerup_name]))
	{
		return;
	}
	
	if(!isdefined(level.mp_powerup_array))
	{
		level.mp_powerup_array = [];
	}	

	struct = SpawnStruct();

	if(!isdefined(level.mp_powerups))
	{
		level.mp_powerups = [];
	}

	struct.powerup_name = powerup_name;
	struct.model_name = model_name;
	struct.weapon_classname = "script_model";
	struct.hint = hint;
	struct.only_affects_grabber = only_affects_grabber;
	struct.any_team = any_team;
	
	struct.hash_id = HashString(powerup_name);
	
	struct.player_specific = player_specific;

	if(isdefined(fx))
	{
		struct.fx = fx;
	}

	level.mp_powerups[powerup_name] = struct;
	level.mp_powerup_array[level.mp_powerup_array.size] = powerup_name;
}

function include_zombie_powerup(powerup_name)
{
	if(!isdefined(level.mp_include_powerups))
	{
		level.mp_include_powerups = [];
	}

	level.mp_include_powerups[powerup_name] = true;
}

function powerup_drop(who_can_grab, drop_point)
{
	if(isdefined(level.custom_zombie_powerup_drop))
	{
		b_outcome = [[level.custom_zombie_powerup_drop]](drop_point);
		
		if(IS_TRUE(b_outcome))
		{
			return;	
		}
	}
	
	if(!isdefined(level.mp_include_powerups) || level.mp_include_powerups.size == 0)
	{
		return;
	}

	// some guys randomly drop, but most of the time they check for the drop flag
	rand_drop = randomint(100);
	
	// Never drop unless in the playable area
	//playable_area = getentarray("player_volume","script_noteworthy");
	
	// This needs to go above the network_safe_spawn because that has a wait.
	//	Otherwise, multiple threads could attempt to drop powerups.
	level.powerup_drop_count++;
	powerup = spawn("script_model", drop_point + (0,0,40));
	//powerup = zm_net::network_safe_spawn("powerup", 1, "script_model", drop_point + (0,0,40));
	
	//chris_p - fixed bug where you could not have more than 1 playable area trigger for the whole map
	/*
	valid_drop = false;
	for (i = 0; i < playable_area.size; i++)
	{
		if (powerup istouching(playable_area[i]))
		{
			valid_drop = true;
			break;
		}
	}
	*/
	powerup powerup_setup();

	powerup thread powerup_timeout(who_can_grab);
	powerup thread powerup_wobble();
	powerup thread powerup_grab(who_can_grab);
	powerup thread powerup_move();

	level.zombie_vars["zombie_drop_item"] = 0;

	level notify("powerup_dropped", powerup);
	//level.players[0] IPrintLnBold("hit fifth drop");

}


//
//	Drop the specified powerup
function specific_powerup_drop(powerup_name, drop_spot, powerup_team, powerup_location, pickup_delay, powerup_player, b_stay_forever)
{
	//powerup = zm_net::network_safe_spawn("powerup", 1, "script_model", drop_spot + (0,0,40));
	powerup = spawn("script_model", drop_spot + (0,0,40));

	level notify("powerup_dropped", powerup);

	if (isdefined(powerup))
	{
		powerup powerup_setup(powerup_name,powerup_team, powerup_location, powerup_player);

		if(!IS_TRUE(b_stay_forever))
		{
			powerup thread powerup_timeout(powerup_team);
		}
		powerup thread powerup_wobble();

		powerup thread powerup_grab(powerup_team);	

		powerup thread powerup_move();

		return powerup;
	}
}

//	Pick the next powerup in the list
function powerup_setup(powerup_override,powerup_team, powerup_location, powerup_player)
{
	powerup = undefined;
	
	if (!isdefined(powerup_override))
	{
		powerup = get_valid_powerup();
	}
	else
	{
		powerup = powerup_override;
	}
	struct = level.mp_powerups[powerup];

	self SetModel(struct.model_name);
	//level.players[0] IPrintLnBold("dropped: " + struct.model_name);
	//TUEY Spawn Powerup
	playsoundatposition("zmb_spawn_powerup", self.origin);
	
	if(isdefined(powerup_team))
	{
		self.powerup_team = powerup_team;  //for encounters
	}
	if(isdefined(powerup_location))
	{
		self.powerup_location = powerup_location; //for encounters
	}
	if(isdefined(powerup_player))
	{
		//assert(IS_TRUE(struct.player_specific), "Non-Player specific powerup dropped with player specified"); 
		self.powerup_player = powerup_player; 
		//self SetInvisibleToAll(); 
		//self SetVisibleToPlayer(powerup_player); 
	}
	else
	{
		//assert(!IS_TRUE(struct.player_specific), "Player specific powerup dropped with no player specified"); 
	}
	self.powerup_name 			= struct.powerup_name;
	self.hint 					= struct.hint;
	self.only_affects_grabber 	= struct.only_affects_grabber;
	self.any_team				= struct.any_team;

	if(isdefined(struct.fx))
	{
		self.fx = struct.fx;
	}

	self PlayLoopSound("zmb_spawn_powerup_loop");
	
    level.active_powerups[level.active_powerups.size] = self;
}

function powerup_grab(powerup_team)
{
	self endon ("powerup_timedout");
	self endon ("powerup_grabbed");

	range_squared = 64 * 64;
	while (isdefined(self))
	{
		if(isdefined(self.powerup_player))
		{
			grabbers = []; 
			grabbers[0] = self.powerup_player;
		}
		else if(isdefined(level.powerup_grab_get_players_override))
		{
			grabbers = [[level.powerup_grab_get_players_override]]();
		}
		else
		{
			grabbers = GetPlayers();
		}

		for (i = 0; i < grabbers.size; i++)
		{
			grabber = grabbers[i];

			if (IsAlive(grabber.owner) && IsPlayer(grabber.owner))
			{
				player = grabber.owner;
			}
			else if (IsPlayer(grabber))
			{
				player = grabber;
			}

			if (grabber.team != powerup_team) {
				continue;
			}
			// if it's a personal power up, require a player 
			if (self.only_affects_grabber && !isdefined(player))
			{
				continue;
			}

			ignore_range = false;
			if (grabber.ignore_range_powerup === self)
			{
				grabber.ignore_range_powerup = undefined;
				ignore_range = true;
			}
			
			if (DistanceSquared(grabber.origin, self.origin) < range_squared || ignore_range)
			{
				if (isdefined(level._powerup_grab_check))
				{
					if (! self [[level._powerup_grab_check]](player))
						continue;
				}
				
				if(isdefined(level._custom_powerups) && isdefined(level._custom_powerups[self.powerup_name]) && isdefined(level._custom_powerups[self.powerup_name].grab_powerup))
				{
					b_continue = self [[level._custom_powerups[self.powerup_name].grab_powerup]](player);
					if(IS_TRUE(b_continue))
					{
						continue;	
					}
				}
				else
				{
					if (isdefined(level._zombiemode_powerup_grab))
					{
						level thread [[level._zombiemode_powerup_grab]](self, player);
					}
				}
				
				
				if (self.only_affects_grabber)
				{
					playfx(level._effect["powerup_grabbed_solo"], self.origin);
				}
				else if (self.any_team)
				{
					playfx(level._effect["powerup_grabbed_caution"], self.origin);
				}
				else
				{
					playfx(level._effect["powerup_grabbed"], self.origin);
				}
			
				if(isdefined(self.grabbed_level_notify))
				{
					level notify(self.grabbed_level_notify);
				}

				// RAVEN BEGIN bhackbarth: since there is a wait here, flag the powerup as being taken 
				self.claimed = true;
				self.power_up_grab_player = player; //Player who grabbed the power up
				// RAVEN END

				wait(0.1);

				if (player.team == powerup_team)
					player PlaySound("mp_powerup_grab");

				//PlaySoundAtPosition("grabbed_powerup", self.origin);
				self stoploopsound();
				self hide();
				
				//Preventing the line from playing AGAIN if fire sale becomes active before it runs out
				if(self.powerup_name != "fire_sale")
				{
					if(isdefined(self.power_up_grab_player))
					{
						if(isdefined(level.powerup_intro_vox))
						{
							level thread [[level.powerup_intro_vox]](self);
							return;
						}
						else
						{
							if(isdefined(level.powerup_vo_available))
							{
								can_say_vo = [[level.powerup_vo_available]]();
								if(!can_say_vo)
								{
									self thread powerup_delete_delayed();
									self notify ("powerup_grabbed");
									return;
								}
							}
						}
					}
				}

				//level thread zm_audio::sndAnnouncerPlayVox(self.powerup_name);
				self thread powerup_delete_delayed();
				self notify ("powerup_grabbed");
			}
		}
		wait 0.1;
	}
}

function powerup_vo(audio_name, team)
{
	self endon("disconnect");

	players = GetPlayers(team);
	
	players[0] PlaySoundToTeam(audio_name, team);
}

function powerup_wobble_fx()
{
	self endon("death"); 
	
	if (!isdefined(self))
	{
		return;
	}

	if (isdefined(level.powerup_fx_func))
	{
		self thread [[level.powerup_fx_func]]();
		return;
	}

	//wait(0.5); // must wait a bit because of the bug where a new entity has its events ignored on the client side //bumping it up from .1 to .5, this was failing in some instances
	/*
	if (self.only_affects_grabber)
	{
		//self clientfield::set(CLIENTFIELD_POWERUP_FX_NAME, CLIENTFIELD_POWERUP_FX_ONLY_AFFECTS_GRABBER_ON);
	}
	else if (self.any_team)
	{
		//self clientfield::set(CLIENTFIELD_POWERUP_FX_NAME, CLIENTFIELD_POWERUP_FX_ANY_TEAM_ON);
	}	
	else if (self.zombie_grabbable)
	{
		//self clientfield::set(CLIENTFIELD_POWERUP_FX_NAME, CLIENTFIELD_POWERUP_FX_ZOMBIE_GRABBABLE_ON);
	}
	else
	{
		//self clientfield::set(CLIENTFIELD_POWERUP_FX_NAME, CLIENTFIELD_POWERUP_FX_ON);
	}
	*/
}

function powerup_wobble()
{
	self endon("powerup_grabbed");
	self endon("powerup_timedout");

	self thread powerup_wobble_fx();

	while (isdefined(self))
	{
		waittime = randomfloatrange(2.5, 5);
		yaw = RandomInt(360);
		if(yaw > 300)
		{
			yaw = 300;
		}
		else if(yaw < 60)
		{
			yaw = 60;
		}
		yaw = self.angles[1] + yaw;
		new_angles = (-60 + randomint(120), yaw, -45 + randomint(90));
		self rotateto(new_angles, waittime, waittime * 0.5, waittime * 0.5);
		if (isdefined(self.worldgundw))
		{
			self.worldgundw rotateto(new_angles, waittime, waittime * 0.5, waittime * 0.5);
		}
		wait randomfloat(waittime - 0.1);
	}
}

function powerup_show(visible, who_can_grab)
{
	if (!visible) 
	{
		self ghost();
		if (isdefined(self.worldgundw))
		{
			self.worldgundw ghost();
		}
	}
	else
	{
		self show();
		if (isdefined(self.worldgundw))
		{
			self.worldgundw show();
		}
		if(isdefined(self.powerup_player))
		{
			self SetInvisibleToAll(); 
			self SetVisibleToPlayer(self.powerup_player); 
			if (isdefined(self.worldgundw))
			{
				self.worldgundw SetInvisibleToAll(); 
				self.worldgundw SetVisibleToPlayer(self.powerup_player); 
			}
		} else {
			self SetInvisibleToAll();
			for (i = 0; i < level.players.size; i++) {
				if (level.players[i].team == who_can_grab) {
					self SetVisibleToPlayer(level.players[i]); 
				}
			}
		}
	}
}

function powerup_timeout(who_can_grab)
{
	if(isdefined(level._powerup_timeout_override)&& !isdefined(self.powerup_team))
	{
		self thread [[level._powerup_timeout_override]]();
		return;
	}
	self endon("powerup_grabbed");
	self endon("death");
	self endon("powerup_reset");
	
	self powerup_show(true, who_can_grab);
	
	wait_time = 15;
	if (isdefined(level._powerup_timeout_custom_time))
	{
		time = [[level._powerup_timeout_custom_time]](self);
		if (time == 0)
		{
			return;
		}
		wait_time = time;
		
	}
	
	wait wait_time;

	for (i = 0; i < 40; i++)
	{
		// hide and show
		if (i % 2)
		{
			self powerup_show(false, who_can_grab);
		}
		else
		{
			self powerup_show(true, who_can_grab);
		}

		if (i < 15)
		{
			wait(0.5);
		}
		else if (i < 25)
		{
			wait(0.25);
		}
		else
		{
			wait(0.1);
		}
	}
	
	self notify("powerup_timedout");
	self powerup_delete();
}


function powerup_delete()
{
	ArrayRemoveValue(level.active_powerups,self,false);
	if (isdefined(self.worldgundw))
	{
		self.worldgundw delete();
	}
	self delete();
}

function powerup_delete_delayed(time)
{
	if (isdefined(time))
		wait time;
	else
		wait 0.01;
	self powerup_delete();
}

function func_should_never_drop()
{
	return false;
}

function func_should_always_drop()
{
	return true;
}

function powerup_move()
{
	self endon ("powerup_timedout");
	self endon ("powerup_grabbed");
	
	drag_speed = 75;
	while (1)
	{
		self waittill("move_powerup", moveto, distance);
		drag_vector = moveto - self.origin;
		range_squared = LengthSquared(drag_vector); //DistanceSquared(self.origin, self.drag_target);
		if (range_squared > distance * distance)
		{
			drag_vector = VectorNormalize(drag_vector);
			drag_vector = distance * drag_vector;
			moveto = self.origin + drag_vector;
		}
		self.origin = moveto;		
	}
}

function get_powerups(origin, radius)
{
	if (isdefined(origin) && isdefined(radius))
	{
		powerups = [];
		foreach(powerup in level.active_powerups)
		{
			if (DistanceSquared(origin, powerup.origin) < radius * radius)
			{
				powerups[powerups.size] = powerup;
			}
		}
		return powerups;
	}
    return level.active_powerups;
}

function add_powerup_hud( powerup, timer )
{
	if ( !isDefined( self.powerup_hud ) )
		self.powerup_hud = [];
	
	if( isDefined( self.powerup_hud[powerup] ) )
	{
		self.powerup_hud[powerup].time = timer; 
		return true; // tells to skip because powerup is already active 
	}
	
	self endon( "disconnect" );
	hud = NewClientHudElem( self );
	hud.powerup = powerup;
	hud.foreground = true;
	hud.hidewheninmenu = false;
	hud.alignX = "center";
	hud.alignY = "bottom";
	hud.horzAlign = "center";
	hud.vertAlign = "bottom";
	hud.x = hud.x;
	hud.y = hud.y - 50;
	hud.alpha = 1;
	hud SetShader( powerup , 64, 64 );
	hud scaleOverTime( .5, 32, 32 );
	hud.time = timer;
	hud thread harrybo21_blink_powerup_hud();
	//thread wait_til_timeout( self, hud ); 
	
	self.powerup_hud[ powerup ] = hud;
	
	a_keys = GetArrayKeys( self.powerup_hud );
	for ( i = 0; i < a_keys.size; i++ )
	 	self.powerup_hud[ a_keys[i] ] thread move_hud( .5, 0 - ( 24 * ( self.powerup_hud.size ) ) + ( i * 37.5 ) + 25, self.powerup_hud[ a_keys[i] ].y );
	
	return false; // powerup is not already active
}

function move_hud( time, x, y )
{
	self moveOverTime( time );
	self.x = x;
	self.y = y;
}

function harrybo21_blink_powerup_hud()
{
	self endon( "delete" );
	self endon( "stop_fade" );
	while( isDefined( self ) )
	{
		if ( self.time >= 20 )
		{
			self.alpha = 1; 
			wait .1;
			continue;
		}
		fade_time = 1;
		if ( self.time < 10 )
			fade_time = .5;
		if ( self.time < 5 )
			fade_time = .25;
			
		self fadeOverTime( fade_time );
		self.alpha = !self.alpha;
		
		wait( fade_time );
	}
}

function remove_powerup_hud( powerup )
{
	self.powerup_hud[ powerup ] destroy();
	self.powerup_hud[ powerup ] notify( "stop_fade" );
	self.powerup_hud[ powerup ] fadeOverTime( .2 );
	self.alpha = 0;
	wait .2;
	self.powerup_hud[ powerup ] delete();
	self.powerup_hud[ powerup ] = undefined;
	self.powerup_hud = array::remove_index( self.powerup_hud, self.powerup_hud[ powerup ], true );
	
	a_keys = GetArrayKeys( self.powerup_hud );
	for ( i = 0; i < a_keys.size; i++ )
	 	self.powerup_hud[ a_keys[i] ] thread move_hud( .5, 0 - ( 24 * ( self.powerup_hud.size ) ) + ( i * 37.5 ) + 25, self.powerup_hud[ a_keys[i] ].y );
}

/* TODO
//HUD powerup functions
function show_on_hud(player_team, str_powerup)
{
	self endon ("disconnect");
	
	str_index_on 	= "zombie_powerup_" + str_powerup + "_on";
	str_index_time 	= "zombie_powerup_" + str_powerup + "_time";

	// check to see if this is on or not
	if (level.zombie_vars[player_team][str_index_on])
	{
		// reset the time and keep going
		level.zombie_vars[player_team][str_index_time] = N_POWERUP_DEFAULT_TIME;
		return;
	}

	level.zombie_vars[player_team][str_index_on] = true;

	// set time remaining for powerup
	level thread time_remaining_on_powerup(player_team, str_powerup);
}
*/

function time_remaining_on_powerup(player_team, str_powerup)
{	
	str_index_on 	= "zombie_powerup_" + str_powerup + "_on";
	str_index_time 	= "zombie_powerup_" + str_powerup + "_time";
	str_sound_loop 	= "zmb_" + str_powerup + "_loop";
	str_sound_off 	= "zmb_" + str_powerup + "_loop_off";
	
	temp_ent = Spawn("script_origin", (0,0,0));
	temp_ent PlayLoopSound (str_sound_loop);
	
	// time it down!
	while (level.zombie_vars[player_team][str_index_time] >= 0)
	{
		WAIT_SERVER_FRAME;
		level.zombie_vars[player_team][str_index_time] = level.zombie_vars[player_team][str_index_time] - 0.05;
	}

	// turn off the timer
	level.zombie_vars[player_team][str_index_on] = false;
	
	GetPlayers()[0] PlaySoundToTeam(str_sound_off, player_team);

	temp_ent StopLoopSound(2);

	// remove the offset to make room for new powerups, reset timer for next time
	level.zombie_vars[player_team][str_index_time] = N_POWERUP_DEFAULT_TIME;

	temp_ent delete();
}
////////End HUD powerup functions

/@
"Name: register_powerup(<str_powerup>, [func_grab_powerup], [func_setup])"
"Module: Zombie Powerups"
"Summary: Registers functions to run when zombie perks are given to and taken from players."
"MandatoryArg: <str_powerup>: the name of the specialty that this perk uses. This should be unique, and will identify this perk in system scripts."
"OptionalArg: [func_grab_powerup]: this function will run when the player grabs the powerup."
"OptionalArg: [func_setup]: this function will in addition to normal powerup setup."	
"Example: register_powerup("nuke", &grab_nuke);"
"SPMP: multiplayer"
@/
function register_powerup(str_powerup, func_grab_powerup, func_setup)
{
	Assert(isdefined(str_powerup), "str_powerup is a required argument for register_powerup!");

	_register_undefined_powerup(str_powerup);
	
	if (isdefined(func_grab_powerup))
	{
		if (!isdefined(level._custom_powerups[str_powerup].grab_powerup))
		{
			level._custom_powerups[str_powerup].grab_powerup = func_grab_powerup;
		}
	}
	
	if (isdefined(func_setup))
	{
		if (!isdefined(level._custom_powerups[str_powerup].setup_powerup))
		{
			level._custom_powerups[str_powerup].setup_powerup = func_setup;
		}
	}	
}

// make sure powerup exists before we actually try to set fields on it. Does nothing if it exists already
function _register_undefined_powerup(str_powerup)
{
	if (!isdefined(level._custom_powerups))
	{
		level._custom_powerups = [];
	}
	
	if (!isdefined(level._custom_powerups[str_powerup]))
	{
		level._custom_powerups[str_powerup] = SpawnStruct();
		include_zombie_powerup(str_powerup);
	}	
}

/@
"Name: register_powerup_weapon(<str_powerup>, [func_grab_powerup], [func_setup])"
"Module: Zombie Powerups"
"Summary: Registers functions to run when zombie perks are given to and taken from players."
"MandatoryArg: <str_powerup>: the name of the specialty that this perk uses. This should be unique, and will identify this perk in system scripts."
"OptionalArg: [func_countdown]: this function will run when the weapon powerup counts down."
"Example: register_powerup_weapon("minigun", &minigun_countdown);"
"SPMP: multiplayer"
@/
function register_powerup_weapon(str_powerup, func_countdown)
{
	//Assert(isdefined(str_powerup), "str_powerup is a required argument for register_powerup!");

	_register_undefined_powerup(str_powerup);
	
	if (isdefined(func_countdown))
	{
		if (!isdefined(level._custom_powerups[str_powerup].weapon_countdown))
		{
			level._custom_powerups[str_powerup].weapon_countdown = func_countdown;
		}
	}
}

//Special weapon powerup functions

function weapon_powerup( ent_player, time, str_weapon, allow_cycling = false )
{
	str_weapon_on 			= "zombie_powerup_" + str_weapon + "_on";
	str_weapon_time_over 	= str_weapon + "_time_over";
	
	ent_player notify( "replace_weapon_powerup" );
	ent_player._show_solo_hud = true;
	
	ent_player.has_specific_powerup_weapon[ str_weapon ] = true;
	ent_player.has_powerup_weapon = true;
	
	if( allow_cycling )
	{
		ent_player EnableWeaponCycling();
	}
	
	ent_player._zombie_weapon_before_powerup[ str_weapon ] = ent_player GetCurrentWeapon();
	
	// give player the powerup weapon
	ent_player GiveWeapon( level.zombie_powerup_weapon[ str_weapon ] );
	ent_player SwitchToWeapon( level.zombie_powerup_weapon[ str_weapon ] );
	
	ent_player.zombie_vars[ str_weapon_on ] = true;
	
	level thread weapon_powerup_countdown( ent_player, str_weapon_time_over, time, str_weapon );
	level thread weapon_powerup_replace( ent_player, str_weapon_time_over, str_weapon );
	level thread weapon_powerup_change( ent_player, str_weapon_time_over, str_weapon );
}

function weapon_powerup_change( ent_player, str_gun_return_notify, str_weapon )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );
	
	while( 1 )
	{
		ent_player waittill( "weapon_change", newWeapon, oldWeapon );
	
		if( newWeapon != level.weaponNone && newWeapon != level.zombie_powerup_weapon[ str_weapon ] )
		{
			break;
		}
	}
	
	level thread weapon_powerup_remove( ent_player, str_gun_return_notify, str_weapon, false );
}

function weapon_powerup_countdown( ent_player, str_gun_return_notify, time, str_weapon )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );
	
	str_weapon_time = "zombie_powerup_" + str_weapon + "_time";
	
	ent_player.zombie_vars[str_weapon_time] = time;
		
	[[level._custom_powerups[ str_weapon ].weapon_countdown]]( ent_player, str_weapon_time );
	
	level thread weapon_powerup_remove( ent_player, str_gun_return_notify, str_weapon, true );	
}

function weapon_powerup_replace( ent_player, str_gun_return_notify, str_weapon )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( str_gun_return_notify );
	
	str_weapon_on 	= "zombie_powerup_" + str_weapon + "_on";

	ent_player waittill( "replace_weapon_powerup" );

	ent_player TakeWeapon( level.zombie_powerup_weapon[ str_weapon ] );
	
	ent_player.zombie_vars[ str_weapon_on ] = false;
	
	ent_player.has_specific_powerup_weapon[ str_weapon ] = false;
	ent_player.has_powerup_weapon = false;
}

function weapon_powerup_remove( ent_player, str_gun_return_notify, str_weapon, b_switch_back_weapon = true )
{
	ent_player endon( "death" );

	str_weapon_on 	= "zombie_powerup_" + str_weapon + "_on";
	
	// take the minigun back
	ent_player TakeWeapon( level.zombie_powerup_weapon[ str_weapon ] );
	
	ent_player.zombie_vars[ str_weapon_on ] = false;
	ent_player._show_solo_hud = false;
	
	ent_player.has_specific_powerup_weapon[ str_weapon ] = false;
	ent_player.has_powerup_weapon = false;
	
	// this gives the player back their weapons
	ent_player notify( str_gun_return_notify );
	

	if ( b_switch_back_weapon )
	{
		//ent_player zm_weapons::switch_back_primary_weapon(  );
		ent_player GiveWeapon(ent_player._zombie_weapon_before_powerup[str_weapon]);
		ent_player SwitchToWeapon(ent_player._zombie_weapon_before_powerup[str_weapon]);
	}
}
//END special weapon powerup functions

function get_table_items( filterSlot, blackList, search )
{
	items = [];

	for(i = 0; i < STATS_TABLE_MAX_ITEMS; i++)
	{
		row = TableLookupRowNum( level.statsTableID, STATS_TABLE_COL_NUMBERING, i );

		if ( row < 0 )
		{
			continue;
		}

		if ( isdefined( filterSlot ) )
		{
			slot = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_SLOT );
		
			if ( slot != filterSlot )
			{
				continue;
			}
		}
		
		ref = TableLookupColumnForRow( level.statsTableId, row, STATS_TABLE_COL_REFERENCE );
		
		if(IsDefined(blackList) && array::contains(blackList, ref))
		{
			continue;
		}

		name = TableLookupIString( level.statsTableID, STATS_TABLE_COL_NUMBERING, i, STATS_TABLE_COL_NAME );
		
		if(IsDefined(search) && search == ref)
			items[items.size] = name;
		else
			items[items.size] = ref;
	}

	return items;
}