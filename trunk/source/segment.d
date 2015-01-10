module ud1_arkanoid_d.segment;

struct Segment {
	import ud1_arkanoid_d.vector2d;

	void initialize(in Vector p1, in Vector p2) {
		import std.math;

		this.p1 = p1;
		Vector tau = p2 - p1;
		length = tau.length;
		angle = atan2(tau.y, tau.x);
		angular_velocity = 0.0f;
		velocity = Vector(0.0f, 0.0f);

	}

	Vector p1 = Vector(0.0f, 0.0f), velocity = Vector(0.0f, 0.0f);
	float length = 1.0f, angle = 0.0f, angular_velocity = 0.0f;
}
