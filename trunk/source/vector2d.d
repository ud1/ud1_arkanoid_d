module ud1_arkanoid_d.vector2d;

struct Vector {
    float[2] coords;

	@property {
		float x() const {
			return coords[0];
		}

		ref float x() {
			return coords[0];
		}

		float y() const {
			return coords[1];
		}

		ref float y() {
			return coords[1];
		}
	}

	this(float x, float y) {
		this.x = x;
		this.y = y;
	}

	this(float angle) {
		import std.math;

		x = cos(angle);
		y = sin(angle);
	}

	float dot(in Vector o) const {
		return x*o.x + y*o.y;
	}

	float cross(in Vector o) const {
		return x*o.y - y*o.x;
	}

	@property float length() const {
		import std.math;

		return sqrt(x*x + y*y);
	}

	@property float length2() const {
		return x*x + y*y;
	}

	Vector rotate(float angle) const {
		import std.math;

		float sina = sin(angle);
		float cosa = cos(angle);
		return Vector(x*cosa - y*sina, x*sina + y*cosa);
	}

	// little optimization
	Vector rotate(float sina, float cosa) const {
		return Vector(x*cosa - y*sina, x*sina + y*cosa);
	}

	Vector rotateHalfPi() const {
		return Vector(-y, x);
	}

	void normalize() {
		float rlen = length();
		if (rlen > 0.0f) {
			x /= rlen;
			y /= rlen;
		} else {
			x = 1.0f;
			y = 0.0f;
		}
	}

	Vector reflect(in Vector normal) const {
		float proj = dot(normal);
		return this - normal*(2.0f*proj);
	}

	bool isNull() const {
		return (x == 0.0f && y == 0.0f);
	}

	Vector opBinary(string op)(in Vector o) const if (op == "-" || op == "+" || op == "*") {
		Vector result;
		result.coords = mixin("coords[]" ~ op ~ "o.coords[]");
		return result;
	}

	Vector opBinary(string op)(float v) const if (op == "*" || op == "/") {
		Vector result;
		result.coords = mixin("coords[]" ~ op ~ "v");
		return result;
	}

	ref Vector opOpAssign(string op)(in Vector o) if (op == "-" || op == "+") {
		mixin("this.coords[] " ~ op ~ "= o.coords[];");
		return this;
	}

	bool opEquals()(auto ref const Vector v) const {
		return x == v.x && y == v.y;
	}
}

unittest {
	const Vector v1 = Vector(10.0f, 20.0f);
	const Vector v2 = Vector(1.0f, 2.0f);

	Vector v3 = v1 - v2;

	assert(v3.x == 9.0f && v3.y == 18.0f);

	v3 += Vector(1.0f, 2.0f);
	assert(v3.x == 10.0f && v3.y == 20.0f);
	assert(v3 == Vector(10.0f, 20.0f));
}
