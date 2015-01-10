module ud1_arkanoid_d.render;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import std.conv;

int round_up_pos_of_2(int val) {
	for (int i = 0; i < 31; ++i) {
		int c = 1 << i;
		if (val <= c)
			return c;
	}
	return 0;
}

GLint getTextureFormat(SDL_Surface *image) {
	int nOfColors = image.format.BytesPerPixel;
	if (nOfColors == 4) {
		if (image.format.Rmask == 0x000000ff)
			return GL_RGBA;
		else
			return GL_BGRA;
	} else if (nOfColors == 3) {
		if (image.format.Rmask == 0x000000ff)
			return GL_RGB;
		else
			return GL_BGR;
	}

	return GL_RGB;
}

void build2DMipmaps(SDL_Surface *image) {
	int width = image.w;
	int height = image.h;
	ubyte[] old_data = (cast(ubyte*) image.pixels)[0..width*height*3];

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, getTextureFormat(image), GL_UNSIGNED_BYTE, image.pixels);
	int lod = 0;
	while ((width /= 2) && (height /= 2)) {
		++lod;
		ubyte[] new_data = new ubyte[width*height*3];
		for (int i = 0; i < height; ++i) {
			for (int j = 0; j < width; ++j) {
				uint v =
					old_data[3*((2*i+0)*(2*width)	+ 2*j + 0)+0] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 0)+0] +
					old_data[3*((2*i+0)*(2*width)	+ 2*j + 1)+0] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 1)+0];
				new_data[3*(i*width+j)+0] = cast(ubyte) (v/4);

				v = old_data[3*((2*i+0)*(2*width)	+ 2*j + 0)+1] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 0)+1] +
					old_data[3*((2*i+0)*(2*width)	+ 2*j + 1)+1] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 1)+1];
				new_data[3*(i*width+j)+1] = cast(ubyte) (v/4);

				v = old_data[3*((2*i+0)*(2*width)	+ 2*j + 0)+2] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 0)+2] +
					old_data[3*((2*i+0)*(2*width)	+ 2*j + 1)+2] +
					old_data[3*((2*i+1)*(2*width)	+ 2*j + 1)+2];
				new_data[3*(i*width+j)+2] = cast(ubyte) (v/4);
			}
		}

		glTexImage2D(GL_TEXTURE_2D, lod, GL_RGB, width, height, 0, getTextureFormat(image), GL_UNSIGNED_BYTE, new_data.ptr);
		old_data = new_data;
	}
}

struct RenderData {
	import ud1_arkanoid_d.game;
	import ud1_arkanoid_d.vector2d;
	import ud1_arkanoid_d.chars_info;
	import ud1_arkanoid_d.chars_info;
	import ud1_arkanoid_d.ball_render_info;
	import ud1_arkanoid_d.ball;
	import ud1_arkanoid_d.bonus;
	import ud1_arkanoid_d.bonus_info;
	import ud1_arkanoid_d.physical_object;
	import ud1_arkanoid_d.render_object;

	~this() {

	}

	static struct Color {
		float r, g, b;
		this(float r_, float g_, float b_) {
			r = r_;
			g = g_;
			b = b_;
		}
	};

	void setGame(Game *game_) {
		game = game_;
	}

	void init(bool disable_effects_) {
		disable_effects = disable_effects_;
		elements = SDL_LoadBMP("data/images.bmp");
		if (!elements)
			throw new Exception("Cannot load data/images.bmp");

		stat_img = SDL_LoadBMP("data/stats.bmp");
		if (!stat_img)
			throw new Exception("Cannot load data/stats.bmp");

		background = SDL_LoadBMP("data/background.bmp");
		if (!background)
			throw new Exception("Cannot load data/background.bmp");

		clouds = SDL_LoadBMP("data/clouds.bmp");
		if (!clouds)
			throw new Exception("Cannot load data/clouds.bmp");

		big_chars.loadFromFile("conf/big_chars.txt");
		small_chars.loadFromFile("conf/small_chars.txt");
		ball_rdata.loadFromFile("conf/balls.txt");

		// upload elements texture
		glGenTextures(1, &elements_textureID);
		glBindTexture(GL_TEXTURE_2D, elements_textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		build2DMipmaps(elements);
		glBindTexture(GL_TEXTURE_2D, 0);

		// upload stat_img texture
		stat_tex_w = round_up_pos_of_2(stat_img.w);
		stat_tex_h = round_up_pos_of_2(stat_img.h);
		glGenTextures(1, &stat_textureID);
		glBindTexture(GL_TEXTURE_2D, stat_textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, stat_tex_w, stat_tex_h, 0, getTextureFormat(stat_img), GL_UNSIGNED_BYTE, null);
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, stat_img.w, stat_img.h, getTextureFormat(stat_img), GL_UNSIGNED_BYTE, stat_img.pixels);
		glBindTexture(GL_TEXTURE_2D, 0);

		// upload background texture
		glGenTextures(1, &background_textureID);
		glBindTexture(GL_TEXTURE_2D, background_textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, background.w, background.h, 0, getTextureFormat(background), GL_UNSIGNED_BYTE, background.pixels);
		glBindTexture(GL_TEXTURE_2D, 0);

		// upload cloud texture
		glGenTextures(1, &clouds_textureID);
		glBindTexture(GL_TEXTURE_2D, clouds_textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, clouds.w, clouds.h, 0, getTextureFormat(clouds), GL_UNSIGNED_BYTE, clouds.pixels);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void renderField() {
		startRenderStat();
		renderBackground();

		startRenderField(game.getFieldLogicSize());

		if (!disable_effects) {
			glStencilMask(-1);
			glStencilFunc(GL_ALWAYS, 1, 0);
			glStencilOp(GL_KEEP, GL_REPLACE, GL_REPLACE);
			glEnable(GL_STENCIL_TEST);
		}

		renderObjectsAndPlatform();

		if (!disable_effects) {
			glDisable(GL_STENCIL_TEST);
		}

		foreach (ref Bonus bonus; game.world.bonuses) {
			renderBonus(bonus);
		}

		foreach (ref Ball ball; game.world.balls) {
			renderBall(ball);
		}
	}

	void renderStats() {
		startRenderStat();
		renderStatsPanel();
		renderScore();
		renderLevelNumber();
	}

	void renderClouds(float dtx, float dty, float alpha) {
		if (disable_effects)
			return;
		glEnable(GL_STENCIL_TEST);
		glEnable(GL_BLEND);
		glStencilFunc(GL_EQUAL, 1, -1);
		glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		startRenderStat();
		float x = game.form_config.field.x;
		float y = game.form_config.field.y;
		float w = game.form_config.field.width;
		float h = game.form_config.field.height;
		float tx = cast(float) w / cast(float) clouds.w;
		float ty = cast(float) h / cast(float) clouds.h;
		glColor4f(1.0f, 1.0f, 1.0f, alpha);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, clouds_textureID);
		glBegin(GL_QUADS);
		glTexCoord2f(dtx, dty);
		glVertex2f(x, y);

		glTexCoord2f(tx + dtx, dty);
		glVertex2f(x + w, y);

		glTexCoord2f(tx + dtx, ty + dty);
		glVertex2f(x + w, y + h);

		glTexCoord2f(dtx, ty + dty);
		glVertex2f(x, y + h);
		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);

		glDisable(GL_BLEND);
		glDisable(GL_STENCIL_TEST);
	}

	void renderDark(float darkness) {
		startRenderStat();
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glColor4f(0.0f, 0.0f, 0.0f, darkness);
		glBegin(GL_QUADS);
			glVertex2f(0.0f, 0.0f);
			glVertex2f(game.form_config.window.width, 0.0f);
			glVertex2f(game.form_config.window.width, game.form_config.window.height);
			glVertex2f(0.0f, game.form_config.window.height);
		glEnd();
		glDisable(GL_BLEND);
	}


	void printTextBig(string text, in Vector pos, in Color color) {
		printText(text, big_chars, pos, color);
	}

	void printTextSmall(string text, in Vector pos, in Color color) {
		printText(text, small_chars, pos, color);
	}

	CharsInfo big_chars, small_chars;

private:
	Game *game;
	SDL_Surface *elements;
	SDL_Surface *stat_img;
	SDL_Surface *background;
	SDL_Surface *clouds;
	BallRenderData ball_rdata;
	bool disable_effects;

	int stat_tex_w, stat_tex_h;
	GLuint elements_textureID, stat_textureID, background_textureID, clouds_textureID;

	void renderBackground() {
		float x = game.form_config.field.x;
		float y = game.form_config.field.y;
		float w = game.form_config.field.width;
		float h = game.form_config.field.height;
		float tx = cast(float) w / cast(float) background.w;
		float ty = cast(float) h / cast(float) background.h;
		glColor3f(1,1,1);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, background_textureID);
		glBegin(GL_QUADS);
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f(x, y);
		glTexCoord2f(tx, 0.0f);
		glVertex2f(x + w, y);
		glTexCoord2f(tx, ty);
		glVertex2f(x + w, y + h);
		glTexCoord2f(0.0f, ty);
		glVertex2f(x, y + h);
		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void renderObjectsAndPlatform() {
		glColor3f(1,1,1);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, elements_textureID);
		glBegin(GL_TRIANGLES);

		foreach (PhysicalObject obj; game.world.objects) {
			const (RenderTriangle []) tris = obj.getRenderObject().getTriangles();

			foreach (const ref RenderTriangle tri; tris) {
				glTexCoord2f(tri.vertexes[0].tex_coord.x / elements.w, tri.vertexes[0].tex_coord.y / elements.h);
				glVertex2f(tri.vertexes[0].coord.x, tri.vertexes[0].coord.y);

				glTexCoord2f(tri.vertexes[1].tex_coord.x / elements.w, tri.vertexes[1].tex_coord.y / elements.h);
				glVertex2f(tri.vertexes[1].coord.x, tri.vertexes[1].coord.y);

				glTexCoord2f(tri.vertexes[2].tex_coord.x / elements.w, tri.vertexes[2].tex_coord.y / elements.h);
				glVertex2f(tri.vertexes[2].coord.x, tri.vertexes[2].coord.y);
			}
		}

		PhysicalObject obj = game.world.player_platform;
		const (RenderTriangle[]) tris = obj.getRenderObject().getTriangles();

		foreach (const ref RenderTriangle tri; tris) {
			glTexCoord2f(tri.vertexes[0].tex_coord.x / elements.w, tri.vertexes[0].tex_coord.y / elements.h);
			glVertex2f(tri.vertexes[0].coord.x, tri.vertexes[0].coord.y);

			glTexCoord2f(tri.vertexes[1].tex_coord.x / elements.w, tri.vertexes[1].tex_coord.y / elements.h);
			glVertex2f(tri.vertexes[1].coord.x, tri.vertexes[1].coord.y);

			glTexCoord2f(tri.vertexes[2].tex_coord.x / elements.w, tri.vertexes[2].tex_coord.y / elements.h);
			glVertex2f(tri.vertexes[2].coord.x, tri.vertexes[2].coord.y);
		}

		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void startRenderField(in Vector field_logic_size) {
		float a = field_logic_size.x / game.form_config.field.width;
		float b = -a * game.form_config.field.x;
		float c = field_logic_size.y / game.form_config.field.height;
		float d = -c * game.form_config.field.y;
		glMatrixMode (GL_PROJECTION);
		glLoadIdentity ();
		glOrtho(b, a * game.window.width + b,
			d, c * game.window.height + d,
			-100.0,100.0);
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity ();
	}

	void startRenderStat() {
		glMatrixMode (GL_PROJECTION);
		glLoadIdentity ();
		glOrtho(0.0, game.window.width,
			game.window.height, 0.0,
			-100.0,100.0);
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity();
	}

	void renderBall(ref Ball b) {
		b.collide_number %= ball_rdata.balls.length;
		const BallRenderData.BallRect *ball_rect = &ball_rdata.balls[b.collide_number];

		glColor3f(1,1,1);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, elements_textureID);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
		glBegin(GL_QUADS);
		glTexCoord2f(ball_rect.left / elements.w, ball_rect.top / elements.h);
		glVertex2f(b.position.x - b.rad, b.position.y + b.rad);

		glTexCoord2f(ball_rect.right / elements.w, ball_rect.top / elements.h);
		glVertex2f(b.position.x + b.rad, b.position.y + b.rad);

		glTexCoord2f(ball_rect.right / elements.w, ball_rect.bottom / elements.h);
		glVertex2f(b.position.x + b.rad, b.position.y - b.rad);

		glTexCoord2f(ball_rect.left / elements.w, ball_rect.bottom / elements.h);
		glVertex2f(b.position.x - b.rad, b.position.y - b.rad);
		glEnd();
		glDisable(GL_BLEND);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void renderBonus(in Bonus b) {
		const BonusInfo.BonusRect *bonus_rect = &game.bonus_info.info[b.bonus_type];

		glColor3f(bonus_rect.red, bonus_rect.green, bonus_rect.blue);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, elements_textureID);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
		glBegin(GL_QUADS);
		glTexCoord2f(bonus_rect.left / elements.w, bonus_rect.top / elements.h);
		glVertex2f(b.position.x - b.rad, b.position.y + b.rad);

		glTexCoord2f(bonus_rect.right / elements.w, bonus_rect.top / elements.h);
		glVertex2f(b.position.x + b.rad, b.position.y + b.rad);

		glTexCoord2f(bonus_rect.right / elements.w, bonus_rect.bottom / elements.h);
		glVertex2f(b.position.x + b.rad, b.position.y - b.rad);

		glTexCoord2f(bonus_rect.left / elements.w, bonus_rect.bottom / elements.h);
		glVertex2f(b.position.x - b.rad, b.position.y - b.rad);
		glEnd();
		glDisable(GL_BLEND);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void renderStatsPanel() {
		glColor3f(1,1,1);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, stat_textureID);
		glBegin(GL_QUADS);
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f(game.form_config.stat_panel.left, game.form_config.stat_panel.top);

		glTexCoord2f(cast(float) stat_img.w / cast(float) stat_tex_w, 0.0f);
		glVertex2f(game.form_config.stat_panel.right, game.form_config.stat_panel.top);

		glTexCoord2f(
			cast(float) stat_img.w / cast(float) stat_tex_w,
			cast(float) stat_img.h / cast(float) stat_tex_h);
		glVertex2f(game.form_config.stat_panel.right, game.form_config.stat_panel.bottom);

		glTexCoord2f(0.0f, cast(float) stat_img.h / cast(float) stat_tex_h);
		glVertex2f(game.form_config.stat_panel.left, game.form_config.stat_panel.bottom);
		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void renderScore() {
		string score = to!string(game.score.get());

		float w = score.length*big_chars.getWidth();
		float h = big_chars.getHeight();
		Vector pos = Vector(
			game.form_config.score_position.right - w,
			(game.form_config.score_position.top + game.form_config.score_position.bottom - h)/2.0f);

		printText(score, big_chars, pos, Color(1.0f, 0.0f, 0.0f));
	}

	void renderLevelNumber() {
		import std.string;

		string score = format("%02d", game.getLevel());

		float w = score.length*small_chars.getWidth();
		float h = small_chars.getHeight();
		Vector pos = Vector(
			game.form_config.level_position.right - w,
			(game.form_config.level_position.top + game.form_config.level_position.bottom - h)/2.0f);

		printText(score, small_chars, pos, Color(1.0f, 0.0f, 0.0f));
	}

	// pos - top left point
	void printText(string text, in CharsInfo info, Vector pos, in Color color) {
		glColor3f(color.r, color.g, color.b);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, elements_textureID);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);

		float rect_w = info.getWidth();
		glBegin(GL_QUADS);
		for (size_t i = 0; i < text.length; ++i) {
			char ch = text[i];
			const CharsInfo.CharRect *rect = info.get(ch);
			if (rect) {
				float w = rect.right - rect.left;
				float h = rect.bottom - rect.top;
				float rx = pos.x + rect_w - w;

				glTexCoord2f(rect.left / elements.w, rect.top / elements.h);
				glVertex2f(rx, pos.y);

				glTexCoord2f(rect.right / elements.w, rect.top / elements.h);
				glVertex2f(rx + w, pos.y);

				glTexCoord2f(rect.right / elements.w, rect.bottom / elements.h);
				glVertex2f(rx + w, pos.y + h);

				glTexCoord2f(rect.left / elements.w, rect.bottom / elements.h);
				glVertex2f(rx, pos.y + h);
			}

			pos.x += rect_w;
		}
		glEnd();
		glDisable(GL_BLEND);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

}
