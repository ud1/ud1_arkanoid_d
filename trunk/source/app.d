module ud1_arkanoid_d.app;

import std.stdio;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import derelict.openal.al;
import derelict.ogg.ogg;
import derelict.vorbis.vorbis;
import derelict.vorbis.enc;
import derelict.vorbis.file;
import ud1_arkanoid_d.game;

Game *g_game;

void close_main_window() {
	g_game.isRunning = false;
}

void lbdown(int x, int y) {
	if (g_game.getState() == Game.State.SIMULATION) {
		g_game.world.player_platform.setNoVelocityLoss(true);
	}
}

void lbup(int x, int y) {
	g_game.world.player_platform.setNoVelocityLoss(false);
}

void on_deactivate() {
	if (g_game.getState() != Game.State.PAUSE)
		g_game.pause();
}

void key_down(int key) {
	if (g_game.getState() == Game.State.SIMULATION) {
		float angle = 0.2f;
		if (key == SDLK_d) {
			g_game.world.player_platform.setTargetAngle(-angle);
		} else if (key == SDLK_a) {
			g_game.world.player_platform.setTargetAngle(angle);
		}
	}
}

void key_up(int key) {
	if (key == SDLK_ESCAPE) {
		g_game.pause();
	}

	if (key == SDLK_a || key == SDLK_d) {
		g_game.world.player_platform.setTargetAngle(0.0f);
	}

	if (g_game.getState() == Game.State.SIMULATION) {
		if (key == SDLK_r) {
			g_game.throwBall();
		}
	}

	if (g_game.getState() == Game.State.FINAL) {
		if (key == SDLK_RETURN || key == SDLK_SPACE) {
			g_game.restartGame();
		}
	}
}

void mmove(int x, int y) {
	if (g_game.getState() == Game.State.SIMULATION) {
		g_game.mouse.setDeltaPos(cast(float) x, cast(float) -y);
	}
}

void main(char[][] args)
{
	import std.conv;
	import std.stdio;

	writeln(args);

	DerelictSDL2.load();
	DerelictGL.load();
	DerelictAL.load();
	DerelictOgg.load();
	DerelictVorbis.load();
    DerelictVorbisEnc.load();
    DerelictVorbisFile.load();

    Game game;
    g_game = &game;

	if (args.length > 1) {
		game.level = to!int(args[1]);
	}

	game.initialize();
	game.run();
	game.destroy();
}
