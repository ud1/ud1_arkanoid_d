module ud1_arkanoid_d.bonus_info;

enum BonusType {
	BONUS_NEW_BALL = 1,
	BONUS_MIN = 2,
	BONUS_LONG_PLATFORM = 2,
	BONUS_SHORT_PLATFORM = 3,
	BONUS_GRAVITY_LEFT = 4,
	BONUS_GRAVITY_RIGHT = 5,
	BONUS_TIMER_SPEED_DOWN = 6,
	BONUS_TIMER_SPEED_UP = 7,
	BONUS_RESERVE_BALL = 8,
	BONUS_MAX
}

struct BonusInfo {
	static struct BonusRect {
		float left, top, right, bottom;
		float red, green, blue;
	}

	void loadFromFile(string filename) {
		import std.stdio;
		import std.format;

		auto f = File(filename, "r");

		foreach(line; f.byLine()) {
            if (line.length < 3)
				continue;

			if (line[0] == '/' && line[1] == '/')
				continue;

			string cmd;
			if (formattedRead(line, "%s ", &cmd) != 1)
				throw new Exception("Parse error: " ~ line.idup);

			if (cmd == "bonus") {
				BonusRect rect;
				int type;
				if (formattedRead(line, "%s %s %s %s %s %s %s %s", &type, &rect.left, &rect.top, &rect.right, &rect.bottom,
					&rect.red, &rect.green, &rect.blue) == 8)
				{
					if (type >= BonusType.BONUS_MIN && type < BonusType.BONUS_MAX) {
						info[type] = rect;
					}
				} else {
					throw new Exception("Parse error, bonus: " ~ line.idup);
				}
			} else if (cmd == "radius") {
				if (formattedRead(line, "%s", &bonus_rad) != 1) {
					throw new Exception("Parse error, radius: " ~ line.idup);
				}
			} else if (cmd == "speed") {
				if (formattedRead(line, "%s", &speed) != 1) {
					throw new Exception("Parse error, speed: " ~ line.idup);
				}
			} else {
				throw new Exception("Parse error: " ~ cmd);
			}
		}
	}

	float bonus_rad, speed;
	BonusRect[BonusType.BONUS_MAX] info;
}
