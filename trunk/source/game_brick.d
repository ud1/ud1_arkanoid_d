module ud1_arkanoid_d.game_brick;
import ud1_arkanoid_d.physical_object;

class GameBrick : PhysicalObject {
	import ud1_arkanoid_d.bonus_info;
	import ud1_arkanoid_d.level;
	import ud1_arkanoid_d.game;

	this(Game *game_) {
		game = game_;
	}

	void initialize(in Level.BrickInfo info, in ObjectPrototype proto) {
		setPrototype(proto, info.scale);
		mover = info.mover;
		initPosition(info.pos, info.angle);
		life = info.life;
		game_points = info.points;
		is_static = info.is_static != 0;
		setSurfaceParams(info.velocity_loss, info.surf_friction_coef);
		bonus = info.bonus();
	}

	override void collide() {
		if (!is_static) {
			game.score.add(game_points);

			--life;
			if (life == 0) {
				if (bonus >= BonusType.BONUS_MIN && bonus < BonusType.BONUS_MAX) {
					game.createBonus(position, bonus);
				} else if (bonus == BonusType.BONUS_NEW_BALL) {
					game.newBall(position, Vector(0.0f, 0.0f));
				}
				game.world.removeObj(this);
			}
		}
	}

	bool isStatic() const {
		return is_static != 0;
	}

private:
	Game *game;
	int life, game_points;
	BonusType bonus;
	int is_static; // bool
};

