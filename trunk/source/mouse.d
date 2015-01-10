module ud1_arkanoid_d.mouse;

struct Mouse {
	import ud1_arkanoid_d.vector2d;

	void setDeltaPos(float dx, float dy) {
		discr_abs_x += dx;
		discr_abs_y += dy;
	}

	void update(float delta_t) {
		import std.math;

		float exp_dt = exp(-delta_t/tau);

		float dx = discr_abs_x - abs_x;
		abs_x = discr_abs_x - dx*exp_dt;

		float dy = discr_abs_y - abs_y;
		abs_y = discr_abs_y - dy*exp_dt;
	}

	void set(Vector coords) {
		float dx = coords.x - abs_x;
		float dy = coords.y - abs_y;
		abs_x = coords.x;
		abs_y = coords.y;
		discr_abs_x += dx;
		discr_abs_y += dy;
	}

	void absSet(Vector coords) {
		abs_x = coords.x;
		abs_y = coords.y;
		discr_abs_x = coords.x;
		discr_abs_y = coords.y;
	}

	Vector get() const {
		return Vector(abs_x, abs_y);
	}

	void setTau(float seconds) {
		tau = seconds;
	}

private:
	float discr_abs_x = 0.0f, discr_abs_y = 0.0f;
	float abs_x = 0.0f, abs_y = 0.0f;
	float tau = 0.07f;
};
