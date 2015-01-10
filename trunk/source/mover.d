module ud1_arkanoid_d.mover;

struct Mover {
	import ud1_arkanoid_d.vector2d;

	~this() {
		import std.stdio;
	}

	static struct MoveBase {
		float period, start_time, end_time, time_offset;
		int symmetric; // bool
	};

	static struct PosLin {
		MoveBase moveBase;
		alias moveBase this;
		Vector delta_pos;
	};

	static struct PosSine {
		MoveBase moveBase;
		alias moveBase this;
		Vector delta_pos;
	};

	static struct AngleLin {
		MoveBase moveBase;
		alias moveBase this;
		float delta_angle;
	};

	static struct AngleSine {
		MoveBase moveBase;
		alias moveBase this;
		float delta_angle;
	};

	PosLin[] pos_lin_funcs;
	PosSine[] pos_sine_funcs;
	AngleLin[] angle_lin_funcs;
	AngleSine[] angle_sine_funcs;

	Vector getPositionDelta(float t) const {
		Vector res = Vector(0.0f, 0.0f);

		foreach (pos_lin; pos_lin_funcs)
			res += calc(pos_lin, t);

		foreach (pos_sine; pos_sine_funcs)
			res += calc(pos_sine, t);

		return res;
	}

	float getAngleDelta(float t) const {
		float res = 0.0f;

		foreach (angle_lin; angle_lin_funcs)
			res += calc(angle_lin, t);

		foreach (angle_sine; angle_sine_funcs)
			res += calc(angle_sine, t);

		return res;
	}

protected:
	float getFactor(in MoveBase mv, float t) const {
		import std.math;

		t += mv.time_offset;
		if (t > mv.period) {
			t = fmod(t, mv.period);
		} else if (t < 0.0f) {
			t += mv.period*(1 + cast(int)(-t/mv.period));
		}

		if (t <= mv.start_time)
			return 0.0f;

		if (t >= mv.end_time) {
			if (mv.symmetric)
				return 0.0f;
			return 1.0f;
		}

		if (mv.symmetric) {
			float mid = (mv.start_time + mv.end_time)/2.0f;
			float len = (mv.end_time - mv.start_time)/2.0f;
			return t < mid ? (t - mv.start_time)/len : (mv.end_time - t)/len;
		}

		float len = mv.end_time - mv.start_time;
		return (t - mv.start_time) / len;
	}

	Vector calc(in PosLin p_lin, float t) const {
		return p_lin.delta_pos*getFactor(p_lin, t);
	}

	Vector calc(in PosSine p_sine, float t) const {
		import std.math;

		float c = cos(getFactor(p_sine, t)*PI);
		return p_sine.delta_pos*( (1.0f - c)/2.0f );
	}

	float calc(in AngleLin a_lin, float t) const {
		return a_lin.delta_angle*getFactor(a_lin, t);
	}

	float calc(in AngleSine a_sine, float t) const {
		import std.math;

		float c = cos(getFactor(a_sine, t)*PI);
		return a_sine.delta_angle*( (1.0f - c)/2.0f );
	}
}

