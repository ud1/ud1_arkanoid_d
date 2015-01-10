module ud1_arkanoid_d.world;
import ud1_arkanoid_d.distance;
import ud1_arkanoid_d.ball;
import ud1_arkanoid_d.vector2d;

enum float min_delta_t = 1.0f/1500.0f;
enum float max_delta_t = 1.0f/500.0f;
enum float ball_inertia_moment = 0.4f;
enum float ball_to_ball_surf_friction_coef = 0.4f;

enum Sounds {
	BALL_TO_WALL_SOUND,
	BALL_TO_BALL_SOUND,
	BALL_TO_BRICK_SOUND,
	BALL_TO_PLATFORM_SOUND,
	BONUS_SOUND,

	SOUNDS_NUMBER
}

float collideBallToPhysObj(PhysObj)(ref Ball ball, ref PhysObj obj, float delta_t) {
	import std.math;
	import std.algorithm;

	DistanceInfo dst = ballToPhysObjDistance(ball, obj);
	float time_to_collide = dst.distance / dst.velocity;
	if (time_to_collide > delta_t)
		time_to_collide = delta_t;
	if (time_to_collide < 0.0f)
		time_to_collide = 0.0f;
	ball.move(time_to_collide);
	float vel_coef = 2.0f - obj.getVelocityLoss();
	float res = abs(vel_coef*dst.velocity);
	ball.velocity = ball.velocity + dst.normal * (vel_coef*dst.velocity);
	float delta_rot_speed = min(abs(vel_coef*dst.velocity*obj.getSurfaceFrictionCoef()/ball_inertia_moment), abs(dst.rotation_speed/(1.0f+ball_inertia_moment)));
	if (dst.rotation_speed < 0.0f)
		delta_rot_speed = -delta_rot_speed;
	ball.rotation_speed += delta_rot_speed;
	ball.velocity = ball.velocity - dst.normal.rotateHalfPi()*(delta_rot_speed*ball_inertia_moment);
	ball.move(delta_t - time_to_collide);

	dst = ballToPhysObjDistance(ball, obj);
	if (dst.distance < 0.0f) {
		//	inside obj, move to surface
		ball.position = dst.closest_point + dst.normal*ball.rad;
	}

	ball.collide();
	obj.collide();
	ball.pos_updated = true;
	return res;
}

float collideBallToBall(ref Ball b1, ref Ball b2, float delta_t) {
	import std.math;
	import std.algorithm;

	DistanceInfo dst = ballToPhysObjDistance(b1, b2);
	float time_to_collide = dst.distance / dst.velocity;
	if (time_to_collide > delta_t)
		time_to_collide = delta_t;
	if (time_to_collide < 0.0f)
		time_to_collide = 0.0f;
	b1.move(time_to_collide);
	b2.move(time_to_collide);
	float res = abs(dst.velocity);
	b1.velocity = b1.velocity + dst.normal * (dst.velocity);
	b2.velocity = b2.velocity - dst.normal * (dst.velocity);
	float delta_rot_speed = min(abs(dst.velocity*ball_to_ball_surf_friction_coef/ball_inertia_moment), abs(dst.rotation_speed/(2.0f*(1.0f+ball_inertia_moment))));
	if (dst.rotation_speed < 0.0f)
		delta_rot_speed = -delta_rot_speed;
	b1.rotation_speed += delta_rot_speed;
	b2.rotation_speed += delta_rot_speed;
	Vector tangent = dst.normal.rotateHalfPi();
	b1.velocity = b1.velocity - tangent*(delta_rot_speed*ball_inertia_moment);
	b2.velocity = b2.velocity + tangent*(delta_rot_speed*ball_inertia_moment);
	b1.move(delta_t - time_to_collide);
	b2.move(delta_t - time_to_collide);

	dst = ballToPhysObjDistance(b1, b2);
	if (dst.distance < 0.0f) {
		//	inside obj, move to surface
		b1.position = dst.closest_point + dst.normal*b1.rad;
	}

	b1.collide();
	b2.collide();

	b1.pos_updated = true;
	b2.pos_updated = true;
	return res;
}

void testMoveObj(T)(ref T t, float delta_t) {
	if (t.pos_updated)
		return;
	t.testMove(delta_t);
	t.pos_updated = true;
}

void moveObj(T)(ref T t, float delta_t) {
	if (t.pos_updated) {
		t.applyMove();
		return;
	}
	t.move(delta_t);
	t.pos_updated = true;
}

struct World {
	import ud1_arkanoid_d.physical_object;
	import ud1_arkanoid_d.wall;
	import ud1_arkanoid_d.bonus;
	import ud1_arkanoid_d.player_platform;
	import ud1_arkanoid_d.sound_system;
	import ud1_arkanoid_d.render_object;

	float current_time = 0.0f;
	PhysicalObject[] objects;
	Wall[] walls;
	Ball[] balls;
	Bonus[] bonuses;
	PlayerPlatform player_platform = new PlayerPlatform;

	void setSoundSystem(SoundSystem *s, float vel_volume_factor_) {

		snd_system = s;
		vel_volume_factor = vel_volume_factor_;
	}

	void resetCurrentTime(float current_time_) {
		current_time = current_time_;
	}

	void simulateUntil(float t) {
		if (t <= current_time)
			return;

		player_platform.calculateVelocity(t - current_time);
		foreach (ref PhysicalObject obj; objects)
			obj.calculateVelocity(t, t - current_time);

		size_t cnt = cast(size_t) ((t - current_time) / max_delta_t);
		for (size_t i = 0; i < cnt; ++i) {
			simulateDelta(max_delta_t);
			current_time += max_delta_t;
		}
		simulateDelta(t - current_time);
		current_time = t;

		removeOutBalls();
		removeOutBonuses();
		removeUnusedObjects();
		addNewBalls();
	}

	void addObj(PhysicalObject o) {
		objects ~= o;
	}

	void addActiveBlock(PhysicalObject o) {
		active_blocks ~= o;
	}

	size_t activeBlockNumber() const {
		return active_blocks.length;
	}

	size_t ballsNumber() const {
		return balls.length;
	}

	void clear() {
		current_time = 0.0f;
		objects = null;
		walls = null;
		balls = null;
		bonuses = null;
		for_deletion = null;
		active_blocks = null;
		new_balls = null;
	}

	void setGravity(in Vector g) {
		foreach (ref Ball ball; balls) {
			ball.gravity = g;
		}
	}

	void newBall(in Ball b) {
		new_balls ~= b;
	}

	float speedBonus(in Vector field_logic_size) const {
		float sum_bonus = 0.0f;
		foreach (const ref Ball ball; balls) {
			sum_bonus += ball.speedBonus(field_logic_size);
		}
		return sum_bonus;
	}

	void removeObj(PhysicalObject o) {
		for_deletion ~= o;
	}

private:
	void removeUnusedObjects() {
		import std.algorithm;

		if (!for_deletion.length)
			return;

		PhysicalObject ar[];
        foreach(ref PhysicalObject obj; objects) {
			if (!canFind(for_deletion, obj))
				ar ~= obj;
        }
        objects = ar;

        ar = null;
        foreach(ref PhysicalObject obj; active_blocks) {
			if (!canFind(for_deletion, obj))
				ar ~= obj;
        }
        active_blocks = ar;
		for_deletion = null;
	}

	float clampDeltaVel(float v) {
		v *= vel_volume_factor;
		if (v > 1.0f)
			v = 1.0f;
		return v;
	}

	void simulateDelta(float delta_t) {
		while (delta_t > 0.0f) {
			float dt = delta_t;
			while (!tryToSimulate(dt))
				dt /= 2;

			delta_t -= dt;
		}
	}

	bool tryToSimulate(float delta_t) {
		player_platform.pos_updated = false;
		foreach (ref Ball ball; balls) {
			ball.pos_updated = false;
		}
		foreach (ref PhysicalObject obj; objects)
			obj.pos_updated = false;

		// Check for collisions
		if (delta_t > min_delta_t) {
			foreach (i, ref Ball ball; balls) {
				Ball tmp_ball;
				tmp_ball = ball;
				tmp_ball.move(delta_t);

				// Check collision to walls
				foreach (ref Wall wall; walls) {
					if (ballToPhysObjCollided(tmp_ball, wall))
						return false;
				}

				// Check collision to objects
				foreach (ref PhysicalObject obj; objects) {
					testMoveObj(obj, delta_t);
					if (ballToPhysObjCollided(tmp_ball, obj))
						return false;
				}

				// Check collision to player platform
				testMoveObj(player_platform, delta_t);
				if (ballToPhysObjCollided(tmp_ball, player_platform))
					return false;

				// Check collision to other balls
				for (size_t j = i+1; j < balls.length; ++j) {
					Ball tmp_ball2;
					tmp_ball2 = balls[j];
					tmp_ball2.move(delta_t);
					if (ballToPhysObjCollided(tmp_ball, tmp_ball2))
						return false;
				}
			}

			// Check collision the platform to bonuses
			for (size_t i = 0; i < bonuses.length; ++i) {
				testMoveObj(player_platform, delta_t);
				Bonus tmp_bounus = bonuses[i];
				tmp_bounus.move(delta_t);
				if (ballToPhysObjCollided(tmp_bounus, player_platform))
					return false;
			}
		}

		// Update positions
		foreach (i, ref Ball ball; balls) {
			Ball tmp_ball;
			tmp_ball = ball;
			tmp_ball.move(delta_t);

			// Check collision to walls
			foreach (ref Wall wall; walls)  {
				if (ballToPhysObjCollided(tmp_ball, wall)) {
					float dv = collideBallToPhysObj(ball, wall, delta_t);
					snd_system.play(Sounds.BALL_TO_WALL_SOUND, clampDeltaVel(dv));
				}
			}

			// Check collision to objects
			foreach (ref PhysicalObject obj; objects) {
				testMoveObj(obj, delta_t);
				if (ballToPhysObjCollided(tmp_ball, obj)) {
					float dv = collideBallToPhysObj(ball, obj, delta_t);
					snd_system.play(Sounds.BALL_TO_BRICK_SOUND, clampDeltaVel(dv));
				}
			}

			// Check collision to player platform
			testMoveObj(player_platform, delta_t);
			if (ballToPhysObjCollided(tmp_ball, player_platform)) {
				float dv = collideBallToPhysObj(ball, player_platform, delta_t);
				snd_system.play(Sounds.BALL_TO_PLATFORM_SOUND, clampDeltaVel(dv));
			}

			// Check collision to other balls
			for (size_t j = i+1; j < balls.length; ++j) {
				Ball tmp_ball2;
				tmp_ball2 = balls[j];
				tmp_ball2.move(delta_t);
				if (ballToPhysObjCollided(tmp_ball, tmp_ball2)) {
					float dv = collideBallToBall(ball, balls[j], delta_t);
					snd_system.play(Sounds.BALL_TO_BALL_SOUND, clampDeltaVel(dv));
				}
			}

			if (!ball.pos_updated) {
				ball.move(delta_t);
			}
		}

		// Check collision the platform to bonuses
		testMoveObj(player_platform, delta_t);
		Bonus[] bonuses_new;
		foreach (ref Bonus bonus; bonuses) {
			bonus.move(delta_t);
			if (ballToPhysObjCollided(bonus, player_platform)) {
				bonus.collide();
			} else {
				bonuses_new ~= bonus;
			}
		}
		bonuses = bonuses_new;

		// Move all what is not already moved
		moveObj(player_platform, delta_t);
		foreach (ref PhysicalObject obj; objects) {
			moveObj(obj, delta_t);
		}

		return true;
	}

	void removeOutBalls() {
		Ball[] balls_new;
		foreach (ref Ball b; balls) {
			if (b.position.y >= -b.rad)
				balls_new ~= b;
		}
		balls = balls_new;
	}

	void removeOutBonuses() {
		Bonus[] bonuses_new;
		foreach (ref Bonus b; bonuses) {
			if (b.position.y >= -b.rad)
				bonuses_new ~= b;
		}
		bonuses = bonuses_new;
	}

	void addNewBalls() {
		balls ~= new_balls;
		new_balls = [];
	}

	PhysicalObject[] for_deletion;
	PhysicalObject[] active_blocks;
	Ball[] new_balls;
	SoundSystem *snd_system;
	float vel_volume_factor;
};

