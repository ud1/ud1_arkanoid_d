module ud1_arkanoid_d.physical_object;

abstract class PhysicalObject {
	import ud1_arkanoid_d.object_prototype;
	import ud1_arkanoid_d.vector2d;
	import ud1_arkanoid_d.render_object;
	import ud1_arkanoid_d.polygon_collision_object;
	import ud1_arkanoid_d.mover;

	ptrdiff_t opCmp(const PhysicalObject c) const
	{
		return (cast(const void*)this - cast(const void*)c);
	}

	final void setPrototype(in ObjectPrototype p, in Vector scale) {
		this.scale = scale;
		collision_object.setPrototype(p.col_obj_proto, scale);
		render_object.setPrototype(p.render_obj_proto, scale);
	}

	void initPosition(in Vector pos, float angle_) {
		start_position = pos;
		start_angle = angle_;
		position = render_position = test_position = start_position + (mover ? mover.getPositionDelta(0.0f) : Vector(0.0f, 0.0f));
		angle = render_angle = test_angle = start_angle + (mover ? mover.getAngleDelta(0.0f) : 0.0f);

		velocity = Vector(0.0f, 0.0f);
		angular_velocity = 0.0f;
		collision_object.setPosition(position, angle, velocity, angular_velocity);
		render_object.setPosition(position, angle);
	}

	final void setTarget(in Vector pos, float angle_, float delta_t) {
		import std.math;
		velocity = (pos - position)/delta_t;
		float d_angle = fmod(abs(angle_ - angle), 2.0*PI);
		if (angle_ < angle)
			d_angle = -d_angle;
		if (d_angle < -PI)
			d_angle += 2.0*PI;
		if (d_angle > PI)
			d_angle -= 2.0*PI;

		angular_velocity = d_angle/delta_t;
	}

	final void calculateVelocity(float abs_t, float delta_t) {
		setTarget(start_position + (mover ? mover.getPositionDelta(abs_t) : Vector(0.0f, 0.0f)),
			start_angle + (mover ? mover.getAngleDelta(abs_t) : 0.0f), delta_t);
	}

	final void testMove(float delta_t) {
		import std.math;

		if (angular_velocity == 0.0f && velocity.isNull())
			return; // do nothing

		test_position = position + velocity*delta_t;
		test_angle = angle + angular_velocity*delta_t;
		if (test_angle > PI)
			test_angle -= 2.0*PI;
		if (test_angle < -PI)
			test_angle += 2.0*PI;
		collision_object.setPosition(test_position, test_angle, velocity, angular_velocity);
	}

	final void applyMove() {
		position = test_position;
		angle = test_angle;
	}

	final void move(float delta_t) {
		testMove(delta_t);
		applyMove();
	}

	final ref const(PolygonCollisionObject) getCollObject() const {
		return collision_object;
	}

	final ref const(RenderObject) getRenderObject() {
		// Check if something has changed
		if (angle != render_angle || position != render_position) {
			render_position = position;
			render_angle = angle;
			render_object.setPosition(position, angle);
		}

		return render_object;
	}

	void setSurfaceParams(float velocity_loss, float surf_friction_coef) {
		collision_object.velocity_loss = velocity_loss;
		collision_object.surf_friction_coef = surf_friction_coef;
	}

	void collide() {}

	final Vector getPosition() const {
		return test_position;
	}

	final float getVelocityLoss() const {
		return collision_object.velocity_loss;
	}

	final float getSurfaceFrictionCoef() const {
		return collision_object.surf_friction_coef;
	}

	bool pos_updated;
	const(Mover) *mover;

protected:
	PolygonCollisionObject collision_object;
	RenderObject render_object;

	Vector position, velocity;
	float angle, angular_velocity;

	Vector test_position;
	float test_angle;

	Vector render_position;
	float render_angle;

	Vector start_position;
	float start_angle;

	Vector scale;
}
