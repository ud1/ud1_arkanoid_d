module ud1_arkanoid_d.ball;

struct Ball {
	import ud1_arkanoid_d.vector2d;

	Vector position, velocity, gravity;
	int collide_number = 0;
	float rotation_speed = 0.0f; // omega*rad, >0 ccw
	float rad;
	bool pos_updated;

	void move(float delta_t) {
		position = position + velocity*delta_t + gravity*(delta_t*delta_t/2.0f);
		velocity = velocity + gravity*delta_t;
	}

	// Calculates speed bonus
	float speedBonus(in Vector field_logic_size) const {
		import std.math;

		float bottom_speed = sqrt(abs(2.0f*gravity.y*position.y) + velocity.length2);
		return bottom_speed / field_logic_size.y;
	}

	void collide() {
		++collide_number;
	}
}
