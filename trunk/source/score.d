module ud1_arkanoid_d.score;

struct Score {
	void reset() {
		this = Score.init;
	}

	void add(int s) {
		score += s * speed_bonus * platform_bonus * gravity_bonus * time_bonus;
	}

	int get() const {
		return cast(int) score;
	}

	float speed_bonus = 1.0f, platform_bonus = 1.0f, gravity_bonus = 1.0f, time_bonus = 1.0f;

private:
	float score = 0.0f;
}
