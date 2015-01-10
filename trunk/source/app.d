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

Game game;

void close_main_window() {
	game.isRunning = false;
}

void lbdown(int x, int y) {
	if (game.getState() == Game.State.SIMULATION) {
		game.world.player_platform.setNoVelocityLoss(true);
	}
}

void lbup(int x, int y) {
	game.world.player_platform.setNoVelocityLoss(false);
}

void on_deactivate() {
	if (game.getState() != Game.State.PAUSE)
		game.pause();
}

void key_down(int key) {
	if (game.getState() == Game.State.SIMULATION) {
		float angle = 0.2f;
		if (key == SDLK_d) {
			game.world.player_platform.setTargetAngle(-angle);
		} else if (key == SDLK_a) {
			game.world.player_platform.setTargetAngle(angle);
		}
	}
}

void key_up(int key) {
	if (key == SDLK_ESCAPE) {
		game.pause();
	}

	if (key == SDLK_a || key == SDLK_d) {
		game.world.player_platform.setTargetAngle(0.0f);
	}

	if (game.getState() == Game.State.SIMULATION) {
		if (key == SDLK_r) {
			game.throwBall();
		}
	}

	if (game.getState() == Game.State.FINAL) {
		if (key == SDLK_RETURN || key == SDLK_SPACE) {
			game.restartGame();
		}
	}
}

void mmove(int x, int y) {
	if (game.getState() == Game.State.SIMULATION) {
		game.mouse.setDeltaPos(cast(float) x, cast(float) -y);
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

	if (args.length > 1) {
		game.level = to!int(args[1]);
	}

	game.initialize();
	game.run();
	game.destroy();
}
