module ud1_arkanoid_d.wall;

struct Wall {
	import ud1_arkanoid_d.segment;

	Segment segment;
	alias segment this;

	float getVelocityLoss() const {
		return velocity_loss;
	}

	float getSurfaceFrictionCoef() const {
		return surf_friction_coef;
	}

	void collide() {}

	float velocity_loss, surf_friction_coef;
};
