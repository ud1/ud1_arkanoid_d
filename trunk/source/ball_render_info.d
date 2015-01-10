module ud1_arkanoid_d.ball_render_info;

struct BallRenderData {
	static struct BallRect {
		float left, top, right, bottom;
	};

	BallRect[] balls;

	void loadFromFile(string filename) {
		import std.stdio;
		import std.format;

		balls = null;
		auto f = File(filename, "r");

		foreach(line; f.byLine()) {
            if (line.length < 3)
				continue;

			if (line[0] == '/' && line[1] == '/')
				continue;

			BallRect rect;
			if (formattedRead(line, "%s %s %s %s", &rect.left, &rect.top, &rect.right, &rect.bottom) != 4)
				throw new Exception("Parse error: " ~ line.idup);

			balls ~= rect;
		}
	}
}
