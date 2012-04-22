class Monster extends Entity {

	var path : Array<{ x : Int, y : Int }>;
	var wait : Float;
	var attSpeed : Float;
	public var life : Int;
	
	public function new(x, y, k) {
		super(x, y, k);
		game.dm.add(mc, Game.PLAN_MONSTER);
		mspeed *= 1.5;
		attSpeed = 1.;
		wait = 0;
		life = getStats().life;
		mc.addEventListener(flash.events.MouseEvent.MOUSE_OVER, function(_) {
			tip();
		});
		mc.addEventListener(flash.events.MouseEvent.MOUSE_OUT, function(_) {
			mc.filters = [];
			game.help();
		});
	}
	
	function tip() {
		if( game.world.fog[x][y] == 1 )
			return;
		var s = getStats();
		var desc = Std.format("${s.name}    Att:${s.att} Def:${s.def} Life:${s.life}");
		var hero = game.hero;
		var color = 0xFFFFFF;
		if( s.def >= hero.attack )
			color = 0xFF0000;
		else {
			var k = Math.ceil(s.life / (hero.attack - s.def));
			var loose = k * (s.att - hero.defense);
			if( loose <= 0 )
				color = 0x00FF00;
			else {
				desc += " - you will lose " + loose + " life";
				if( loose >= hero.life ) color = 0xFF0000;
			}
		}
		mc.filters = [new flash.filters.GlowFilter(color, 0.8, 2, 2, 10, 2)];
		game.help(desc);
	}
	
	public function getStats() {
		return switch(kind) {
			case Blob: { name : "Blob", life : 10, att : 10, def : 5, gold : 1 };
			case Spider: { name : "Spider", life : 20, att : 20, def : 10, gold : 10 };
			case GreenOrc: { name : "Green Orc", life : 20, att : 15, def : 5, gold : 5 };
			case Skeleton: { name : "Skeleton", life : 30, att : 20, def : 10, gold : 4 };
			case Shadow: { name : "Shadow", life : 10, att : 30, def : game.hero.hasItem(LightSaber) ? 99 : 15, gold : 10 };
			default: { name : "???", life : 1, att : 0, def : 0, gold : 0 };
		};
	}
	
	override public function update() {
		var hero = game.hero;
		var dx = x - hero.x;
		var dy = y - hero.y;
		var d = dx * dx + dy * dy;
		if( path == null && d <= 9 && dist(this, hero) <= 3 )
			path = [];
		wait -= attSpeed;
		if( path != null && canMove() ) {
			var p = path.pop();
			if( p == null ) {
				game.world.initPath(x, y);
				path = game.world.getPath(hero.x, hero.y);
			} else if( game.collide(p.x, p.y) ) {
				if( p.x == hero.x && p.y == hero.y && wait < 0 ) {
					game.fight(this);
					wait = 30;
				}
				path = [];
			} else {
				x = p.x;
				y = p.y;
			}
		}
		super.update();
	}
	
}