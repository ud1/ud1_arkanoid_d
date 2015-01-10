module ud1_arkanoid_d.form_config;

struct FormConfig {
	static struct Window {
		int width = 800, height = 600;
	}
	Window window;

	struct Field {
		float width = 600, height = 600, x = 0, y = 0;
		float logic_width = 10.0f, logic_height = 10.0f;
	}
	Field field;

	static struct StatPanel {
		float left = 600, top = 0, right = 800, bottom = 600;
	}
	StatPanel stat_panel;

	static struct ScorePosition {
		int left, top, right, bottom;
	}
	ScorePosition score_position;

	static struct LevelPosition {
		int left = 612, top = 74, right = 787, bottom = 109;
	}
	LevelPosition level_position;

	float mouse_smoothing = 0.07f;
	float background_volume = 0.8f;
	float velocity_volume_factor = 0.05f;
	int disable_effects = 0; // bool

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

			if (cmd == "window") {
				if (formattedRead(line, "%s %s", &window.width, &window.height) != 2) {
					throw new Exception("Parse error, window: " ~ line.idup);
				}
			} else if (cmd == "field") {
				if (formattedRead(line, "%s %s %s %s %s %s", &field.width, &field.height, &field.x, &field.y, &field.logic_width, &field.logic_height) != 6) {
					throw new Exception("Parse error, field: " ~ line.idup);
				}
			} else if (cmd == "stat_panel") {
				if (formattedRead(line, "%s %s %s %s", &stat_panel.left, &stat_panel.top, &stat_panel.right, &stat_panel.bottom) != 4) {
					throw new Exception("Parse error, stat_panel: " ~ line.idup);
				}
			} else if (cmd == "score_position") {
				if (formattedRead(line, "%s %s %s %s", &score_position.left, &score_position.top, &score_position.right, &score_position.bottom) != 4) {
					throw new Exception("Parse error, score_position: " ~ line.idup);
				}
			} else if (cmd == "level_position") {
				if (formattedRead(line, "%s %s %s %s", &level_position.left, &level_position.top, &level_position.right, &level_position.bottom) != 4) {
					throw new Exception("Parse error, level_position: " ~ line.idup);
				}
			} else if (cmd == "mouse_smoothing") {
				if (formattedRead(line, "%s", &mouse_smoothing) != 1) {
					throw new Exception("Parse error, mouse_smoothing: " ~ line.idup);
				}
			} else if (cmd == "background_volume") {
				if (formattedRead(line, "%s", &background_volume) != 1) {
					throw new Exception("Parse error, background_volume: " ~ line.idup);
				}
			} else if (cmd == "velocity_volume_factor") {
				if (formattedRead(line, "%s", &velocity_volume_factor) != 1) {
					throw new Exception("Parse error, velocity_volume_factor: " ~ line.idup);
				}
			} else if (cmd == "disable_effects") {
				if (formattedRead(line, "%s", &disable_effects) != 1) {
					throw new Exception("Parse error, disable_effects: " ~ line.idup);
				}
			} else {
				throw new Exception("Parse error: " ~ cmd);
			}
		}
	}
}
