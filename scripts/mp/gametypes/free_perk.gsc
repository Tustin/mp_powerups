#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\mp\gametypes\mp_powerups;

#insert scripts\mp\gametypes\mp_powerups.gsh;
#insert scripts\shared\statstable_shared.gsh;

#precache( "string", "ZOMBIE_POWERUP_FREE_PERK" );
#precache( "eventstring", "hud_refresh" );

#namespace mp_powerup_free_perk;

REGISTER_SYSTEM( "mp_powerup_free_perk", &__init__, undefined )

//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------


function __init__()
{
	mp_powerups::register_powerup("free_perk", &grab_free_perk);
	mp_powerups::add_mp_powerup("free_perk", 
		"perk_bottle_drop", 
		&"ZOMBIE_POWERUP_FREE_PERK",
		!POWERUP_ONLY_AFFECTS_GRABBER, 
		!POWERUP_ANY_TEAM,
		undefined);
}

function grab_free_perk( player )
{	
	if (!isdefined(player.free_perks)) {
		player.free_perks = [];
	}
	
	level thread free_perk_powerup(self, player );
}

function free_perk_powerup(item, player)
{
	if (player.sessionstate != "spectator" && IsAlive(player))
	{
		random_perk = player thread get_random_perk_doesnt_have();
		if (isdefined(random_perk)) {		
			//Add the unsplit perk to the array because that's what it looks for when finding a random perk
			player.free_perks[player.free_perks.size] = random_perk;
			//Some perks have multiple specialties, which are delimited by a pipe (|)
			perks = strtok(random_perk, "|");
			foreach (perk in perks) {
				player SetPerk(perk);
			}
			player LUINotifyEvent( &"hud_refresh", 0 );
			str = TableLookupIString(level.statsTableID, STATS_TABLE_COL_REFERENCE, random_perk, STATS_TABLE_COL_NAME);
			player LUINotifyEvent( &"score_event", 3, str, 1, 0 );
			WAIT_SERVER_FRAME;
			player hud::showPerks();
		}
	}
}

function get_random_perk_doesnt_have() {
	//just return if they have all the perks or else it'll just inf loop
	//temp_perks = strtok("specialty_additionalprimaryweapon,specialty_armorpiercing,specialty_armorvest,specialty_bulletaccuracy,specialty_bulletdamage,specialty_bulletflinch,specialty_bulletpenetration,specialty_deadshot,specialty_delayexplosive,specialty_detectexplosive,specialty_disarmexplosive,specialty_earnmoremomentum,specialty_explosivedamage,specialty_extraammo,specialty_fallheight,specialty_fastads,specialty_fastequipmentuse,specialty_fastladderclimb,specialty_fastmantle,specialty_fastmeleerecovery,specialty_fastreload,specialty_fasttoss,specialty_fastweaponswitch,specialty_finalstand,specialty_fireproof,specialty_flakjacket,specialty_flashprotection,specialty_gpsjammer,specialty_grenadepulldeath,specialty_healthregen,specialty_holdbreath,specialty_immunecounteruav,specialty_immuneemp,specialty_immunemms,specialty_immunenvthermal,specialty_immunerangefinder,specialty_killstreak,specialty_longersprint,specialty_loudenemies,specialty_marksman,specialty_movefaster,specialty_nomotionsensor,specialty_noname,specialty_nottargetedbyairsupport,specialty_nokillstreakreticle,specialty_nottargettedbysentry,specialty_pin_back,specialty_pistoldeath,specialty_proximityprotection,specialty_quickrevive,specialty_quieter,specialty_reconnaissance,specialty_rof,specialty_scavenger,specialty_showenemyequipment,specialty_stunprotection,specialty_shellshock,specialty_sprintrecovery,specialty_showonradar,specialty_stalker,specialty_twogrenades,specialty_twoprimaries,specialty_unlimitedsprint", ",");
	
	if (self.free_perks.size >= level.availablePerks.size) {
		self IPrintLnBold("You already have all perks!");
		return undefined;
	}

	do {
		random_perk = array::random(level.availablePerks);
	} while (array::contains(self.free_perks, random_perk) || self HasPerk(strtok(random_perk, "|")[0]));

	return random_perk;
}