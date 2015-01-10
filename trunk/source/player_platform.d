module ud1_arkanoid_d.player_platform;
import ud1_arkanoid_d.physical_object;

class PlayerPlatform : PhysicalObject {
	import ud1_arkanoid_d.vector2d;

	Vector clampPosition(Vector pos) const {
		Vector left_bottom_ = left_bottom + scale*0.5;
		Vector right_top_ = right_top - scale*0.5;

		if (pos.x < left_bottom_.x)
			pos.x = left_bottom_.x;
		if (pos.y < left_bottom_.y)
			pos.y = left_bottom_.y;
		if (pos.x > right_top_.x)
			pos.x = right_top_.x;
		if (pos.y > right_top_.y)
			pos.y = right_top_.y;

		return pos;
	}

	const(Vector) setTarget(Vector pos) {
		target = clampPosition(pos);
		return target;
	}

	void setTargetAngle(float angle_) {
		target_angle = angle_;
	}

	void calculateVelocity(float delta_t) {
		PhysicalObject.setTarget(target, target_angle, delta_t);
	}

	override void initPosition(in Vector pos, float angle_ = 0.0f) {
		target = clampPosition(pos);
		target_angle = angle_;
		PhysicalObject.initPosition(target, angle_);
	}

	const(Vector) getTarget() const {
		return target;
	}

	void setArea(in Vector left_bottom_, in Vector right_top_) {
		left_bottom = left_bottom_;
		right_top = right_top_;
	}

	void setNoVelocityLoss(bool b) {
		if (b)
			collision_object.velocity_loss = 0.0f;
		else collision_object.velocity_loss = velocity_loss_saved;
	}

	override void setSurfaceParams(float velocity_loss, float surf_friction_coef) {
		collision_object.velocity_loss = velocity_loss_saved = velocity_loss;
		collision_object.surf_friction_coef = surf_friction_coef;
	}

private:
	Vector left_bottom, right_top;

	Vector target;
	float target_angle;

	float velocity_loss_saved;
}

