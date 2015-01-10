module ud1_arkanoid_d.chars_info;

struct CharsInfo {
	static struct CharRect {
		float left, top, right, bottom;
	};

	const(CharRect) *get(char ch) const {
		return (ch in chars);
	}

	float getWidth() const {
		return max_width;
	}

	float getHeight() const {
		return max_height;
	}

	void loadFromFile(string filename)
	{
		import std.stdio;
		import std.format;

		auto f = File(filename, "r");

		max_width = max_height = 0.0f;
		chars = null;

		foreach(line; f.byLine()) {
            if (line.length < 3)
				continue;

			if (line[0] == '/' && line[1] == '/')
				continue;

			char ch;
			CharRect rect;
			if (formattedRead(line, "%s %s %s %s %s", &ch, &rect.left, &rect.top, &rect.right, &rect.bottom) != 5)
				throw new Exception("Parse error: " ~ line.idup);

			chars[ch] = rect;

			float w = rect.right - rect.left;
			if (w > max_width)
				max_width = w;

			float h = rect.bottom - rect.top;
			if (h > max_height)
				max_height = h;
		}
	}

private:
	CharRect[char] chars;
	float max_width, max_height;
}
