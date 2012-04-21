class Monster extends Entity {

	var path : Array<{ x : Int, y : Int }>;
	
	public function new(x, y, k) {
		super(x, y, k);
		game.dm.add(mc, Game.PLAN_MONSTER);
		mspeed *= 1.5;
	}
	
	override public function update() {
		var hero = game.hero;
		var dx = x - hero.x;
		var dy = y - hero.y;
		var d = dx * dx + dy * dy;
		if( path == null && d <= 9 && dist(this, hero) <= 3 )
			path = [];
		if( path != null && canMove() ) {
			var p = path.pop();
			if( p == null ) {
				if( x == hero.x && y == hero.y ) {
					game.fight(this);
					return;
				}
				game.world.initPath(x, y);
				path = game.world.getPath(hero.x, hero.y);
			} else if( game.collide(p.x, p.y) && (p.x != hero.x || p.y != hero.y) ) {
				path = [];
			} else {
				x = p.x;
				y = p.y;
			}
		}
		super.update();
	}
	
}