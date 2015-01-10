module ud1_arkanoid_d.polygon_collision_object;

struct SegmentProto {
	import ud1_arkanoid_d.vector2d;

	Vector p1, p2;
}

struct PolygonColObjPrototype {
	SegmentProto[] segs;
}

struct PolygonCollisionObject {
	import ud1_arkanoid_d.segment;
	import ud1_arkanoid_d.vector2d;

	// must be the first function called
	void setPrototype(in PolygonColObjPrototype proto, in Vector scale) {
		import std.math;

		max_radius = 0.0f;
		size_t segs_size = proto.segs.length;
		segs.length = segs_size;
		proto_segs.length = segs_size;

		for (size_t i = 0; i < segs_size; ++i) {
			Segment *seg = &proto_segs[i];
			const SegmentProto *prot_seg = &proto.segs[i];
			Vector p1 = prot_seg.p1 * scale;
			Vector p2 = prot_seg.p2 * scale;
			seg.initialize(p1, p2);

			float p1_rad2 = p1.length2;
			float p2_rad2 = p2.length2;

			if (p1_rad2 < p2_rad2)
				p1_rad2 = p2_rad2;
			if (max_radius < p1_rad2)
				max_radius = p1_rad2;
		}

		max_radius = sqrt(max_radius);
	}

	void setPosition(in Vector pos, float angle, in Vector velocity, float angular_vel) {
		import std.math;

		float sina = sin(angle);
		float cosa = cos(angle);

		size_t segs_size = proto_segs.length;
		for (size_t i = 0; i < segs_size; ++i) {
			Segment *seg = &segs[i];
			const Segment *prot_seg = &proto_segs[i];
			seg.p1 = pos + prot_seg.p1.rotate(sina, cosa);
			seg.length = prot_seg.length;
			seg.angle = prot_seg.angle + angle;
			seg.angular_velocity = angular_vel;
			seg.velocity = velocity + prot_seg.p1.rotateHalfPi()*angular_vel;
		}
	}

	const(Segment[]) getSegments() const {
		return segs;
	}

	float getBoundingRad() const {
		return max_radius;
	}

	float velocity_loss, surf_friction_coef;

private:
	Segment[] segs, proto_segs;
	float max_radius;
}
