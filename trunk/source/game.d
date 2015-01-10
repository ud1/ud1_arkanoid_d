module ud1_arkanoid_d.game;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import std.concurrency;

void soundThreadFunc(shared Game *game_) {
	Game *game = cast(Game *) game_;
	while (game.isRunning) {
		game.sound_system.update();
		SDL_Delay(100);
	}
}

struct Game {
	import ud1_arkanoid_d.form_config;
	import ud1_arkanoid_d.world;
	import ud1_arkanoid_d.render_object;
	import ud1_arkanoid_d.timer;
	import ud1_arkanoid_d.score;
	import ud1_arkanoid_d.bonus_info;
	import ud1_arkanoid_d.bonus;
	import ud1_arkanoid_d.level;
	import ud1_arkanoid_d.mouse;
	import ud1_arkanoid_d.vector2d;
	import ud1_arkanoid_d.sound_system;
	import ud1_arkanoid_d.window;
	import ud1_arkanoid_d.object_prototype;
	import ud1_arkanoid_d.render;
	import ud1_arkanoid_d.wall;
	import ud1_arkanoid_d.ball;
	import ud1_arkanoid_d.game_brick;
	import std.math;
	import std.conv;

	enum State {
		PAUSE,
		SIMULATION,
		BALL_LOSS,
		NEW_LEVEL,
		END_LEVEL,
		FINAL
	};

	State state;

	FormConfig form_config;
	World world;
	RenderData render_data;
	AdvancedTimer timer; // for simulation
	Timer game_timer;
	Score score;
	Window *window;
	BonusInfo bonus_info;
	Mouse mouse;
	Vector field_to_window_scale;
	Vector window_to_field_scale;
	SoundSystem sound_system;

	Vector getFieldLogicSize() const {
		return Vector(form_config.field.logic_width, form_config.field.logic_height);
	}

	void initialize() {
		import std.stdio;

		render_data.setGame(&this);
		isRunning = true;
		global_time = game_global_time = 0.0;
		prev_global_time = 0.0;
		dark_period = 0.5;
		max_darkness = 0.7;
		platform_bonus = gravity_bonus = time_bonus = 0;
		reserve_balls = 0;
		restart_game = false;

		form_config.loadFromFile("conf/form.txt");

		mouse.setTau(form_config.mouse_smoothing);

		field_to_window_scale = Vector(
			form_config.window.width/form_config.field.logic_width,
			form_config.window.height/form_config.field.logic_height);

		window_to_field_scale = Vector(
			form_config.field.logic_width/form_config.window.width,
			form_config.field.logic_height/form_config.window.height);

		platform_proto.loadFromFile("conf/platform.txt");
		bonus_info.loadFromFile("conf/bonuses.txt");

		window = createWindow(form_config.window.width, form_config.window.height, form_config.disable_effects != 0);
		render_data.init(form_config.disable_effects != 0);

		if (!sound_system.initialize())
			writeln("Sound system was not initialized");
		sound_system.playBackground("data/background.ogg", form_config.background_volume);
		sound_system.setSndNumber(Sounds.SOUNDS_NUMBER); // TODO
		sound_system.load(Sounds.BALL_TO_WALL_SOUND, "data/wall.ogg");
		sound_system.load(Sounds.BALL_TO_BALL_SOUND, "data/ball.ogg");
		sound_system.load(Sounds.BALL_TO_BRICK_SOUND, "data/brick.ogg");
		sound_system.load(Sounds.BALL_TO_PLATFORM_SOUND, "data/platform.ogg");
		sound_system.load(Sounds.BONUS_SOUND, "data/bonus.ogg");

		//sound_thread = std::thread(soundThreadFunc, this);
		spawn(&soundThreadFunc, cast(shared) &this);

		world.setSoundSystem(&sound_system, form_config.velocity_volume_factor);

		timer = new AdvancedTimer;
		game_timer = new Timer;

		timer.resetGlobalTime(0.0);
		game_timer.resetGlobalTime(0.0);
	}

	void destroy() {
		delete window;
	}

	State getState() const {
		return state;
	}

	void pause() {
		bool p = (state == State.PAUSE);
		if (p) {
			state = prev_state;
			state_switch = true;
			game_timer.resetGlobalTime(game_global_time);
			timer.resetGlobalTime(global_time);
			SDL_SetRelativeMouseMode(SDL_TRUE);
		} else {
			prev_state = state;
			state = State.PAUSE;
			state_switch = true;
			game_global_time = game_timer.globalTime();
			global_time = timer.globalTime();
			SDL_SetRelativeMouseMode(SDL_FALSE);
		}
	}

	int getLevel() const {
		return level;
	}

	void initializeField(float walls_velocity_loss, float surf_friction_coef_wall) {
		float logic_width = form_config.field.logic_width;
		float logic_height = form_config.field.logic_height;
		Wall wall;
		// bottom
		/*wall.p1 = Vector(0.0f, 0.0f);
		wall.angle = 0.0f;
		wall.angular_velocity = 0.0f;
		wall.length = logic_width;
		wall.velocity = Vector(0.0f, 0.0f);
		wall.velocity_loss = walls_velocity_loss;
		wall.surf_friction_coef = surf_friction_coef_wall;
		world.walls.push_back(wall);*/

		// right wall
		wall.p1 = Vector(logic_width, 0.0f);
		wall.angle = PI_2;
		wall.angular_velocity = 0.0f;
		wall.length = logic_height;
		wall.velocity = Vector(0.0f, 0.0f);
		wall.velocity_loss = walls_velocity_loss;
		wall.surf_friction_coef = surf_friction_coef_wall;
		world.walls ~= wall;

		// left wall
		wall.p1 = Vector(0, logic_height);
		wall.angle = -PI_2;
		wall.angular_velocity = 0.0f;
		wall.length = logic_height;
		wall.velocity = Vector(0.0f, 0.0f);
		wall.velocity_loss = walls_velocity_loss;
		wall.surf_friction_coef = surf_friction_coef_wall;
		world.walls ~= wall;

		// top wall
		wall.p1 = Vector(logic_width, logic_height);
		wall.angle = PI;
		wall.angular_velocity = 0.0f;
		wall.length = logic_width;
		wall.velocity = Vector(0.0f, 0.0f);
		wall.velocity_loss = walls_velocity_loss;
		wall.surf_friction_coef = surf_friction_coef_wall;
		world.walls ~= wall;
	}

	void resetPlatform() {
		float logic_width = form_config.field.logic_width;
		float logic_height = form_config.field.logic_height;
		world.player_platform.setPrototype(platform_proto, level_conf.platform_scale);
		world.player_platform.setArea(Vector(0.0f, 0.0f), Vector(logic_width, logic_height/5.0f));
		world.player_platform.initPosition(Vector(logic_width/2.0f, 0.0f));
		world.player_platform.setSurfaceParams(level_conf.velocity_loss_platform, level_conf.surf_friction_coef_platform);
		mouse.absSet(world.player_platform.getTarget()*field_to_window_scale);
	}

	void resetBall() {
		world.balls = [];
		setupBall();
	}

	void setupBall() {
		Ball ball;
		ball.gravity = getGravity();
		ball.velocity = Vector(0.0f, 0.0f);
		ball.position = Vector(form_config.field.logic_width/2.0f, 2.0f);
		ball.rad = 0.1f;
		world.balls ~= ball;
	}

	void throwBall() {
		if (reserve_balls > 0) {
			--reserve_balls;
			setupBall();
		}
	}

	void newBall(in Vector pos, in Vector vel) {
		Ball ball;
		ball.gravity = getGravity();
		ball.velocity = vel;
		ball.position = pos;
		ball.rad = 0.1f;
		world.newBall(ball);
	}

	void createBonus(in Vector pos, BonusType type) {
		Bonus b = Bonus(pos, bonus_info, type, &this);
		world.bonuses ~= b;
	}

	void activateBonus(in Bonus bonus) {
		switch (bonus.bonus_type) {
		case BonusType.BONUS_LONG_PLATFORM:
			platform_bonus = BonusType.BONUS_LONG_PLATFORM;
			platform_bonus_untill = timer.globalTime() + level_conf.platform_bonus_time;
			world.player_platform.setPrototype(platform_proto, level_conf.long_platform_scale);
			world.player_platform.initPosition(world.player_platform.getPosition());
			score.platform_bonus = 0.5f;
			break;
		case BonusType.BONUS_SHORT_PLATFORM:
			platform_bonus = BonusType.BONUS_SHORT_PLATFORM;
			platform_bonus_untill = timer.globalTime() + level_conf.platform_bonus_time;
			world.player_platform.setPrototype(platform_proto, level_conf.short_platform_scale);
			world.player_platform.initPosition(world.player_platform.getPosition());
			score.platform_bonus = 2.0f;
			break;
		case BonusType.BONUS_GRAVITY_LEFT:
			gravity_bonus = BonusType.BONUS_GRAVITY_LEFT;
			gravity_bonus_untill = timer.globalTime() + level_conf.gravity_bonus_time;
			world.setGravity(level_conf.gravity_left);
			score.gravity_bonus = 2.0f;
			break;
		case BonusType.BONUS_GRAVITY_RIGHT:
			gravity_bonus = BonusType.BONUS_GRAVITY_RIGHT;
			gravity_bonus_untill = timer.globalTime() + level_conf.gravity_bonus_time;
			world.setGravity(level_conf.gravity_right);
			score.gravity_bonus = 2.0f;
			break;
		case BonusType.BONUS_TIMER_SPEED_DOWN:
			time_bonus = BonusType.BONUS_TIMER_SPEED_DOWN;
			time_bonus_untill = timer.globalTime() + level_conf.time_bonus_time;
			timer.setTimeAcceleration(0.5);
			score.time_bonus = 0.5f;
			break;
		case BonusType.BONUS_TIMER_SPEED_UP:
			time_bonus = BonusType.BONUS_TIMER_SPEED_UP;
			time_bonus_untill = timer.globalTime() + level_conf.time_bonus_time;
			timer.setTimeAcceleration(2.0);
			score.time_bonus = 2.0f;
			break;
		case BonusType.BONUS_RESERVE_BALL:
			++reserve_balls;
			break;
		default:
			break;
		}
	}

	void simulateWorld() {
		setupBonuses();
		double t = timer.globalTime();
		world.simulateUntil(t);
	}

	void restartGame() {
		restart_game = true;
	}

	void run() {
		state = State.PAUSE;
		prev_state = State.NEW_LEVEL;
		state_switch = true;

		while (isRunning) {
			processMessages();

			if (isRunning)
				runOnce();
		}
	}

	void loadLevel(in Level l) {
		world.clear();
		initializeField(l.velocity_loss_wall, l.surf_friction_coef_wall);
		resetPlatform();
		resetBonuses();
		resetBall();
		reserve_balls += l.reserve_balls_number;

		foreach (const ref Level.BrickInfo info; l.bricks) {
			const ObjectPrototype *proto = prototype_mgr.get(info.type);
			if (proto) {
				GameBrick brick = new GameBrick(&this);
				brick.initialize(info, *proto);
				world.addObj(brick);
				if (!brick.isStatic())
					world.addActiveBlock(brick);
			}
		}

		foreach (const ref Level.BallInfo info; l.balls) {
			newBall(info.position, info.velocity);
		}
	}

	bool isRunning;
	int level;
protected:
	bool restart_game;
	State prev_state; // Saved by Pause()
	int reserve_balls;

	Level level_conf;

	double global_time, game_global_time;
	double dark_period, max_darkness;
	ObjectPrototypeManager prototype_mgr;
	ObjectPrototype platform_proto;

	void runOnce() {
		if (!form_config.disable_effects) {
			glClearStencil(0);
			glClear(GL_STENCIL_BUFFER_BIT);
			glStencilMask(0);
		}

		double t1 = game_timer.globalTime();
		final switch (state) {
			case State.PAUSE:
				doPause();
				break;

			case State.SIMULATION:
				doSimulation();
				break;

			case State.BALL_LOSS:
				doBallLoss();
				break;

			case State.NEW_LEVEL:
				doNewLevel();
				break;

			case State.END_LEVEL:
				doEndLevel();
				break;

			case State.FINAL:
				doFinal();
				break;
		}

		SDL_GL_SwapWindow(window.window);
		double t2 = game_timer.globalTime();
		double dt = t2 - t1;
	}

	void doPause() {
		render();
		renderDark(state_switch);

		if (state_switch) {
			state_switch = false;
		}

		string str = "PAUSE";
		float wid = render_data.big_chars.getWidth() * str.length;
		float heig = render_data.big_chars.getHeight();
		Vector pos = Vector((form_config.window.width - wid) / 2.0f, (form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(str, pos, RenderData.Color(1.0f, 1.0f, 0.0f));

		str = "PRESS ESC";
		wid = render_data.big_chars.getWidth() * str.length;
		pos = Vector((form_config.window.width - wid) / 2.0f, (1.5f*form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(str, pos, RenderData.Color(1.0f, 1.0f, 0.0f));
	}

	void doSimulation() {
		if (state_switch) {
			state_switch = false;
			timer.resetGlobalTime(global_time);
			prev_global_time = global_time;
			mouse.absSet(world.player_platform.getTarget()*field_to_window_scale);
		}

		double delta_t = timer.globalTime() - prev_global_time;
		if (delta_t > 0.1) {
			timer.resetGlobalTime(prev_global_time + 0.1);
			delta_t = 0.1;
		}
		prev_global_time = timer.globalTime();

		updateMouse();

		world.player_platform.setTarget(mouse.get()*window_to_field_scale);
		mouse.set(world.player_platform.getTarget()*field_to_window_scale);

		simulateWorld();

		if (world.activeBlockNumber() == 0) {
			state_switch = true;
			state = State.END_LEVEL;
			global_time = timer.globalTime();
		}

		if (world.ballsNumber() == 0) {
			state_switch = true;
			state = State.BALL_LOSS;
			global_time = timer.globalTime();
		}

		render();
	}

	void doBallLoss() {
		render();
		renderDark(state_switch);

		if (state_switch) {
			state_switch = false;

			next_state_switch_time = timer.globalTime() + 2.0;
			if (reserve_balls-- <= 0) {
				state = State.FINAL;
				state_switch = true;
			}
		}

		if (next_state_switch_time <= timer.globalTime()) {
			state = State.SIMULATION;
			state_switch = true;
			resetBonuses();
			resetPlatform();
			resetBall();
		}

		string str = "Balls left " ~ to!string(reserve_balls);
		float wid = render_data.big_chars.getWidth() * str.length;
		float heig = render_data.big_chars.getHeight();
		Vector pos = Vector((form_config.window.width - wid) / 2.0f, (form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(str, pos, RenderData.Color(1.0f, 1.0f, 0.0f));
	}

	void doNewLevel() {
		render();
		render_data.renderDark(max_darkness);

		if (state_switch) {
			state_switch = false;

			if (world.activeBlockNumber())
				return;

			global_time = 0.0;
			timer.resetGlobalTime(0.0);

			next_state_switch_time = timer.globalTime() + 2.0;
			string file_name = "levels/level" ~ to!string(++level) ~ ".txt";
			try {
				level_conf.loadFromFile(file_name);
				loadLevel(level_conf);
				string start_lev_file_name = "data/lev" ~ to!string(level) ~ ".ogg";
				sound_system.play(start_lev_file_name, 1.0f);
			} catch (Exception e) {
                std.stdio.writeln(e);
				state = State.FINAL;
				state_switch = true;
				return;
			}

			return;
		}

		string str = "Level " ~ to!string(level);
		float wid = render_data.big_chars.getWidth() * str.length;
		float heig = render_data.big_chars.getHeight();
		Vector pos = Vector((form_config.window.width - wid) / 2.0f, (form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(str, pos, RenderData.Color(1.0f, 1.0f, 0.0f));

		if (next_state_switch_time <= timer.globalTime()) {
			state = State.SIMULATION;
			state_switch = true;
		}
	}

	void doEndLevel() {
		render();
		renderDark(state_switch);

		if (state_switch) {
			state_switch = false;
			next_state_switch_time = timer.globalTime() + 1.0;
		}

		if (next_state_switch_time <= timer.globalTime()) {
			state = State.NEW_LEVEL;
			state_switch = true;
		}
	}

	void doFinal() {
		render();
		renderDark(state_switch);

		if (state_switch) {
			state_switch = false;
			SDL_SetRelativeMouseMode(SDL_FALSE);
		}

		string str = "Game over";
		float wid = render_data.big_chars.getWidth() * str.length;
		float heig = render_data.big_chars.getHeight();
		Vector pos = Vector((form_config.window.width - wid) / 2.0f, (form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(str, pos, RenderData.Color(1.0f, 1.0f, 0.0f));

		string oss = "Your score " ~ to!string(score.get());
		wid = render_data.big_chars.getWidth() * oss.length;
		pos = Vector((form_config.window.width - wid) / 2.0f, (1.5f*form_config.window.height - heig) / 2.0f);
		render_data.printTextBig(oss, pos, RenderData.Color(1.0f, 1.0f, 0.0f));

		if (restart_game) {
			restart_game = false;
			level = 0;
			reserve_balls = 0;
			score.reset();
			world.clear();
			state = State.NEW_LEVEL;
			state_switch = true;
			SDL_SetRelativeMouseMode(SDL_TRUE);
		}
	}

	void render() {
		render_data.renderField();
		render_data.renderStats();

		float t = cast(float) timer.globalTime();
		render_data.renderClouds(t*level_conf.clouds_speed.x, t*level_conf.clouds_speed.y, level_conf.clouds_alpha);
	}

	void renderDark(bool state_switch) {
		static double t;

		if (state_switch) {
			t = timer.globalTime();
		}

		double delta_t = timer.globalTime() - t;
		if (delta_t > dark_period)
			delta_t = dark_period;

		render_data.renderDark(delta_t * max_darkness / dark_period);
	}

	double prev_global_time; // used by DoSimulation()
	double next_state_switch_time;
	bool state_switch;

	int platform_bonus;
	double platform_bonus_untill;

	int gravity_bonus;
	double gravity_bonus_untill;

	int time_bonus;
	double time_bonus_untill;

	Vector getGravity() const {
		if (gravity_bonus == BonusType.BONUS_GRAVITY_LEFT)
			return level_conf.gravity_left;

		if (gravity_bonus == BonusType.BONUS_GRAVITY_RIGHT)
			return level_conf.gravity_right;

		return level_conf.gravity;
	}

	void setupBonuses() {
		score.speed_bonus = world.speedBonus(getFieldLogicSize());

		double t = timer.globalTime();
		if (platform_bonus && platform_bonus_untill < t) {
			platform_bonus = 0;
			world.player_platform.setPrototype(platform_proto, level_conf.platform_scale);
			score.platform_bonus = 1.0f;
		}

		if (gravity_bonus && gravity_bonus_untill < t) {
			gravity_bonus = 0;
			world.setGravity(level_conf.gravity);
			score.gravity_bonus = 1.0f;
		}

		if (time_bonus && time_bonus_untill < t) {
			time_bonus = 0;
			timer.setTimeAcceleration(1.0f);
			score.time_bonus = 1.0f;
		}
	}

	void resetBonuses() {
		platform_bonus = 0;
		world.player_platform.setPrototype(platform_proto, level_conf.platform_scale);
		score.platform_bonus = 1.0f;

		gravity_bonus = 0;
		world.setGravity(level_conf.gravity);
		score.gravity_bonus = 1.0f;

		time_bonus = 0;
		timer.setTimeAcceleration(1.0f);
		score.time_bonus = 1.0f;
	}

	void updateMouse() {
		static double game_timer_prev_time = 0.0;
		double t = game_timer.globalTime();
		double dt = t - game_timer_prev_time;
		game_timer_prev_time = t;
		mouse.update(dt);
	}
}
