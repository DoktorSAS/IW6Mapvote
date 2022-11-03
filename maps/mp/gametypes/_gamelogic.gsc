// IW6 GSC SOURCE
// Decompiled by https://github.com/xensik/gsc-tool

onforfeit( var_0 )
{
    if ( isdefined( level.forfeitinprogress ) )
        return;

    level endon( "abort_forfeit" );
    level thread forfeitwaitforabort();
    level.forfeitinprogress = 1;

    if ( !level.teambased && level.players.size > 1 )
        wait 10;
    else
        wait 1.05;

    level.forfeit_aborted = 0;
    var_1 = 20.0;
    matchforfeittimer( var_1 );
    var_2 = &"";

    if ( !isdefined( var_0 ) )
    {
        level.finalkillcam_winner = "none";
        var_2 = game["end_reason"]["players_forfeited"];
        var_3 = level.players[0];
    }
    else if ( var_0 == "axis" )
    {
        level.finalkillcam_winner = "axis";
        var_2 = game["end_reason"]["allies_forfeited"];
        var_3 = "axis";
    }
    else if ( var_0 == "allies" )
    {
        level.finalkillcam_winner = "allies";
        var_2 = game["end_reason"]["axis_forfeited"];
        var_3 = "allies";
    }
    else if ( level.multiteambased && issubstr( var_0, "team_" ) )
        var_3 = var_0;
    else
    {
        level.finalkillcam_winner = "none";
        var_3 = "tie";
    }

    level.forcedend = 1;

    if ( isplayer( var_3 ) )
        logstring( "forfeit, win: " + var_3 getxuid() + "(" + var_3.name + ")" );
    else
        logstring( "forfeit, win: " + var_3 + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

    thread endgame( var_3, var_2 );
}

forfeitwaitforabort()
{
    level endon( "game_ended" );
    level waittill( "abort_forfeit" );
    level.forfeit_aborted = 1;
    setomnvar( "ui_match_start_countdown", 0 );
}

matchforfeittimer_internal( var_0 )
{
    waittillframeend;
    level endon( "match_forfeit_timer_beginning" );

    while ( var_0 > 0 && !level.gameended && !level.forfeit_aborted && !level.ingraceperiod )
    {
        setomnvar( "ui_match_start_countdown", var_0 );
        var_0--;
        maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause( 1.0 );
    }

    setomnvar( "ui_match_start_countdown", 0 );
}

matchforfeittimer( var_0 )
{
    level notify( "match_forfeit_timer_beginning" );
    var_1 = int( var_0 );
    setomnvar( "ui_match_start_text", "opponent_forfeiting_in" );
    matchforfeittimer_internal( var_1 );
}

default_ondeadevent( var_0 )
{
    level.finalkillcam_winner = "none";

    if ( var_0 == "allies" )
    {
        iprintln( &"MP_GHOSTS_ELIMINATED" );
        logstring( "team eliminated, win: opfor, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
        level.finalkillcam_winner = "axis";
        thread endgame( "axis", game["end_reason"]["allies_eliminated"] );
    }
    else if ( var_0 == "axis" )
    {
        iprintln( &"MP_FEDERATION_ELIMINATED" );
        logstring( "team eliminated, win: allies, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
        level.finalkillcam_winner = "allies";
        thread endgame( "allies", game["end_reason"]["axis_eliminated"] );
    }
    else
    {
        logstring( "tie, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
        level.finalkillcam_winner = "none";

        if ( level.teambased )
            thread endgame( "tie", game["end_reason"]["tie"] );
        else
            thread endgame( undefined, game["end_reason"]["tie"] );
    }
}

default_ononeleftevent( var_0 )
{
    if ( level.teambased )
    {
        var_1 = maps\mp\_utility::getlastlivingplayer( var_0 );

        if ( isdefined( var_1 ) )
            var_1 thread givelastonteamwarning();
    }
    else
    {
        var_1 = maps\mp\_utility::getlastlivingplayer();
        logstring( "last one alive, win: " + var_1.name );
        level.finalkillcam_winner = "none";
        thread endgame( var_1, game["end_reason"]["enemies_eliminated"] );
    }

    return 1;
}

default_ontimelimit()
{
    var_0 = undefined;
    level.finalkillcam_winner = "none";

    if ( level.teambased )
    {
        if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
            var_0 = "tie";
        else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
        {
            level.finalkillcam_winner = "axis";
            var_0 = "axis";
        }
        else
        {
            level.finalkillcam_winner = "allies";
            var_0 = "allies";
        }

        logstring( "time limit, win: " + var_0 + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
    }
    else
    {
        var_0 = maps\mp\gametypes\_gamescore::gethighestscoringplayer();

        if ( isdefined( var_0 ) )
            logstring( "time limit, win: " + var_0.name );
        else
            logstring( "time limit, tie" );
    }

    thread endgame( var_0, game["end_reason"]["time_limit_reached"] );
}

default_onhalftime()
{
    var_0 = undefined;
    level.finalkillcam_winner = "none";
    thread endgame( "halftime", game["end_reason"]["time_limit_reached"] );
}

forceend( var_0 )
{
    if ( level.hostforcedend || level.forcedend )
        return;

    var_1 = undefined;
    level.finalkillcam_winner = "none";

    if ( level.teambased )
    {
        if ( getdvarint( "squad_match" ) == 1 && isdefined( var_0 ) && var_0 == 2 )
            var_1 = "axis";
        else if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
            var_1 = "tie";
        else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
        {
            level.finalkillcam_winner = "axis";
            var_1 = "axis";
        }
        else
        {
            level.finalkillcam_winner = "allies";
            var_1 = "allies";
        }

        logstring( "host ended game, win: " + var_1 + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
    }
    else
    {
        var_1 = maps\mp\gametypes\_gamescore::gethighestscoringplayer();

        if ( isdefined( var_1 ) )
            logstring( "host ended game, win: " + var_1.name );
        else
            logstring( "host ended game, tie" );
    }

    level.forcedend = 1;
    level.hostforcedend = 1;

    if ( level.splitscreen )
        var_2 = game["end_reason"]["ended_game"];
    else
        var_2 = game["end_reason"]["host_ended_game"];

    if ( isdefined( var_0 ) && var_0 == 2 )
        var_2 = game["end_reason"]["allies_forfeited"];

    level notify( "force_end" );
    thread endgame( var_1, var_2 );
}

onscorelimit()
{
    var_0 = game["end_reason"]["score_limit_reached"];
    var_1 = undefined;
    level.finalkillcam_winner = "none";

    if ( level.multiteambased )
    {
        var_1 = maps\mp\gametypes\_gamescore::getwinningteam();

        if ( var_1 == "none" )
            var_1 = "tie";
    }
    else if ( level.teambased )
    {
        if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
            var_1 = "tie";
        else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
        {
            var_1 = "axis";
            level.finalkillcam_winner = "axis";
        }
        else
        {
            var_1 = "allies";
            level.finalkillcam_winner = "allies";
        }

        logstring( "scorelimit, win: " + var_1 + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
    }
    else
    {
        var_1 = maps\mp\gametypes\_gamescore::gethighestscoringplayer();

        if ( isdefined( var_1 ) )
            logstring( "scorelimit, win: " + var_1.name );
        else
            logstring( "scorelimit, tie" );
    }

    thread endgame( var_1, var_0 );
    return 1;
}

updategameevents()
{
    if ( maps\mp\_utility::matchmakinggame() && !level.ingraceperiod && ( !isdefined( level.disableforfeit ) || !level.disableforfeit ) )
    {
        if ( level.multiteambased )
        {
            var_0 = 0;
            var_1 = 0;

            for ( var_2 = 0; var_2 < level.teamnamelist.size; var_2++ )
            {
                var_0 += level.teamcount[level.teamnamelist[var_2]];

                if ( level.teamcount[level.teamnamelist[var_2]] )
                    var_1 += 1;
            }

            for ( var_2 = 0; var_2 < level.teamnamelist.size; var_2++ )
            {
                if ( var_0 == level.teamcount[level.teamnamelist[var_2]] && game["state"] == "playing" )
                {
                    thread onforfeit( level.teamnamelist[var_2] );
                    return;
                }
            }

            if ( var_1 > 1 )
            {
                level.forfeitinprogress = undefined;
                level notify( "abort_forfeit" );
            }
        }
        else if ( level.teambased )
        {
            if ( level.teamcount["allies"] < 1 && level.teamcount["axis"] > 0 && game["state"] == "playing" )
            {
                thread onforfeit( "axis" );
                return;
            }

            if ( level.teamcount["axis"] < 1 && level.teamcount["allies"] > 0 && game["state"] == "playing" )
            {
                thread onforfeit( "allies" );
                return;
            }

            if ( level.teamcount["axis"] > 0 && level.teamcount["allies"] > 0 )
            {
                level.forfeitinprogress = undefined;
                level notify( "abort_forfeit" );
            }
        }
        else
        {
            if ( level.teamcount["allies"] + level.teamcount["axis"] == 1 && level.maxplayercount > 1 )
            {
                thread onforfeit();
                return;
            }

            if ( level.teamcount["axis"] + level.teamcount["allies"] > 1 )
            {
                level.forfeitinprogress = undefined;
                level notify( "abort_forfeit" );
            }
        }
    }

    if ( !maps\mp\_utility::getgametypenumlives() && ( !isdefined( level.disablespawning ) || !level.disablespawning ) )
        return;

    if ( !maps\mp\_utility::gamehasstarted() )
        return;

    if ( level.ingraceperiod )
        return;

    if ( level.multiteambased )
        return;

    if ( level.teambased )
    {
        var_3["allies"] = level.livescount["allies"];
        var_3["axis"] = level.livescount["axis"];

        if ( isdefined( level.disablespawning ) && level.disablespawning )
        {
            var_3["allies"] = 0;
            var_3["axis"] = 0;
        }

        if ( !level.alivecount["allies"] && !level.alivecount["axis"] && !var_3["allies"] && !var_3["axis"] )
            return [[ level.ondeadevent ]]( "all" );

        if ( !level.alivecount["allies"] && !var_3["allies"] )
            return [[ level.ondeadevent ]]( "allies" );

        if ( !level.alivecount["axis"] && !var_3["axis"] )
            return [[ level.ondeadevent ]]( "axis" );

        var_4 = level.alivecount["allies"] == 1 && !var_3["allies"];
        var_5 = level.alivecount["axis"] == 1 && !var_3["axis"];

        if ( var_4 || var_5 )
        {
            var_6 = undefined;

            if ( var_4 && !isdefined( level.onelefttime["allies"] ) )
            {
                level.onelefttime["allies"] = gettime();
                var_7 = [[ level.ononeleftevent ]]( "allies" );

                if ( isdefined( var_7 ) )
                {
                    if ( !isdefined( var_6 ) )
                        var_6 = var_7;

                    var_6 = var_6 || var_7;
                }
            }

            if ( var_5 && !isdefined( level.onelefttime["axis"] ) )
            {
                level.onelefttime["axis"] = gettime();
                var_8 = [[ level.ononeleftevent ]]( "axis" );

                if ( isdefined( var_8 ) )
                {
                    if ( !isdefined( var_6 ) )
                        var_6 = var_8;

                    var_6 = var_6 || var_8;
                }
            }

            return var_6;
            return;
        }
    }
    else
    {
        if ( !level.alivecount["allies"] && !level.alivecount["axis"] && ( !level.livescount["allies"] && !level.livescount["axis"] ) )
            return [[ level.ondeadevent ]]( "all" );

        var_9 = maps\mp\_utility::getpotentiallivingplayers();

        if ( var_9.size == 1 )
            return [[ level.ononeleftevent ]]( "all" );
    }
}

waittillfinalkillcamdone()
{
    if ( !isdefined( level.finalkillcam_winner ) )
    {
        return 0;
    }
        

    level waittill( "final_killcam_done" );
    return 1;
}

timelimitclock_intermission( var_0 )
{
    setgameendtime( gettime() + int( var_0 * 1000 ) );
    var_1 = spawn( "script_origin", ( 0.0, 0.0, 0.0 ) );
    var_1 hide();

    if ( var_0 >= 10.0 )
        wait(var_0 - 10.0);

    for (;;)
    {
        var_1 playsound( "ui_mp_timer_countdown" );
        wait 1.0;
    }
}

waitforplayers( var_0 )
{
    var_1 = gettime();
    var_2 = var_1 + var_0 * 1000 - 200;

    if ( var_0 > 5 )
        var_3 = gettime() + getdvarint( "min_wait_for_players" ) * 1000;
    else
        var_3 = 0;

    var_4 = level.connectingplayers / 3;

    for (;;)
    {
        if ( isdefined( game["roundsPlayed"] ) && game["roundsPlayed"] )
            break;

        var_5 = level.maxplayercount;
        var_6 = gettime();

        if ( var_5 >= var_4 && var_6 > var_3 || var_6 > var_2 )
            break;

        wait 0.05;
    }
}

prematchperiod()
{
    level endon( "game_ended" );
    level.connectingplayers = getdvarint( "party_partyPlayerCountNum" );

    if ( level.prematchperiod > 0 )
        matchstarttimerwaitforplayers();
    else
        matchstarttimerskip();

    foreach ( var_1 in level.players )
    {
        var_1 maps\mp\_utility::freezecontrolswrapper( 0 );
        var_1 enableweapons();

        if ( !isdefined( var_1.pers["team"] ) )
            continue;

        var_2 = var_1.pers["team"];
        var_3 = maps\mp\_utility::getobjectivehinttext( var_2 );

        if ( !isdefined( var_3 ) || !var_1.hasspawned )
            continue;

        var_4 = 0;

        if ( game["defenders"] == var_2 )
            var_4 = 1;

        var_1 setclientomnvar( "ui_objective_text", var_4 );
    }

    if ( game["state"] != "playing" )
        return;
}

graceperiod()
{
    level endon( "game_ended" );

    if ( !isdefined( game["clientActive"] ) )
    {
        while ( getactiveclientcount() == 0 )
            wait 0.05;

        game["clientActive"] = 1;
    }

    while ( level.ingraceperiod > 0 )
    {
        wait 1.0;
        level.ingraceperiod--;
    }

    level notify( "grace_period_ending" );
    wait 0.05;
    maps\mp\_utility::gameflagset( "graceperiod_done" );
    level.ingraceperiod = 0;

    if ( game["state"] != "playing" )
        return;

    if ( maps\mp\_utility::getgametypenumlives() )
    {
        var_0 = level.players;

        for ( var_1 = 0; var_1 < var_0.size; var_1++ )
        {
            var_2 = var_0[var_1];

            if ( !var_2.hasspawned && var_2.sessionteam != "spectator" && !isalive( var_2 ) )
                var_2.statusicon = "hud_status_dead";
        }
    }

    level thread updategameevents();
}

sethasdonecombat( var_0, var_1 )
{
    var_0.hasdonecombat = var_1;
    var_2 = !isdefined( var_0.hasdoneanycombat ) || !var_0.hasdoneanycombat;

    if ( var_2 && var_1 )
    {
        var_0.hasdoneanycombat = 1;

        if ( isdefined( var_0.pers["hasMatchLoss"] ) && var_0.pers["hasMatchLoss"] )
            return;

        if ( !maps\mp\_utility::is_aliens() )
            updatelossstats( var_0 );
    }
}

updatewinstats( var_0 )
{
    if ( !var_0 maps\mp\_utility::rankingenabled() )
        return;

    if ( !isdefined( var_0.hasdoneanycombat ) || !var_0.hasdoneanycombat )
        return;

    if ( !issquadsmode() )
    {
        var_0 maps\mp\gametypes\_persistence::statadd( "losses", -1 );
        var_0 maps\mp\gametypes\_persistence::statadd( "wins", 1 );
        var_0 maps\mp\_utility::updatepersratio( "winLossRatio", "wins", "losses" );
        var_0 maps\mp\gametypes\_persistence::statadd( "currentWinStreak", 1 );
        var_1 = var_0 maps\mp\gametypes\_persistence::statget( "currentWinStreak" );

        if ( var_1 > var_0 maps\mp\gametypes\_persistence::statget( "winStreak" ) )
            var_0 maps\mp\gametypes\_persistence::statset( "winStreak", var_1 );
    }

    var_0 maps\mp\gametypes\_persistence::statsetchild( "round", "win", 1 );
    var_0 maps\mp\gametypes\_persistence::statsetchild( "round", "loss", 0 );
}

updatelossstats( var_0 )
{
    if ( !var_0 maps\mp\_utility::rankingenabled() )
        return;

    if ( !isdefined( var_0.hasdoneanycombat ) || !var_0.hasdoneanycombat )
        return;

    var_0.pers["hasMatchLoss"] = 1;

    if ( !issquadsmode() )
    {
        var_0 maps\mp\gametypes\_persistence::statadd( "losses", 1 );
        var_0 maps\mp\_utility::updatepersratio( "winLossRatio", "wins", "losses" );
        maps\mp\gametypes\_persistence::statadd( "gamesPlayed", 1 );
    }

    var_0 maps\mp\gametypes\_persistence::statsetchild( "round", "loss", 1 );
}

updatetiestats( var_0 )
{
    if ( !var_0 maps\mp\_utility::rankingenabled() )
        return;

    if ( !isdefined( var_0.hasdoneanycombat ) || !var_0.hasdoneanycombat )
        return;

    if ( !issquadsmode() )
    {
        var_0 maps\mp\gametypes\_persistence::statadd( "losses", -1 );
        var_0 maps\mp\gametypes\_persistence::statadd( "ties", 1 );
        var_0 maps\mp\_utility::updatepersratio( "winLossRatio", "wins", "losses" );
        var_0 maps\mp\gametypes\_persistence::statset( "currentWinStreak", 0 );
    }

    var_0 maps\mp\gametypes\_persistence::statsetchild( "round", "loss", 0 );
}

updatewinlossstats( var_0 )
{
    if ( maps\mp\_utility::privatematch() )
        return;

    if ( !maps\mp\_utility::waslastround() )
        return;

    var_1 = level.players;
    updateplayercombatstatus();

    if ( !isdefined( var_0 ) || isdefined( var_0 ) && isstring( var_0 ) && var_0 == "tie" )
    {
        foreach ( var_3 in level.players )
        {
            if ( isdefined( var_3.connectedpostgame ) )
                continue;

            if ( level.hostforcedend && var_3 ishost() )
            {
                if ( !issquadsmode() )
                    var_3 maps\mp\gametypes\_persistence::statset( "currentWinStreak", 0 );

                continue;
            }

            updatetiestats( var_3 );
        }
    }
    else if ( isplayer( var_0 ) )
    {
        if ( level.hostforcedend && var_0 ishost() )
        {
            if ( !issquadsmode() )
                var_0 maps\mp\gametypes\_persistence::statset( "currentWinStreak", 0 );

            return;
        }

        updatewinstats( var_0 );
    }
    else if ( isstring( var_0 ) )
    {
        foreach ( var_3 in level.players )
        {
            if ( isdefined( var_3.connectedpostgame ) )
                continue;

            if ( level.hostforcedend && var_3 ishost() )
            {
                if ( !issquadsmode() )
                    var_3 maps\mp\gametypes\_persistence::statset( "currentWinStreak", 0 );

                continue;
            }

            if ( var_0 == "tie" )
            {
                updatetiestats( var_3 );
                continue;
            }

            if ( var_3.pers["team"] == var_0 )
            {
                updatewinstats( var_3 );
                continue;
            }

            if ( !issquadsmode() )
                var_3 maps\mp\gametypes\_persistence::statset( "currentWinStreak", 0 );
        }
    }
}

updateplayercombatstatus()
{
    if ( level.gametype != "infect" )
        return;

    foreach ( var_1 in level.players )
    {
        if ( var_1.sessionstate == "spectator" && !var_1.spectatekillcam )
            continue;
        else if ( isdefined( var_1.hasdoneanycombat ) && var_1.hasdoneanycombat )
            continue;
        else if ( var_1.team == "axis" )
            continue;
        else
            var_1 sethasdonecombat( var_1, 1 );
    }
}

freezeplayerforroundend( var_0 )
{
    self endon( "disconnect" );
    maps\mp\_utility::clearlowermessages();

    if ( !isdefined( var_0 ) )
        var_0 = 0.05;

    wait(var_0);
    maps\mp\_utility::freezecontrolswrapper( 1 );
}

updatematchbonusscores( var_0 )
{
    if ( !game["timePassed"] )
        return;

    if ( !maps\mp\_utility::matchmakinggame() )
        return;

    if ( !maps\mp\_utility::gettimelimit() || level.forcedend )
    {
        var_1 = maps\mp\_utility::gettimepassed() / 1000;
        var_1 = min( var_1, 1200 );
    }
    else
        var_1 = maps\mp\_utility::gettimelimit() * 60;

    if ( level.teambased )
    {
        if ( var_0 == "allies" )
        {
            var_2 = "allies";
            var_3 = "axis";
        }
        else if ( var_0 == "axis" )
        {
            var_2 = "axis";
            var_3 = "allies";
        }
        else
        {
            var_2 = "tie";
            var_3 = "tie";
        }

        if ( var_2 != "tie" )
        {
            var_4 = maps\mp\gametypes\_rank::getscoreinfovalue( "win" );
            var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "loss" );
            setwinningteam( var_2 );
        }
        else
        {
            var_4 = maps\mp\gametypes\_rank::getscoreinfovalue( "tie" );
            var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "tie" );
        }

        foreach ( var_7 in level.players )
        {
            if ( isdefined( var_7.connectedpostgame ) )
                continue;

            if ( !var_7 maps\mp\_utility::rankingenabled() )
                continue;

            if ( var_7.timeplayed["total"] < 1 || var_7.pers["participation"] < 1 )
            {
                var_7 thread maps\mp\gametypes\_rank::endgameupdate();
                continue;
            }

            if ( level.hostforcedend && var_7 ishost() )
                continue;

            if ( !isdefined( var_7.hasdoneanycombat ) || !var_7.hasdoneanycombat )
                continue;

            var_8 = var_7 maps\mp\gametypes\_rank::getspm();

            if ( var_2 == "tie" )
            {
                var_9 = int( var_4 * ( var_1 / 60 * var_8 ) * var_7.timeplayed["total"] / var_1 );
                var_7 thread givematchbonus( "tie", var_9 );
                var_7.matchbonus = var_9;
                continue;
            }

            if ( isdefined( var_7.pers["team"] ) && var_7.pers["team"] == var_2 )
            {
                var_9 = int( var_4 * ( var_1 / 60 * var_8 ) * var_7.timeplayed["total"] / var_1 );
                var_7 thread givematchbonus( "win", var_9 );
                var_7.matchbonus = var_9;
                continue;
            }

            if ( isdefined( var_7.pers["team"] ) && var_7.pers["team"] == var_3 )
            {
                var_9 = int( var_5 * ( var_1 / 60 * var_8 ) * var_7.timeplayed["total"] / var_1 );
                var_7 thread givematchbonus( "loss", var_9 );
                var_7.matchbonus = var_9;
            }
        }
    }
    else
    {
        if ( isdefined( var_0 ) )
        {
            var_4 = maps\mp\gametypes\_rank::getscoreinfovalue( "win" );
            var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "loss" );
        }
        else
        {
            var_4 = maps\mp\gametypes\_rank::getscoreinfovalue( "tie" );
            var_5 = maps\mp\gametypes\_rank::getscoreinfovalue( "tie" );
        }

        foreach ( var_7 in level.players )
        {
            if ( isdefined( var_7.connectedpostgame ) )
                continue;

            if ( var_7.timeplayed["total"] < 1 || var_7.pers["participation"] < 1 )
            {
                var_7 thread maps\mp\gametypes\_rank::endgameupdate();
                continue;
            }

            if ( !isdefined( var_7.hasdoneanycombat ) || !var_7.hasdoneanycombat )
                continue;

            var_8 = var_7 maps\mp\gametypes\_rank::getspm();
            var_12 = 0;

            for ( var_13 = 0; var_13 < min( level.placement["all"].size, 3 ); var_13++ )
            {
                if ( level.placement["all"][var_13] != var_7 )
                    continue;

                var_12 = 1;
            }

            if ( var_12 )
            {
                var_9 = int( var_4 * ( var_1 / 60 * var_8 ) * var_7.timeplayed["total"] / var_1 );
                var_7 thread givematchbonus( "win", var_9 );
                var_7.matchbonus = var_9;
                continue;
            }

            var_9 = int( var_5 * ( var_1 / 60 * var_8 ) * var_7.timeplayed["total"] / var_1 );
            var_7 thread givematchbonus( "loss", var_9 );
            var_7.matchbonus = var_9;
        }
    }
}

givematchbonus( var_0, var_1 )
{
    self endon( "disconnect" );
    level waittill( "give_match_bonus" );
    maps\mp\gametypes\_rank::giverankxp( var_0, var_1 );
    maps\mp\gametypes\_rank::endgameupdate();
}

setxenonranks( var_0 )
{
    var_1 = level.players;

    for ( var_2 = 0; var_2 < var_1.size; var_2++ )
    {
        var_3 = var_1[var_2];

        if ( !isdefined( var_3.score ) || !isdefined( var_3.pers["team"] ) )
            continue;
    }

    for ( var_2 = 0; var_2 < var_1.size; var_2++ )
    {
        var_3 = var_1[var_2];

        if ( !isdefined( var_3.score ) || !isdefined( var_3.pers["team"] ) )
            continue;

        var_4 = var_3.score;

        if ( maps\mp\_utility::getminutespassed() )
            var_4 = var_3.score / maps\mp\_utility::getminutespassed();

        setplayerteamrank( var_3, var_3.clientid, int( var_4 ) );
    }
}

checktimelimit( var_0 )
{
    if ( isdefined( level.timelimitoverride ) && level.timelimitoverride )
        return;

    if ( game["state"] != "playing" )
    {
        setgameendtime( 0 );
        return;
    }

    if ( maps\mp\_utility::gettimelimit() <= 0 )
    {
        if ( isdefined( level.starttime ) )
            setgameendtime( level.starttime );
        else
            setgameendtime( 0 );

        return;
    }

    if ( !maps\mp\_utility::gameflag( "prematch_done" ) )
    {
        setgameendtime( 0 );
        return;
    }

    if ( !isdefined( level.starttime ) )
        return;

    if ( maps\mp\_utility::gettimepassedpercentage() > level.timepercentagecutoff )
        setnojiptime( 1 );

    var_1 = gettimeremaining();
    setgameendtime( gettime() + int( var_1 ) );

    if ( var_1 > 0 )
        return;

    [[ level.ontimelimit ]]();
}

gettimeremaining()
{
    return maps\mp\_utility::gettimelimit() * 60 * 1000 - maps\mp\_utility::gettimepassed();
}

gettimeremainingpercentage()
{
    var_0 = maps\mp\_utility::gettimelimit() * 60 * 1000;
    return ( var_0 - maps\mp\_utility::gettimepassed() ) / var_0;
}

checkteamscorelimitsoon( var_0 )
{
    if ( maps\mp\_utility::getwatcheddvar( "scorelimit" ) <= 0 || maps\mp\_utility::isobjectivebased() )
        return;

    if ( isdefined( level.scorelimitoverride ) && level.scorelimitoverride )
        return;

    if ( level.gametype == "conf" || level.gametype == "jugg" )
        return;

    if ( !level.teambased )
        return;

    if ( maps\mp\_utility::gettimepassed() < 60000 )
        return;

    var_1 = estimatedtimetillscorelimit( var_0 );

    if ( var_1 < 2 )
        level notify( "match_ending_soon", "score" );
}

checkplayerscorelimitsoon()
{
    if ( maps\mp\_utility::getwatcheddvar( "scorelimit" ) <= 0 || maps\mp\_utility::isobjectivebased() )
        return;

    if ( level.teambased )
        return;

    if ( maps\mp\_utility::gettimepassed() < 60000 )
        return;

    var_0 = estimatedtimetillscorelimit();

    if ( var_0 < 2 )
        level notify( "match_ending_soon", "score" );
}

checkscorelimit()
{
    if ( maps\mp\_utility::isobjectivebased() )
        return 0;

    if ( isdefined( level.scorelimitoverride ) && level.scorelimitoverride )
        return 0;

    if ( game["state"] != "playing" )
        return 0;

    if ( maps\mp\_utility::getwatcheddvar( "scorelimit" ) <= 0 )
        return 0;

    if ( level.teambased )
    {
        var_0 = 0;

        for ( var_1 = 0; var_1 < level.teamnamelist.size; var_1++ )
        {
            if ( game["teamScores"][level.teamnamelist[var_1]] >= maps\mp\_utility::getwatcheddvar( "scorelimit" ) )
                var_0 = 1;
        }

        if ( !var_0 )
            return 0;
    }
    else
    {
        if ( !isplayer( self ) )
            return 0;

        if ( self.score < maps\mp\_utility::getwatcheddvar( "scorelimit" ) )
            return 0;
    }

    return onscorelimit();
}

updategametypedvars()
{
    level endon( "game_ended" );

    while ( game["state"] == "playing" )
    {
        if ( isdefined( level.starttime ) )
        {
            if ( gettimeremaining() < 3000 )
            {
                wait 0.1;
                continue;
            }
        }

        wait 1;
    }
}

matchstarttimerwaitforplayers()
{
    thread matchstarttimer( "match_starting_in", level.prematchperiod + level.prematchperiodend );
    waitforplayers( level.prematchperiod );

    if ( level.prematchperiodend > 0 && !isdefined( level.hostmigrationtimer ) )
    {
        var_0 = level.prematchperiodend;

        if ( maps\mp\_utility::isroundbased() && !maps\mp\_utility::isfirstround() || maps\mp\_utility::ismlgmatch() )
            var_0 = level.prematchperiod;

        matchstarttimer( "match_starting_in", var_0 );
    }
}

matchstarttimer_internal( var_0 )
{
    waittillframeend;
    introvisionset();
    level endon( "match_start_timer_beginning" );

    while ( var_0 > 0 && !level.gameended )
    {
        setomnvar( "ui_match_start_countdown", var_0 );

        if ( var_0 == 0 )
            visionsetnaked( "", 0 );

        var_0--;
        wait 1.0;
    }

    setomnvar( "ui_match_start_countdown", 0 );
}

matchstarttimer( var_0, var_1 )
{
    self notify( "matchStartTimer" );
    self endon( "matchStartTimer" );
    level notify( "match_start_timer_beginning" );
    var_2 = int( var_1 );

    if ( var_2 >= 2 )
    {
        setomnvar( "ui_match_start_text", var_0 );
        matchstarttimer_internal( var_2 );
        visionsetnaked( "", 3.0 );
    }
    else
    {
        introvisionset();
        visionsetnaked( "", 1.0 );
    }
}

introvisionset()
{
    if ( !isdefined( level.introvisionset ) )
        level.introvisionset = "mpIntro";

    visionsetnaked( level.introvisionset, 0 );
}

matchstarttimerskip()
{
    visionsetnaked( "", 0 );
}

onroundswitch()
{
    if ( !isdefined( game["switchedsides"] ) )
        game["switchedsides"] = 0;

    if ( game["roundsWon"]["allies"] == maps\mp\_utility::getwatcheddvar( "winlimit" ) - 1 && game["roundsWon"]["axis"] == maps\mp\_utility::getwatcheddvar( "winlimit" ) - 1 )
    {
        var_0 = getbetterteam();

        if ( var_0 != game["defenders"] )
        {
            game["switchedsides"] = !game["switchedsides"];
            level.switchedsides = 1;
        }
        else
            level.switchedsides = undefined;

        level.halftimetype = "overtime";
    }
    else
    {
        level.halftimetype = "halftime";
        game["switchedsides"] = !game["switchedsides"];
        level.switchedsides = 1;
    }
}

checkroundswitch()
{
    if ( !level.teambased )
        return 0;

    if ( !isdefined( level.roundswitch ) || !level.roundswitch )
        return 0;

    if ( game["roundsPlayed"] % level.roundswitch == 0 )
    {
        onroundswitch();
        return 1;
    }

    return 0;
}

timeuntilroundend()
{
    if ( level.gameended )
    {
        var_0 = ( gettime() - level.gameendtime ) / 1000;
        var_1 = level.postroundtime - var_0;

        if ( var_1 < 0 )
            return 0;

        return var_1;
    }

    if ( maps\mp\_utility::gettimelimit() <= 0 )
        return undefined;

    if ( !isdefined( level.starttime ) )
        return undefined;

    var_2 = maps\mp\_utility::gettimelimit();
    var_0 = ( gettime() - level.starttime ) / 1000;
    var_1 = maps\mp\_utility::gettimelimit() * 60 - var_0;

    if ( isdefined( level.timepaused ) )
        var_1 += level.timepaused;

    return var_1 + level.postroundtime;
}

freegameplayhudelems()
{
    if ( isdefined( self.perkicon ) )
    {
        if ( isdefined( self.perkicon[0] ) )
        {
            self.perkicon[0] maps\mp\gametypes\_hud_util::destroyelem();
            self.perkname[0] maps\mp\gametypes\_hud_util::destroyelem();
        }

        if ( isdefined( self.perkicon[1] ) )
        {
            self.perkicon[1] maps\mp\gametypes\_hud_util::destroyelem();
            self.perkname[1] maps\mp\gametypes\_hud_util::destroyelem();
        }

        if ( isdefined( self.perkicon[2] ) )
        {
            self.perkicon[2] maps\mp\gametypes\_hud_util::destroyelem();
            self.perkname[2] maps\mp\gametypes\_hud_util::destroyelem();
        }
    }

    self notify( "perks_hidden" );
    self.lowermessage maps\mp\gametypes\_hud_util::destroyelem();
    self.lowertimer maps\mp\gametypes\_hud_util::destroyelem();

    if ( isdefined( self.proxbar ) )
        self.proxbar maps\mp\gametypes\_hud_util::destroyelem();

    if ( isdefined( self.proxbartext ) )
        self.proxbartext maps\mp\gametypes\_hud_util::destroyelem();
}

gethostplayer()
{
    var_0 = getentarray( "player", "classname" );

    for ( var_1 = 0; var_1 < var_0.size; var_1++ )
    {
        if ( var_0[var_1] ishost() )
            return var_0[var_1];
    }
}

hostidledout()
{
    var_0 = gethostplayer();

    if ( isdefined( var_0 ) && !var_0.hasspawned && !isdefined( var_0.selectedclass ) )
        return 1;

    return 0;
}

roundendwait( var_0, var_1 )
{
    var_2 = 0;

    while ( !var_2 )
    {
        var_3 = level.players;
        var_2 = 1;

        foreach ( var_5 in var_3 )
        {
            if ( !isdefined( var_5.doingsplash ) )
                continue;

            if ( !var_5 maps\mp\gametypes\_hud_message::isdoingsplash() )
                continue;

            var_2 = 0;
        }

        wait 0.5;
    }

    if ( !var_1 )
    {
        wait(var_0);
        level notify( "round_end_finished" );
        return;
    }

    wait(var_0 / 2);
    level notify( "give_match_bonus" );
    wait(var_0 / 2);
    var_2 = 0;

    while ( !var_2 )
    {
        var_3 = level.players;
        var_2 = 1;

        foreach ( var_5 in var_3 )
        {
            if ( !isdefined( var_5.doingsplash ) )
                continue;

            if ( !var_5 maps\mp\gametypes\_hud_message::isdoingsplash() )
                continue;

            var_2 = 0;
        }

        wait 0.5;
    }

    level notify( "round_end_finished" );
}

roundenddof( var_0 )
{
    self setdepthoffield( 0, 128, 512, 4000, 6, 1.8 );
}

updatesquadvssquad()
{
    for (;;)
    {
        setnojiptime( 1 );
        wait 0.05;
    }
}

callback_startgametype()
{
    maps\mp\_load::main();
    maps\mp\_utility::levelflaginit( "round_over", 0 );
    maps\mp\_utility::levelflaginit( "game_over", 0 );
    maps\mp\_utility::levelflaginit( "block_notifies", 0 );
    maps\mp\_utility::levelflaginit( "post_game_level_event_active", 0 );
    level.prematchperiod = 0;
    level.prematchperiodend = 0;
    level.postgamenotifies = 0;
    level.intermission = 0;
    setdvar( "bg_compassShowEnemies", getdvar( "scr_game_forceuav" ) );

    if ( maps\mp\_utility::matchmakinggame() )
        setdvar( "isMatchMakingGame", 1 );
    else
        setdvar( "isMatchMakingGame", 0 );

    if ( level.multiteambased )
        setdvar( "ui_numteams", level.numteams );

    if ( !isdefined( game["gamestarted"] ) )
    {
        game["clientid"] = 0;
        game["truncated_killcams"] = 0;

        if ( !isdefined( game["attackers"] ) || !isdefined( game["defenders"] ) )
            thread common_scripts\utility::error( "No attackers or defenders team defined in level .gsc." );

        if ( !isdefined( game["attackers"] ) )
            game["attackers"] = "allies";

        if ( !isdefined( game["defenders"] ) )
            game["defenders"] = "axis";

        if ( !isdefined( game["state"] ) )
            game["state"] = "playing";

        game["allies"] = "ghosts";
        game["axis"] = "federation";
        game["strings"]["press_to_spawn"] = &"PLATFORM_PRESS_TO_SPAWN";
        game["strings"]["spawn_next_round"] = &"MP_SPAWN_NEXT_ROUND";
        game["strings"]["spawn_flag_wait"] = &"MP_SPAWN_FLAG_WAIT";
        game["strings"]["spawn_tag_wait"] = &"MP_SPAWN_TAG_WAIT";
        game["strings"]["waiting_to_spawn"] = &"MP_WAITING_TO_SPAWN";
        game["strings"]["waiting_to_safespawn"] = &"MP_WAITING_TO_SAFESPAWN";
        game["strings"]["match_starting"] = &"MP_MATCH_STARTING";
        game["strings"]["change_class"] = &"MP_CHANGE_CLASS_NEXT_SPAWN";
        game["strings"]["last_stand"] = &"MPUI_LAST_STAND";
        game["strings"]["final_stand"] = &"MPUI_FINAL_STAND";
        game["strings"]["c4_death"] = &"MPUI_C4_DEATH";
        game["strings"]["cowards_way"] = &"PLATFORM_COWARDS_WAY_OUT";
        game["colors"]["black"] = ( 0.0, 0.0, 0.0 );
        game["colors"]["white"] = ( 1.0, 1.0, 1.0 );
        game["colors"]["grey"] = ( 0.5, 0.5, 0.5 );
        game["colors"]["cyan"] = ( 0.35, 0.7, 0.9 );
        game["colors"]["orange"] = ( 0.9, 0.6, 0.0 );
        game["colors"]["blue"] = ( 0.2, 0.3, 0.7 );
        game["colors"]["red"] = ( 0.75, 0.25, 0.25 );
        game["colors"]["green"] = ( 0.25, 0.75, 0.25 );
        game["colors"]["yellow"] = ( 0.65, 0.65, 0.0 );
        game["strings"]["allies_name"] = maps\mp\gametypes\_teams::getteamname( "allies" );
        game["icons"]["allies"] = maps\mp\gametypes\_teams::getteamicon( "allies" );
        game["colors"]["allies"] = maps\mp\gametypes\_teams::getteamcolor( "allies" );
        game["strings"]["axis_name"] = maps\mp\gametypes\_teams::getteamname( "axis" );
        game["icons"]["axis"] = maps\mp\gametypes\_teams::getteamicon( "axis" );
        game["colors"]["axis"] = maps\mp\gametypes\_teams::getteamcolor( "axis" );

        if ( game["colors"]["allies"] == game["colors"]["black"] )
            game["colors"]["allies"] = game["colors"]["grey"];

        if ( game["colors"]["axis"] == game["colors"]["black"] )
            game["colors"]["axis"] = game["colors"]["grey"];

        [[ level.onprecachegametype ]]();
        setdvarifuninitialized( "min_wait_for_players", 5 );

        if ( level.console )
        {
            if ( !level.splitscreen )
            {
                if ( maps\mp\_utility::ismlgmatch() || isdedicatedserver() )
                    level.prematchperiod = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "graceperiod_comp" );
                else
                    level.prematchperiod = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "graceperiod" );

                level.prematchperiodend = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "matchstarttime" );
            }
        }
        else
        {
            if ( maps\mp\_utility::ismlgmatch() || isdedicatedserver() )
                level.prematchperiod = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "playerwaittime_comp" );
            else
                level.prematchperiod = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "playerwaittime" );

            level.prematchperiodend = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "matchstarttime" );
        }

        setnojipscore( 0 );
        setnojiptime( 0 );

        if ( getdvar( "squad_vs_squad" ) == "1" )
            thread updatesquadvssquad();
    }
    else
    {
        setdvarifuninitialized( "min_wait_for_players", 5 );

        if ( level.console )
        {
            if ( !level.splitscreen )
            {
                level.prematchperiod = 5;
                level.prematchperiodend = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "matchstarttime" );
            }
        }
        else
        {
            level.prematchperiod = 5;
            level.prematchperiodend = maps\mp\gametypes\_tweakables::gettweakablevalue( "game", "matchstarttime" );
        }
    }

    if ( !isdefined( game["status"] ) )
        game["status"] = "normal";

    setdvar( "ui_overtime", game["status"] == "overtime" );

    if ( game["status"] != "overtime" && game["status"] != "halftime" )
    {
        if ( !( isdefined( game["switchedsides"] ) && game["switchedsides"] == 1 && maps\mp\_utility::ismoddedroundgame() ) )
        {
            game["teamScores"]["allies"] = 0;
            game["teamScores"]["axis"] = 0;
        }

        if ( level.multiteambased )
        {
            for ( var_0 = 0; var_0 < level.teamnamelist.size; var_0++ )
                game["teamScores"][level.teamnamelist[var_0]] = 0;
        }
    }

    if ( !isdefined( game["timePassed"] ) )
        game["timePassed"] = 0;

    if ( !isdefined( game["roundsPlayed"] ) )
        game["roundsPlayed"] = 0;

    if ( !isdefined( game["roundsWon"] ) )
        game["roundsWon"] = [];

    if ( level.teambased )
    {
        if ( !isdefined( game["roundsWon"]["axis"] ) )
            game["roundsWon"]["axis"] = 0;

        if ( !isdefined( game["roundsWon"]["allies"] ) )
            game["roundsWon"]["allies"] = 0;

        if ( level.multiteambased )
        {
            for ( var_0 = 0; var_0 < level.teamnamelist.size; var_0++ )
            {
                if ( !isdefined( game["roundsWon"][level.teamnamelist[var_0]] ) )
                    game["roundsWon"][level.teamnamelist[var_0]] = 0;
            }
        }
    }

    level.gameended = 0;
    level.forcedend = 0;
    level.hostforcedend = 0;

    if ( !maps\mp\_utility::is_aliens() )
        level.hardcoremode = getdvarint( "g_hardcore" );

    if ( level.hardcoremode )
        logstring( "game mode: hardcore" );

    level.diehardmode = getdvarint( "scr_diehard" );

    if ( !level.teambased )
        level.diehardmode = 0;

    if ( level.diehardmode )
        logstring( "game mode: diehard" );

    level.killstreakrewards = getdvarint( "scr_game_hardpoints" );
    level.usestartspawns = 1;
    level.objectivepointsmod = 1;

    if ( maps\mp\_utility::matchmakinggame() )
        level.maxallowedteamkills = 2;
    else
        level.maxallowedteamkills = -1;

    if ( !maps\mp\_utility::is_aliens() )
    {
        thread maps\mp\gametypes\_healthoverlay::init();
        thread maps\mp\gametypes\_killcam::init();
        thread maps\mp\gametypes\_damage::initfinalkillcam();
        thread maps\mp\gametypes\_battlechatter_mp::init();
        thread maps\mp\gametypes\_music_and_dialog::init();
    }

    thread [[ level.intelinit ]]();
    thread maps\mp\gametypes\_persistence::init();
    thread maps\mp\gametypes\_menus::init();
    thread maps\mp\gametypes\_hud::init();
    thread maps\mp\gametypes\_serversettings::init();
    thread maps\mp\gametypes\_teams::init();
    thread maps\mp\gametypes\_weapons::init();
    thread maps\mp\gametypes\_outline::init();
    thread maps\mp\gametypes\_shellshock::init();
    thread maps\mp\gametypes\_deathicons::init();
    thread maps\mp\gametypes\_damagefeedback::init();
    thread maps\mp\gametypes\_objpoints::init();
    thread maps\mp\gametypes\_gameobjects::init();
    thread maps\mp\gametypes\_spectating::init();
    thread maps\mp\gametypes\_spawnlogic::init();
    thread maps\mp\_matchdata::init();
    thread maps\mp\_awards::init();
    thread maps\mp\_areas::init();
    thread [[ level.killstreakinit ]]();
    thread maps\mp\perks\_perks::init();
    thread maps\mp\_events::init();
    thread maps\mp\_defcon::init();
    thread [[ level.matcheventsinit ]]();
    thread maps\mp\_zipline::init();

    if ( level.teambased )
        thread maps\mp\gametypes\_friendicons::init();

    thread maps\mp\gametypes\_hud_message::init();
    game["gamestarted"] = 1;
    level.maxplayercount = 0;
    level.wavedelay["allies"] = 0;
    level.wavedelay["axis"] = 0;
    level.lastwave["allies"] = 0;
    level.lastwave["axis"] = 0;
    level.waveplayerspawnindex["allies"] = 0;
    level.waveplayerspawnindex["axis"] = 0;
    level.aliveplayers["allies"] = [];
    level.aliveplayers["axis"] = [];
    level.activeplayers = [];

    if ( level.multiteambased )
    {
        for ( var_0 = 0; var_0 < level.teamnamelist.size; var_0++ )
        {
            level._wavedelay[level.teamnamelist[var_0]] = 0;
            level._lastwave[level.teamnamelist[var_0]] = 0;
            level._waveplayerspawnindex[level.teamnamelist[var_0]] = 0;
            level._aliveplayers[level.teamnamelist[var_0]] = [];
        }
    }

    setdvar( "ui_scorelimit", 0 );
    setdvar( "ui_allow_teamchange", 1 );

    if ( maps\mp\_utility::getgametypenumlives() )
        setdvar( "g_deadChat", 0 );
    else
        setdvar( "g_deadChat", 1 );

    var_1 = getdvarint( "scr_" + level.gametype + "_waverespawndelay" );

    if ( var_1 )
    {
        level.wavedelay["allies"] = var_1;
        level.wavedelay["axis"] = var_1;
        level.lastwave["allies"] = 0;
        level.lastwave["axis"] = 0;

        if ( level.multiteambased )
        {
            for ( var_0 = 0; var_0 < level.teamnamelist.size; var_0++ )
            {
                level._wavedelay[level.teamnamelist[var_0]] = var_1;
                level._lastwave[level.teamnamelist[var_0]] = 0;
            }
        }

        level thread wavespawntimer();
    }

    maps\mp\_utility::gameflaginit( "prematch_done", 0 );

    if ( maps\mp\_utility::is_aliens() )
        level.graceperiod = 10;
    else
        level.graceperiod = 15;

    level.ingraceperiod = level.graceperiod;
    maps\mp\_utility::gameflaginit( "graceperiod_done", 0 );
    level.roundenddelay = 4;
    level.halftimeroundenddelay = 4;
    level.noragdollents = getentarray( "noragdoll", "targetname" );

    if ( level.teambased )
    {
        maps\mp\gametypes\_gamescore::updateteamscore( "axis" );
        maps\mp\gametypes\_gamescore::updateteamscore( "allies" );

        if ( level.multiteambased )
        {
            for ( var_0 = 0; var_0 < level.teamnamelist.size; var_0++ )
                maps\mp\gametypes\_gamescore::updateteamscore( level.teamnamelist[var_0] );
        }
    }
    else
        thread maps\mp\gametypes\_gamescore::initialdmscoreupdate();

    thread updateuiscorelimit();
    level notify( "update_scorelimit" );
    [[ level.onstartgametype ]]();
    level.scorepercentagecutoff = getdvarint( "scr_" + level.gametype + "_score_percentage_cut_off", 80 );
    level.timepercentagecutoff = getdvarint( "scr_" + level.gametype + "_time_percentage_cut_off", 80 );

    if ( !level.console && ( getdvar( "dedicated" ) == "dedicated LAN server" || getdvar( "dedicated" ) == "dedicated internet server" ) )
        thread verifydedicatedconfiguration();

    thread startgame();
    level thread maps\mp\_utility::updatewatcheddvars();
    level thread timelimitthread();

    if ( !maps\mp\_utility::is_aliens() )
        level thread maps\mp\gametypes\_damage::dofinalkillcam();
    else
        monitoraliensfailed();
}

callback_codeendgame()
{
    endparty();

    if ( !level.gameended )
        level thread forceend();
}

verifydedicatedconfiguration()
{
    for (;;)
    {
        if ( level.rankedmatch )
            exitlevel( 0 );

        if ( !getdvarint( "xblive_privatematch" ) )
            exitlevel( 0 );

        if ( getdvar( "dedicated" ) != "dedicated LAN server" && getdvar( "dedicated" ) != "dedicated internet server" )
            exitlevel( 0 );

        wait 5;
    }
}

timelimitthread()
{
    level endon( "game_ended" );
    var_0 = maps\mp\_utility::gettimepassed();

    while ( game["state"] == "playing" )
    {
        thread checktimelimit( var_0 );
        var_0 = maps\mp\_utility::gettimepassed();

        if ( isdefined( level.starttime ) )
        {
            if ( gettimeremaining() < 3000 )
            {
                wait 0.1;
                continue;
            }
        }

        wait 1;
    }
}

updateuiscorelimit()
{
    for (;;)
    {
        level common_scripts\utility::waittill_either( "update_scorelimit", "update_winlimit" );

        if ( !maps\mp\_utility::isroundbased() || !maps\mp\_utility::isobjectivebased() )
        {
            setdvar( "ui_scorelimit", maps\mp\_utility::getwatcheddvar( "scorelimit" ) );
            thread checkscorelimit();
            continue;
        }

        setdvar( "ui_scorelimit", maps\mp\_utility::getwatcheddvar( "winlimit" ) );
    }
}

playtickingsound()
{
    self endon( "death" );
    self endon( "stop_ticking" );
    level endon( "game_ended" );
    var_0 = level.bombtimer;

    for (;;)
    {
        self playsound( "ui_mp_suitcasebomb_timer" );

        if ( var_0 > 10 )
        {
            var_0 -= 1;
            wait 1;
        }
        else if ( var_0 > 4 )
        {
            var_0 -= 0.5;
            wait 0.5;
        }
        else if ( var_0 > 1 )
        {
            var_0 -= 0.4;
            wait 0.4;
        }
        else
        {
            var_0 -= 0.3;
            wait 0.3;
        }

        maps\mp\gametypes\_hostmigration::waittillhostmigrationdone();
    }
}

stoptickingsound()
{
    self notify( "stop_ticking" );
}

timelimitclock()
{
    level endon( "game_ended" );
    wait 0.05;
    var_0 = spawn( "script_origin", ( 0.0, 0.0, 0.0 ) );
    var_0 hide();

    while ( game["state"] == "playing" )
    {
        if ( !level.timerstopped && maps\mp\_utility::gettimelimit() )
        {
            var_1 = gettimeremaining() / 1000;
            var_2 = int( var_1 + 0.5 );

            if ( var_2 >= 30 && var_2 <= 60 )
                level notify( "match_ending_soon", "time" );

            if ( var_2 <= 10 || var_2 <= 30 && var_2 % 2 == 0 )
            {
                level notify( "match_ending_very_soon" );

                if ( var_2 == 0 )
                    break;

                var_0 playsound( "ui_mp_timer_countdown" );
            }

            if ( var_1 - floor( var_1 ) >= 0.05 )
                wait(var_1 - floor( var_1 ));
        }

        wait 1.0;
    }
}

gametimer()
{
    level endon( "game_ended" );
    level waittill( "prematch_over" );
    level.starttime = gettime();
    level.discardtime = 0;

    if ( isdefined( game["roundMillisecondsAlreadyPassed"] ) )
    {
        level.starttime -= game["roundMillisecondsAlreadyPassed"];
        game["roundMillisecondsAlreadyPassed"] = undefined;
    }

    var_0 = gettime();

    while ( game["state"] == "playing" )
    {
        if ( !level.timerstopped )
            game["timePassed"] += gettime() - var_0;

        var_0 = gettime();
        wait 1.0;
    }
}

updatetimerpausedness()
{
    var_0 = level.timerstoppedforgamemode || isdefined( level.hostmigrationtimer );

    if ( !maps\mp\_utility::gameflag( "prematch_done" ) )
        var_0 = 0;

    if ( !level.timerstopped && var_0 )
    {
        level.timerstopped = 1;
        level.timerpausetime = gettime();
    }
    else if ( level.timerstopped && !var_0 )
    {
        level.timerstopped = 0;
        level.discardtime += gettime() - level.timerpausetime;
    }
}

pausetimer()
{
    level.timerstoppedforgamemode = 1;
    updatetimerpausedness();
}

resumetimer()
{
    level.timerstoppedforgamemode = 0;
    updatetimerpausedness();
}

startgame()
{
    thread gametimer();
    level.timerstopped = 0;
    level.timerstoppedforgamemode = 0;
    setomnvar( "ui_prematch_period", 1 );

    if ( isdefined( level.customprematchperiod ) )
        [[ level.customprematchperiod ]]();
    else
        prematchperiod();

    maps\mp\_utility::gameflagset( "prematch_done" );
    level notify( "prematch_over" );
    setomnvar( "ui_prematch_period", 0 );
    updatetimerpausedness();
    thread timelimitclock();
    thread graceperiod();

    if ( !maps\mp\_utility::is_aliens() )
        thread maps\mp\gametypes\_missions::roundbegin();
}

wavespawntimer()
{
    level endon( "game_ended" );

    while ( game["state"] == "playing" )
    {
        var_0 = gettime();

        if ( var_0 - level.lastwave["allies"] > level.wavedelay["allies"] * 1000 )
        {
            level notify( "wave_respawn_allies" );
            level.lastwave["allies"] = var_0;
            level.waveplayerspawnindex["allies"] = 0;
        }

        if ( var_0 - level.lastwave["axis"] > level.wavedelay["axis"] * 1000 )
        {
            level notify( "wave_respawn_axis" );
            level.lastwave["axis"] = var_0;
            level.waveplayerspawnindex["axis"] = 0;
        }

        if ( level.multiteambased )
        {
            for ( var_1 = 0; var_1 < level.teamnamelist.size; var_1++ )
            {
                if ( var_0 - level.lastwave[level.teamnamelist[var_1]] > level._wavedelay[level.teamnamelist[var_1]] * 1000 )
                {
                    var_2 = "wave_rewpawn_" + level.teamnamelist[var_1];
                    level notify( var_2 );
                    level.lastwave[level.teamnamelist[var_1]] = var_0;
                    level.waveplayerspawnindex[level.teamnamelist[var_1]] = 0;
                }
            }
        }

        wait 0.05;
    }
}

getbetterteam()
{
    var_0["allies"] = 0;
    var_0["axis"] = 0;
    var_1["allies"] = 0;
    var_1["axis"] = 0;

    foreach ( var_3 in level.players )
    {
        var_4 = var_3.pers["team"];

        if ( isdefined( var_4 ) && ( var_4 == "allies" || var_4 == "axis" ) )
        {
            var_0[var_4] += var_3.kills;
            var_1[var_4] += var_3.deaths;
        }
    }

    if ( var_0["allies"] > var_0["axis"] )
        return "allies";
    else if ( var_0["axis"] > var_0["allies"] )
        return "axis";

    if ( var_1["allies"] < var_1["axis"] )
        return "allies";
    else if ( var_1["axis"] < var_1["allies"] )
        return "axis";

    if ( randomint( 2 ) == 0 )
        return "allies";

    return "axis";
}

rankedmatchupdates( var_0 )
{
    if ( maps\mp\_utility::matchmakinggame() )
    {
        setxenonranks();

        if ( hostidledout() )
        {
            level.hostforcedend = 1;
            logstring( "host idled out" );
            endlobby();
        }

        updatematchbonusscores( var_0 );
    }

    updatewinlossstats( var_0 );
}

displayroundend( var_0, var_1 )
{
    if ( maps\mp\_utility::ismoddedroundgame() )
    {
        var_0 = "roundend";
        var_2 = game["music"]["allies_suspense"].size;
        var_3 = game["music"]["axis_suspense"].size;
        maps\mp\_utility::playsoundonplayers( game["music"]["allies_suspense"][randomint( var_2 )], "allies" );
        maps\mp\_utility::playsoundonplayers( game["music"]["axis_suspense"][randomint( var_3 )], "axis" );
    }

    foreach ( var_5 in level.players )
    {
        if ( isdefined( var_5.connectedpostgame ) || var_5.pers["team"] == "spectator" && !var_5 ismlgspectator() )
            continue;

        if ( level.teambased )
        {
            var_5 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( var_0, 1, var_1 );
            continue;
        }

        var_5 thread maps\mp\gametypes\_hud_message::outcomenotify( var_0, var_1 );
    }

    if ( !maps\mp\_utility::waslastround() )
        level notify( "round_win", var_0 );

    if ( maps\mp\_utility::waslastround() )
        roundendwait( level.roundenddelay, 0 );
    else
        roundendwait( level.roundenddelay, 1 );
}

displaygameend( var_0, var_1 )
{
    foreach ( var_3 in level.players )
    {
        if ( isdefined( var_3.connectedpostgame ) || var_3.pers["team"] == "spectator" && !var_3 ismlgspectator() )
            continue;

        if ( level.teambased )
        {
            var_3 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( var_0, 0, var_1 );
            continue;
        }

        var_3 thread maps\mp\gametypes\_hud_message::outcomenotify( var_0, var_1 );
    }

    level notify( "game_win", var_0 );
    roundendwait( level.postroundtime, 1 );
}

displayroundswitch()
{
    var_0 = level.halftimetype;

    if ( var_0 == "halftime" )
    {
        if ( maps\mp\_utility::getwatcheddvar( "roundlimit" ) )
        {
            if ( game["roundsPlayed"] * 2 == maps\mp\_utility::getwatcheddvar( "roundlimit" ) )
                var_0 = "halftime";
            else
                var_0 = "intermission";
        }
        else if ( maps\mp\_utility::getwatcheddvar( "winlimit" ) )
        {
            if ( game["roundsPlayed"] == maps\mp\_utility::getwatcheddvar( "winlimit" ) - 1 )
                var_0 = "halftime";
            else
                var_0 = "intermission";
        }
        else
            var_0 = "intermission";
    }

    level notify( "round_switch", var_0 );
    var_1 = 0;

    if ( isdefined( level.switchedsides ) )
        var_1 = game["end_reason"]["switching_sides"];

    foreach ( var_3 in level.players )
    {
        if ( isdefined( var_3.connectedpostgame ) || var_3.pers["team"] == "spectator" && !var_3 ismlgspectator() )
            continue;

        var_3 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( var_0, 1, var_1 );
    }

    roundendwait( level.halftimeroundenddelay, 0 );
}

freezeallplayers( var_0, var_1, var_2 )
{
    if ( !isdefined( var_0 ) )
        var_0 = 0;

    foreach ( var_4 in level.players )
    {
        var_4 thread freezeplayerforroundend( var_0 );
        var_4 thread roundenddof( 4.0 );
        var_4 freegameplayhudelems();
        var_4 setclientdvars( "cg_everyoneHearsEveryone", 1, "cg_drawSpectatorMessages", 0 );

        if ( isdefined( var_1 ) && isdefined( var_2 ) )
            var_4 setclientdvars( var_1, var_2 );
    }

    foreach ( var_7 in level.agentarray )
        var_7 maps\mp\_utility::freezecontrolswrapper( 1 );
}

endgameovertime( var_0, var_1 )
{
    visionsetnaked( "mpOutro", 0.5 );
    setdvar( "bg_compassShowEnemies", 0 );
    freezeallplayers();
    level notify( "round_switch", "overtime" );

    foreach ( var_3 in level.players )
    {
        if ( isdefined( var_3.connectedpostgame ) || var_3.pers["team"] == "spectator" && !var_3 ismlgspectator() )
            continue;

        if ( level.teambased )
        {
            var_3 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( var_0, 0, var_1 );
            continue;
        }

        var_3 thread maps\mp\gametypes\_hud_message::outcomenotify( var_0, var_1 );
    }

    roundendwait( level.roundenddelay, 0 );

    if ( isdefined( level.finalkillcam_winner ) )
    {
        level.finalkillcam_timegameended[level.finalkillcam_winner] = maps\mp\_utility::getsecondspassed();

        foreach ( var_3 in level.players )
            var_3 notify( "reset_outcome" );

        level notify( "game_cleanup" );
        waittillfinalkillcamdone();

        foreach ( var_3 in level.players )
        {
            if ( isdefined( var_3.connectedpostgame ) || var_3.pers["team"] == "spectator" && !var_3 ismlgspectator() )
                continue;

            if ( level.teambased )
            {
                var_3 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( var_0, 0, var_1 );
                continue;
            }

            var_3 thread maps\mp\gametypes\_hud_message::outcomenotify( var_0, var_1 );
        }
    }

    game["status"] = "overtime";
    level notify( "restarting" );
    game["state"] = "playing";
    map_restart( 1 );
}

endgamehalftime()
{
    visionsetnaked( "mpOutro", 0.5 );
    setdvar( "bg_compassShowEnemies", 0 );
    game["switchedsides"] = !game["switchedsides"];
    level.switchedsides = undefined;
    freezeallplayers();

    foreach ( var_1 in level.players )
        var_1.pers["stats"] = var_1.stats;

    level notify( "round_switch", "halftime" );

    foreach ( var_1 in level.players )
    {
        if ( isdefined( var_1.connectedpostgame ) || var_1.pers["team"] == "spectator" && !var_1 ismlgspectator() )
            continue;

        var_1 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( "halftime", 1, game["end_reason"]["switching_sides"] );
    }

    roundendwait( level.roundenddelay, 0 );

    if ( isdefined( level.finalkillcam_winner ) )
    {
        level.finalkillcam_timegameended[level.finalkillcam_winner] = maps\mp\_utility::getsecondspassed();

        foreach ( var_1 in level.players )
            var_1 notify( "reset_outcome" );

        level notify( "game_cleanup" );
        waittillfinalkillcamdone();

        foreach ( var_1 in level.players )
        {
            if ( isdefined( var_1.connectedpostgame ) || var_1.pers["team"] == "spectator" && !var_1 ismlgspectator() )
                continue;

            var_1 thread maps\mp\gametypes\_hud_message::teamoutcomenotify( "halftime", 1, game["end_reason"]["switching_sides"] );
        }
    }

    game["status"] = "halftime";
    level notify( "restarting" );
    game["state"] = "playing";
    setdvar( "ui_game_state", game["state"] );
    map_restart( 1 );
}

endgame( var_0, var_1, var_2 )
{
    if ( maps\mp\_utility::is_aliens() )
        [[ level.endgame_alien ]]( var_0, var_1 );
    else
        endgame_regularmp( var_0, var_1, var_2 );
}

endgame_regularmp( var_0, var_1, var_2 )
{
    if ( !isdefined( var_2 ) )
        var_2 = 0;

    if ( game["state"] == "postgame" || level.gameended && ( !isdefined( level.gtnw ) || !level.gtnw ) )
        return;

    setomnvar( "ui_pause_menu_show", 0 );
    game["state"] = "postgame";
    setdvar( "ui_game_state", "postgame" );
    level.gameendtime = gettime();
    level.gameended = 1;
    level.ingraceperiod = 0;
    level notify( "game_ended", var_0 );
    maps\mp\_utility::levelflagset( "game_over" );
    maps\mp\_utility::levelflagset( "block_notifies" );
    common_scripts\utility::waitframe();
    setgameendtime( 0 );
    var_3 = getmatchdata( "gameLength" );
    var_3 += int( maps\mp\_utility::getsecondspassed() );
    setmatchdata( "gameLength", var_3 );
    maps\mp\gametypes\_playerlogic::printpredictedspawnpointcorrectness();

    if ( isdefined( var_0 ) && isstring( var_0 ) && var_0 == "overtime" )
    {
        level.finalkillcam_winner = "none";
        endgameovertime( var_0, var_1 );
        return;
    }

    if ( isdefined( var_0 ) && isstring( var_0 ) && var_0 == "halftime" )
    {
        level.finalkillcam_winner = "none";
        endgamehalftime();
        return;
    }

    if ( isdefined( level.finalkillcam_winner ) )
        level.finalkillcam_timegameended[level.finalkillcam_winner] = maps\mp\_utility::getsecondspassed();

    game["roundsPlayed"]++;

    if ( level.teambased )
    {
        if ( var_0 == "axis" || var_0 == "allies" )
            game["roundsWon"][var_0]++;

        maps\mp\gametypes\_gamescore::updateteamscore( "axis" );
        maps\mp\gametypes\_gamescore::updateteamscore( "allies" );
    }
    else if ( isdefined( var_0 ) && isplayer( var_0 ) )
        game["roundsWon"][var_0.guid]++;

    maps\mp\gametypes\_gamescore::updateplacement();
    rankedmatchupdates( var_0 );

    foreach ( var_5 in level.players )
    {
        var_5 setclientdvar( "ui_opensummary", 1 );

        if ( maps\mp\_utility::wasonlyround() || maps\mp\_utility::waslastround() )
            var_5 maps\mp\killstreaks\_killstreaks::clearkillstreaks();
    }

    setdvar( "g_deadChat", 1 );
    setdvar( "ui_allow_teamchange", 0 );
    setdvar( "bg_compassShowEnemies", 0 );
    freezeallplayers( 1.0, "cg_fovScale", 1 );

    if ( !var_2 )
        visionsetnaked( "mpOutro", 0.5 );

    if ( !maps\mp\_utility::wasonlyround() && !var_2 )
    {
        displayroundend( var_0, var_1 );

        if ( isdefined( level.finalkillcam_winner ) )
        {
            foreach ( var_5 in level.players )
                var_5 notify( "reset_outcome" );

            level notify( "game_cleanup" );
            waittillfinalkillcamdone();
        }

        if ( !maps\mp\_utility::waslastround() )
        {
            maps\mp\_utility::levelflagclear( "block_notifies" );

            if ( checkroundswitch() )
                displayroundswitch();

            foreach ( var_5 in level.players )
                var_5.pers["stats"] = var_5.stats;

            level notify( "restarting" );
            game["state"] = "playing";
            setdvar( "ui_game_state", "playing" );
            map_restart( 1 );
            return;
        }

        if ( !level.forcedend )
            var_1 = updateroundendreasontext( var_0 );
    }

    if ( !isdefined( game["clientMatchDataDef"] ) )
    {
        game["clientMatchDataDef"] = "mp/clientmatchdata.def";
        setclientmatchdatadef( game["clientMatchDataDef"] );
    }

    maps\mp\gametypes\_missions::roundend( var_0 );

    if ( level.teambased && maps\mp\_utility::isroundbased() && level.gameended && !maps\mp\_utility::ismoddedroundgame() )
    {
        if ( game["roundsWon"]["allies"] == game["roundsWon"]["axis"] )
            var_0 = "tie";
        else if ( game["roundsWon"]["axis"] > game["roundsWon"]["allies"] )
        {
            level.finalkillcam_winner = "axis";
            var_0 = "axis";
        }
        else
        {
            level.finalkillcam_winner = "allies";
            var_0 = "allies";
        }
    }

    victim = level.finalKillCam_victim[ level.finalkillcam_winner ];
	attacker = level.finalKillCam_attacker[ level.finalkillcam_winner ];

    // --------------------------------------------------------------------------------------------------------------
    wait 2;
    killcamExist = 1;
    if( !IsDefined( victim ) || 
		!IsDefined( attacker ) )
	{
        killcamExist = 0;
    }

    if ( killcamExist && isdefined( level.finalkillcam_winner ) && maps\mp\_utility::wasonlyround() )
    {
        displaygameend( var_0, var_1 );
        foreach ( var_5 in level.players )
            var_5 notify( "reset_outcome" );

        level notify( "game_cleanup" );
        waittillfinalkillcamdone(); 
    }


    maps\mp\_utility::levelflagclear( "block_notifies" );
    
    [[level.startmapvote]]();
    if(!killcamExist)
    {
        displaygameend( var_0, var_1 );
    }
    // --------------------------------------------------------------------------------------------------------------
    
    level.intermission = 1;
    level notify( "start_custom_ending" );
    level notify( "spawning_intermission" );

    foreach ( var_5 in level.players )
    {
        var_5 notify( "reset_outcome" );
        var_5 thread maps\mp\gametypes\_playerlogic::spawnintermission();
    }

    processlobbydata();
    wait 1.0;
    checkforpersonalbests();

    if ( level.teambased )
    {
        if ( var_0 == "axis" || var_0 == "allies" )
            setmatchdata( "victor", var_0 );
        else
            setmatchdata( "victor", "none" );

        setmatchdata( "alliesScore", getteamscore( "allies" ) );
        setmatchdata( "axisScore", getteamscore( "axis" ) );
    }
    else
        setmatchdata( "victor", "none" );

    foreach ( var_5 in level.players )
    {
        var_5 setcommonplayerdata( "round", "endReasonTextIndex", var_1 );

        if ( var_5 maps\mp\_utility::rankingenabled() && !maps\mp\_utility::is_aliens() )
            var_5 maps\mp\_matchdata::logfinalstats();
    
    }

    setmatchdata( "host", level.hostname );

    if ( maps\mp\_utility::matchmakinggame() )
    {
        setmatchdata( "playlistVersion", getplaylistversion() );
        setmatchdata( "playlistID", getplaylistid() );
        setmatchdata( "isDedicated", isdedicatedserver() );
    }

    sendmatchdata();

    foreach ( var_5 in level.players )
        var_5.pers["stats"] = var_5.stats;

    if ( !var_2 && !level.postgamenotifies )
    {
        if ( !maps\mp\_utility::wasonlyround() )
            wait 6.0;
        else
            wait(min( 10.0, 4.0 + level.postgamenotifies ));
    }
    else
        wait(min( 10.0, 4.0 + level.postgamenotifies ));

    maps\mp\_utility::levelflagwaitopen( "post_game_level_event_active" );

    setnojipscore( 0 );
    setnojiptime( 0 );
    level notify( "exitLevel_called" );
    exitlevel( 0 );
}

updateroundendreasontext( var_0 )
{
    if ( !level.teambased )
        return 1;

    if ( maps\mp\_utility::ismoddedroundgame() )
    {
        if ( maps\mp\_utility::hitscorelimit() )
            return game["end_reason"]["score_limit_reached"];

        if ( maps\mp\_utility::hittimelimit() )
            return game["end_reason"]["time_limit_reached"];
    }
    else if ( maps\mp\_utility::hitroundlimit() )
        return game["end_reason"]["round_limit_reached"];

    if ( maps\mp\_utility::hitwinlimit() )
        return game["end_reason"]["score_limit_reached"];

    return game["end_reason"]["objective_completed"];
}

estimatedtimetillscorelimit( var_0 )
{
    var_1 = getscoreperminute( var_0 );
    var_2 = getscoreremaining( var_0 );
    var_3 = 999999;

    if ( var_1 )
        var_3 = var_2 / var_1;

    return var_3;
}

getscoreperminute( var_0 )
{
    var_1 = maps\mp\_utility::getwatcheddvar( "scorelimit" );
    var_2 = maps\mp\_utility::gettimelimit();
    var_3 = maps\mp\_utility::gettimepassed() / 60000 + 0.0001;

    if ( isplayer( self ) )
        var_4 = self.score / var_3;
    else
        var_4 = getteamscore( var_0 ) / var_3;

    return var_4;
}

getscoreremaining( var_0 )
{
    var_1 = maps\mp\_utility::getwatcheddvar( "scorelimit" );

    if ( isplayer( self ) )
        var_2 = var_1 - self.score;
    else
        var_2 = var_1 - getteamscore( var_0 );

    return var_2;
}

givelastonteamwarning()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );
    maps\mp\_utility::waittillrecoveredhealth( 3 );
    thread maps\mp\_utility::teamplayercardsplash( "callout_lastteammemberalive", self, self.pers["team"] );

    foreach ( var_1 in level.teamnamelist )
    {
        if ( self.pers["team"] != var_1 )
            thread maps\mp\_utility::teamplayercardsplash( "callout_lastenemyalive", self, var_1 );
    }

    level notify( "last_alive", self );
}

processlobbydata()
{
    var_0 = 0;

    foreach ( var_2 in level.players )
    {
        if ( !isdefined( var_2 ) )
            continue;

        var_2.clientmatchdataid = var_0;
        var_0++;

        if ( level.ps3 && var_2.name.size > level.maxnamelength )
        {
            var_3 = "";

            for ( var_4 = 0; var_4 < level.maxnamelength - 3; var_4++ )
                var_3 += var_2.name[var_4];

            var_3 += "...";
        }
        else
            var_3 = var_2.name;

        setclientmatchdata( "players", var_2.clientmatchdataid, "xuid", var_3 );
        var_2 setcommonplayerdata( "round", "clientMatchIndex", var_2.clientmatchdataid );
    }

    maps\mp\_awards::assignawards();
    maps\mp\_scoreboard::processlobbyscoreboards();
    sendclientmatchdata();
}

trackleaderboarddeathstats( var_0, var_1 )
{
    thread threadedsetweaponstatbyname( var_0, 1, "deaths" );
}

trackattackerleaderboarddeathstats( var_0, var_1 )
{
    if ( isdefined( self ) && isplayer( self ) )
    {
        if ( var_1 != "MOD_FALLING" )
        {
            if ( var_1 == "MOD_MELEE" && issubstr( var_0, "tactical" ) )
            {
                maps\mp\_matchdata::logattachmentstat( "tactical", "kills", 1 );
                maps\mp\_matchdata::logattachmentstat( "tactical", "hits", 1 );
                maps\mp\gametypes\_persistence::incrementattachmentstat( "tactical", "kills", 1 );
                maps\mp\gametypes\_persistence::incrementattachmentstat( "tactical", "hits", 1 );
                return;
            }

            if ( var_1 == "MOD_MELEE" && !maps\mp\gametypes\_weapons::isriotshield( var_0 ) && var_0 != "iw6_knifeonly_mp" && var_0 != "iw6_knifeonlyfast_mp" )
            {
                maps\mp\_matchdata::logattachmentstat( "none", "kills", 1 );
                maps\mp\_matchdata::logattachmentstat( "none", "hits", 1 );
                maps\mp\gametypes\_persistence::incrementattachmentstat( "none", "kills", 1 );
                maps\mp\gametypes\_persistence::incrementattachmentstat( "none", "hits", 1 );
                return;
            }

            thread threadedsetweaponstatbyname( var_0, 1, "kills" );
        }

        if ( var_1 == "MOD_HEAD_SHOT" )
            thread threadedsetweaponstatbyname( var_0, 1, "headShots" );
    }
}

setweaponstat( var_0, var_1, var_2 )
{
    if ( !var_1 )
        return;

    var_3 = maps\mp\_utility::getweaponclass( var_0 );

    if ( var_3 == "killstreak" || var_3 == "other" && var_0 != "trophy_mp" )
        return;

    if ( maps\mp\_utility::isenvironmentweapon( var_0 ) )
        return;

    if ( var_3 == "weapon_grenade" || var_3 == "weapon_explosive" || var_0 == "trophy_mp" )
    {
        var_4 = maps\mp\_utility::strip_suffix( var_0, "_mp" );
        maps\mp\gametypes\_persistence::incrementweaponstat( var_4, var_2, var_1 );
        maps\mp\_matchdata::logweaponstat( var_4, var_2, var_1 );
        return;
    }

    if ( !isdefined( self.trackingweaponname ) )
        self.trackingweaponname = var_0;

    if ( var_0 != self.trackingweaponname )
    {
        maps\mp\gametypes\_persistence::updateweaponbufferedstats();
        self.trackingweaponname = var_0;
    }

    switch ( var_2 )
    {
        case "shots":
            self.trackingweaponshots++;
            break;
        case "hits":
            self.trackingweaponhits++;
            break;
        case "headShots":
            self.trackingweaponheadshots++;
            break;
        case "kills":
            self.trackingweaponkills++;
            break;
    }

    if ( var_2 == "deaths" )
    {
        var_5 = undefined;
        var_6 = maps\mp\_utility::getbaseweaponname( var_0 );

        if ( !maps\mp\_utility::iscacprimaryweapon( var_6 ) && !maps\mp\_utility::iscacsecondaryweapon( var_6 ) )
            return;

        var_7 = maps\mp\_utility::getweaponattachmentsbasenames( var_0 );
        maps\mp\gametypes\_persistence::incrementweaponstat( var_6, var_2, var_1 );
        maps\mp\_matchdata::logweaponstat( var_6, "deaths", var_1 );

        foreach ( var_9 in var_7 )
        {
            if ( var_9 == "scope" )
                continue;

            maps\mp\gametypes\_persistence::incrementattachmentstat( var_9, var_2, var_1 );
            maps\mp\_matchdata::logattachmentstat( var_9, var_2, var_1 );
        }
    }
}

setinflictorstat( var_0, var_1, var_2 )
{
    if ( !isdefined( var_1 ) )
        return;

    if ( !isdefined( var_0 ) )
    {
        var_1 setweaponstat( var_2, 1, "hits" );
        return;
    }

    if ( !isdefined( var_0.playeraffectedarray ) )
        var_0.playeraffectedarray = [];

    var_3 = 1;

    for ( var_4 = 0; var_4 < var_0.playeraffectedarray.size; var_4++ )
    {
        if ( var_0.playeraffectedarray[var_4] == self )
        {
            var_3 = 0;
            break;
        }
    }

    if ( var_3 )
    {
        var_0.playeraffectedarray[var_0.playeraffectedarray.size] = self;
        var_1 setweaponstat( var_2, 1, "hits" );
    }
}

threadedsetweaponstatbyname( var_0, var_1, var_2 )
{
    self endon( "disconnect" );
    waittillframeend;
    setweaponstat( var_0, var_1, var_2 );
}

checkforpersonalbests()
{
    foreach ( var_1 in level.players )
    {
        if ( !isdefined( var_1 ) )
            continue;

        if ( var_1 maps\mp\_utility::rankingenabled() )
        {
            var_2 = var_1 getcommonplayerdata( "round", "kills" );
            var_3 = var_1 getcommonplayerdata( "round", "deaths" );
            var_4 = var_1.pers["summary"]["xp"];
            var_5 = var_1 getrankedplayerdata( "bestKills" );
            var_6 = var_1 getrankedplayerdata( "mostDeaths" );
            var_7 = var_1 getrankedplayerdata( "mostXp" );

            if ( var_2 > var_5 )
                var_1 setrankedplayerdata( "bestKills", var_2 );

            if ( var_4 > var_7 )
                var_1 setrankedplayerdata( "mostXp", var_4 );

            if ( var_3 > var_6 )
                var_1 setrankedplayerdata( "mostDeaths", var_3 );

            if ( !maps\mp\_utility::is_aliens() )
                var_1 checkforbestweapon();

            var_1 maps\mp\_matchdata::logplayerxp( var_4, "totalXp" );
            var_1 maps\mp\_matchdata::logplayerxp( var_1.pers["summary"]["score"], "scoreXp" );
            var_1 maps\mp\_matchdata::logplayerxp( var_1.pers["summary"]["operation"], "operationXp" );
            var_1 maps\mp\_matchdata::logplayerxp( var_1.pers["summary"]["challenge"], "challengeXp" );
            var_1 maps\mp\_matchdata::logplayerxp( var_1.pers["summary"]["match"], "matchXp" );
            var_1 maps\mp\_matchdata::logplayerxp( var_1.pers["summary"]["misc"], "miscXp" );
        }

        if ( isdefined( var_1.pers["confirmed"] ) )
            var_1 maps\mp\_matchdata::logkillsconfirmed();

        if ( isdefined( var_1.pers["denied"] ) )
            var_1 maps\mp\_matchdata::logkillsdenied();
    }
}

isvalidbestweapon( var_0 )
{
    var_1 = maps\mp\_utility::getweaponclass( var_0 );
    return isdefined( var_0 ) && var_0 != "" && !maps\mp\_utility::iskillstreakweapon( var_0 ) && var_1 != "killstreak" && var_1 != "other";
}

checkforbestweapon()
{
    var_0 = maps\mp\_matchdata::buildbaseweaponlist();
    var_1 = "";
    var_2 = -1;

    for ( var_3 = 0; var_3 < var_0.size; var_3++ )
    {
        var_4 = var_0[var_3];
        var_4 = maps\mp\_utility::getbaseweaponname( var_4 );

        if ( isvalidbestweapon( var_4 ) )
        {
            var_5 = self getrankedplayerdata( "weaponStats", var_4, "kills" );

            if ( var_5 > var_2 )
            {
                var_1 = var_4;
                var_2 = var_5;
            }
        }
    }

    var_6 = self getrankedplayerdata( "weaponStats", var_1, "shots" );
    var_7 = self getrankedplayerdata( "weaponStats", var_1, "headShots" );
    var_8 = self getrankedplayerdata( "weaponStats", var_1, "hits" );
    var_9 = self getrankedplayerdata( "weaponStats", var_1, "deaths" );
    var_10 = 0;
    self setrankedplayerdata( "bestWeapon", "kills", var_2 );
    self setrankedplayerdata( "bestWeapon", "shots", var_6 );
    self setrankedplayerdata( "bestWeapon", "headShots", var_7 );
    self setrankedplayerdata( "bestWeapon", "hits", var_8 );
    self setrankedplayerdata( "bestWeapon", "deaths", var_9 );
    self setrankedplayerdata( "bestWeaponXP", var_10 );
    var_11 = int( tablelookup( "mp/statstable.csv", 4, var_1, 0 ) );
    self setrankedplayerdata( "bestWeaponIndex", var_11 );
}

monitoraliensfailed()
{
    level waittill( "round_end_finished" );
    level notify( "final_killcam_done" );
    level.forcedend = 1;
    level thread endgame( "axis", game["end_reason"]["objective_failed"] );
}
