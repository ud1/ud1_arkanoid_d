module ud1_arkanoid_d.level;

struct Level {
	import ud1_arkanoid_d.vector2d;
	import ud1_arkanoid_d.mover;
	import ud1_arkanoid_d.bonus_info;

	static struct BrickInfo {
		Vector scale, pos;
		float angle;
		float velocity_loss, surf_friction_coef;
		int life, points, _bonus;
		int is_static; // bool
		string type;
		Mover *mover;

		BonusType bonus() const {
			return cast(BonusType) _bonus;
		}
	};

	static struct BallInfo {
		Vector position;
		Vector velocity;
	};

	BrickInfo[] bricks;
	BallInfo[] balls;
	int reserve_balls_number = 5;
	Vector platform_scale = Vector(1.5f, 0.3f);
	Vector short_platform_scale = Vector(0.75f, 0.2f);
	Vector long_platform_scale = Vector(3.0f, 0.5f);

	Vector gravity = Vector(0.0f, -7.0f);
	Vector gravity_left = Vector(-3.0f, -7.0f);
	Vector gravity_right = Vector(3.0f, 7.0f);

	Vector clouds_speed = Vector(0.1f, 0.1f);
	float clouds_alpha = 0.5f;

	double platform_bonus_time = 2.0, gravity_bonus_time = 2.0, time_bonus_time = 2.0;

	float velocity_loss_wall = 0.05f, velocity_loss_platform = 0.2f;
	float surf_friction_coef_wall = 0.05f, surf_friction_coef_platform = 0.15f;

	void loadFromFile(string filename) {
		import std.stdio;
		import std.format;
		import std.math;

		writeln("load level " ~ filename);

		auto f = File(filename, "r");
		bricks = null;
		balls = null;

		foreach(line; f.byLine()) {
            if (line.length < 3)
				continue;

			if (line[0] == '/' && line[1] == '/')
				continue;

			string cmd;
			if (formattedRead(line, "%s ", &cmd) != 1)
				throw new Exception("Parse error: " ~ line.idup);


			if (cmd == "brick") {
				BrickInfo info;
				info.mover = new Mover();
				if (formattedRead(line, "%s %s %s %s %s %s %s %s %s %s %s %s", &info.type, &info.life, &info.velocity_loss, &info.surf_friction_coef
					, &info.scale.x(), &info.scale.y()
					, &info.pos.x(), &info.pos.y()
					, &info.angle, &info.points
					, &info.is_static, &info._bonus) != 12) {
					throw new Exception("Parse error, brick: " ~ line.idup);
				}

				info.angle *= PI / 180.0f;
				bricks ~= info;
			} else if (cmd == "pos_lin") {
				if (bricks.length) {
					BrickInfo *info = &bricks[$-1];

					Mover.PosLin p_lin;

					if (formattedRead(line, "%s %s %s %s %s %s %s", &p_lin.period, &p_lin.start_time, &p_lin.end_time, &p_lin.time_offset
						, &p_lin.symmetric, &p_lin.delta_pos.x(), &p_lin.delta_pos.y()) != 7) {
						throw new Exception("Parse error, pos_lin: " ~ line.idup);
					}

					info.mover.pos_lin_funcs ~= p_lin;
				}
			} else if (cmd == "pos_sine") {
				if (bricks.length) {
					BrickInfo *info = &bricks[$-1];

					Mover.PosSine pos_sine;

					if (formattedRead(line, "%s %s %s %s %s %s %s", &pos_sine.period, &pos_sine.start_time, &pos_sine.end_time, &pos_sine.time_offset
						, &pos_sine.symmetric, &pos_sine.delta_pos.x(), &pos_sine.delta_pos.y()) != 7) {
						throw new Exception("Parse error, pos_sine: " ~ line.idup);
					}

					info.mover.pos_sine_funcs ~= pos_sine;
				}
			} else if (cmd == "angle_lin") {
				if (bricks.length) {
					BrickInfo *info = &bricks[$-1];

					Mover.AngleLin a_lin;

					if (formattedRead(line, "%s %s %s %s %s %s", &a_lin.period, &a_lin.start_time, &a_lin.end_time, &a_lin.time_offset
						, &a_lin.symmetric, &a_lin.delta_angle) != 6) {
						throw new Exception("Parse error, angle_lin: " ~ line.idup);
					}

					a_lin.delta_angle *= PI/180.0f;

					info.mover.angle_lin_funcs ~= a_lin;
				}
			} else if (cmd == "angle_sine") {
				if (bricks.length) {
					BrickInfo *info = &bricks[$-1];

					Mover.AngleSine a_sine;

					if (formattedRead(line, "%s %s %s %s %s %s", &a_sine.period, &a_sine.start_time, &a_sine.end_time, &a_sine.time_offset
						, &a_sine.symmetric, &a_sine.delta_angle) != 6) {
						throw new Exception("Parse error, angle_sine: " ~ line.idup);
					}

					a_sine.delta_angle *= PI/180.0f;

					info.mover.angle_sine_funcs ~= a_sine;
				}
			} else if (cmd == "ball") {
				BallInfo info;

				if (formattedRead(line, "%s %s %s %s", &info.position.x(), &info.position.y(), &info.velocity.x(), &info.velocity.y()) != 4) {
					throw new Exception("Parse error, ball: " ~ line.idup);
				}

				balls ~= info;
			} else if (cmd == "balls") {
				if (formattedRead(line, "%s", &reserve_balls_number) != 1) {
					throw new Exception("Parse error, balls: " ~ line.idup);
				}
			} else if (cmd == "platform_scale") {
				if (formattedRead(line, "%s %s", &platform_scale.x(), &platform_scale.y()) != 2) {
					throw new Exception("Parse error, platform_scale: " ~ line.idup);
				}
			} else if (cmd == "short_platform_scale") {
				if (formattedRead(line, "%s %s", &short_platform_scale.x(), &short_platform_scale.y()) != 2) {
					throw new Exception("Parse error, short_platform_scale: " ~ line.idup);
				}
			} else if (cmd == "long_platform_scale") {
				if (formattedRead(line, "%s %s", &long_platform_scale.x(), &long_platform_scale.y()) != 2) {
					throw new Exception("Parse error, long_platform_scale: " ~ line.idup);
				}
			} else if (cmd == "gravity") {
				if (formattedRead(line, "%s %s", &gravity.x(), &gravity.y()) != 2) {
					throw new Exception("Parse error, gravity: " ~ line.idup);
				}
			} else if (cmd == "gravity_left") {
				if (formattedRead(line, "%s %s", &gravity_left.x(), &gravity_left.y()) != 2) {
					throw new Exception("Parse error, gravity_left: " ~ line.idup);
				}
			} else if (cmd == "gravity_right") {
				if (formattedRead(line, "%s %s", &gravity_right.x(), &gravity_right.y()) != 2) {
					throw new Exception("Parse error, gravity_right: " ~ line.idup);
				}
			} else if (cmd == "bonus_time") {
				if (formattedRead(line, "%s %s %s", &platform_bonus_time, &gravity_bonus_time, &time_bonus_time) != 3) {
					throw new Exception("Parse error, bonus_time: " ~ line.idup);
				}
			} else if (cmd == "velocity_loss_wall") {
				if (formattedRead(line, "%s", &velocity_loss_wall) != 1) {
					throw new Exception("Parse error, velocity_loss_wall: " ~ line.idup);
				}
			} else if (cmd == "velocity_loss_platform") {
				if (formattedRead(line, "%s", &velocity_loss_platform) != 1) {
					throw new Exception("Parse error, velocity_loss_platform: " ~ line.idup);
				}
			} else if (cmd == "surf_friction_coef_wall") {
				if (formattedRead(line, "%s", &surf_friction_coef_wall) != 1) {
					throw new Exception("Parse error, surf_friction_coef_wall: " ~ line.idup);
				}
			} else if (cmd == "surf_friction_coef_platform") {
				if (formattedRead(line, "%s", &surf_friction_coef_platform) != 1) {
					throw new Exception("Parse error, surf_friction_coef_platform: " ~ line.idup);
				}
			} else if (cmd == "clouds") {
				if (formattedRead(line, "%s %s %s", &clouds_alpha, &clouds_speed.x(), &clouds_speed.y()) != 3) {
					throw new Exception("Parse error, clouds: " ~ line.idup);
				}
			} else {
				throw new Exception("Parse error: " ~ cmd);
			}
		}
	}
}

