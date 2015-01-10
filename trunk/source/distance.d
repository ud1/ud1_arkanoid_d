module ud1_arkanoid_d.distance;

import ud1_arkanoid_d.vector2d;
import ud1_arkanoid_d.ball;
import ud1_arkanoid_d.segment;
import ud1_arkanoid_d.wall;
import ud1_arkanoid_d.physical_object;
import ud1_arkanoid_d.player_platform;

struct DistanceInfo {
	float distance;
	float velocity, rotation_speed;
	Vector closest_point, normal;
}

// returns a distance between a ball and an object
DistanceInfo ballToPhysObjDistance(PhysObj)(in Ball b, in PhysObj obj);

// check if a ball collided with an object
// it's faster than the BallToPhysObjDistance()
bool ballToPhysObjCollided(PhysObj)(in Ball b, in PhysObj obj);


// ------------ Implementation -----------------

private float ballToPhysObjDistanceLight(PhysObj)(in Ball b, in PhysObj obj);

private DistanceInfo distance(in Vector point, in Vector point_velocity, float rotation_speed, in Segment s) {
	DistanceInfo res;
	Vector relp = point - s.p1;
	Vector tau = Vector(s.angle);
	Vector p2 = s.p1 + tau*s.length;
	Vector closest_point_vel;
	float proj = relp.dot(tau);
	if (proj < 0) {
		res.distance = relp.length;
		res.closest_point = s.p1;
		res.normal = relp;
		res.normal.normalize();
		closest_point_vel = s.velocity;
		if (tau.cross(relp) < 0.0f) {
			res.distance = -res.distance;
			res.normal = res.normal*(-1.0f);
		}
	} else if (proj > s.length) {
		res.distance = (point - p2).length;
		res.closest_point = p2;
		res.normal = point - p2;
		res.normal.normalize();
		closest_point_vel = s.velocity + tau.rotateHalfPi() * (s.length * s.angular_velocity);
		if (tau.cross(relp) < 0.0f) {
			res.distance = -res.distance;
			res.normal = res.normal*(-1.0f);
		}
	} else {
		res.distance = tau.cross(relp);
		res.closest_point = s.p1 + tau*proj;
		res.normal = tau.rotateHalfPi();
		closest_point_vel = s.velocity + tau.rotateHalfPi() * (proj * s.angular_velocity);
	}

	res.velocity = res.normal.dot(closest_point_vel - point_velocity);
	res.rotation_speed = -res.normal.cross(closest_point_vel - point_velocity) - rotation_speed;
	return res;
}

float distanceLight(in Vector point, in Segment s) {
	Vector relp = point - s.p1;
	Vector tau = Vector(s.angle);
	float proj = relp.dot(tau);
	float res;
	if (proj < 0) {
		res = relp.length;
		if (tau.cross(relp) < 0.0f) {
			res = -res;
		}
	} else if (proj > s.length) {
		Vector p2 = s.p1 + tau*s.length;
		res = (point - p2).length;
		if (tau.cross(relp) < 0.0f) {
			res = -res;
		}
	} else {
		res = tau.cross(relp);
	}
	return res;
}

DistanceInfo ballToPhysObjDistance(PhysObj : Wall)(in Ball b, in PhysObj w) {
	DistanceInfo res = distance(b.position, b.velocity, b.rotation_speed, w);
	res.distance -= b.rad;
	return res;
}

float ballToPhysObjDistanceLight(PhysObj : Wall)(in Ball b, in PhysObj w) {
	return distanceLight(b.position, w) - b.rad;
}

bool ballToPhysObjCollided(PhysObj : Wall)(in Ball b, in PhysObj w) {
	return ballToPhysObjDistanceLight(b, w) <= 0.0f;
}

DistanceInfo ballToPhysObjDistance(PhysObj : Ball)(in Ball b1, in PhysObj b2) {
	DistanceInfo res;
	Vector b2_b1 = b1.position - b2.position;
	res.distance = b2_b1.length - b1.rad - b2.rad;

	res.normal = b2_b1;
	res.normal.normalize();
	res.closest_point = b2.position + res.normal * b2.rad;
	res.velocity = (b2.velocity - b1.velocity).dot(res.normal);
	res.rotation_speed = -(b1.rotation_speed + b2.rotation_speed) + (b2.velocity - b1.velocity).cross(res.normal);
	return res;
}

bool ballToPhysObjCollided(PhysObj : Ball)(in Ball b1, in PhysObj b2) {
	float rad2 = b1.rad + b2.rad;
	rad2 *= rad2;

	return (b1.position - b2.position).length2 <= rad2;
}

DistanceInfo ballToPhysObjDistance(PhysObj : PhysicalObject)(in Ball b, in PhysObj obj) {
	const(Segment[]) segs = obj.getCollObject().getSegments();
	assert(segs.length > 0);
	DistanceInfo dst_min_positive, dst_max_negative;
	bool has_positive_values = false;
	bool has_negative_values = false;
	for (size_t i = 0; i < segs.length; ++i) {
		DistanceInfo dst = distance(b.position, b.velocity, b.rotation_speed, segs[i]);
		if (dst.distance > 0.0f) {
			if (has_positive_values) {
				if (dst_min_positive.distance > dst.distance)
					dst_min_positive = dst;
			} else {
				dst_min_positive = dst;
			}
			has_positive_values = true;
		} else {
			if (has_negative_values) {
				if (dst_max_negative.distance < dst.distance)
					dst_max_negative = dst;
			} else {
				dst_max_negative = dst;
			}
			has_negative_values = true;
		}
	}

	if (has_positive_values) {
		dst_min_positive.distance -= b.rad;
		return dst_min_positive;
	}
	dst_max_negative.distance -= b.rad;
	return dst_max_negative;
}

bool ballToPhysObjCollided(PhysObj : PhysicalObject)(in Ball b, in PhysObj obj) {
	float dist2 = (b.position - obj.getPosition()).length2;
	float sum_rad = b.rad + obj.getCollObject().getBoundingRad();
	if (dist2 > sum_rad*sum_rad)
		return false;

	const(Segment[]) segs = obj.getCollObject().getSegments();
	size_t segs_size = segs.length;
	assert(segs_size > 0);
	bool inside = true;
	for (size_t i = 0; i < segs_size; ++i) {
		float dst = distanceLight(b.position, segs[i]);
		if (dst > 0 && dst < b.rad)
			return true;
		if (dst > 0)
			inside = false;
	}

	return inside;
}

bool ballToPhysObjCollided(PhysObj : PlayerPlatform)(in Ball b, in PhysObj obj) {
	return ballToPhysObjCollided(b, cast(const PhysicalObject) obj);
}

DistanceInfo ballToPhysObjDistance(PhysObj : PlayerPlatform)(in Ball b, in PhysObj obj) {
	return ballToPhysObjDistance(b, cast(const PhysicalObject) obj);
}
