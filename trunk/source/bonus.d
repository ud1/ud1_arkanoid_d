module ud1_arkanoid_d.bonus;

struct Bonus {
	import ud1_arkanoid_d.ball;
	import ud1_arkanoid_d.bonus_info;
	import ud1_arkanoid_d.vector2d;
	import ud1_arkanoid_d.game;
	import ud1_arkanoid_d.world;

	Ball ball;
	alias ball this;

	this(in Vector pos, in BonusInfo info, BonusType type, Game *game) {
		rad = info.bonus_rad;
		position = pos;
		velocity = Vector(0.0f, -info.speed);
		gravity = Vector(0.0f, 0.0f);
		this.bonus_type = type;
		this.game = game;
	}

	void move(float delta_t) {
		position = position + velocity*delta_t;
	}

	void collide() {
		game.activateBonus(this);
		game.sound_system.play(Sounds.BONUS_SOUND, 1.0f);
	}

	BonusType bonus_type;
	Game *game;
}
