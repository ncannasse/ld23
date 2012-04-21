
class Npc extends Entity {
	
	var target : { x : Int, y : Int };
	var path : Array<{ x : Int, y : Int }>;
	var waitMove : Float;
	
	public function new(g, x, y, k) {
		super(g, x, y, k);
		waitMove = 0;
	}
	
	public function chooseTarget() {
		game.world.initPath(x, y);
		function dist(x, y) return game.world.getDist(x, y);
		switch( Std.random(6) ) {
		case 0, 1, 2:
			// goto city
			var c;
			var cities = game.cities.copy();
			while( true ) {
				c = cities[Std.random(cities.length)];
				if( c == null ) {
					chooseTarget();
					return;
				}
				cities.remove(c);
				var d = dist(c.x,c.y);
				if( d <= 0 ) continue;
				if( d > 100 && Std.random(Math.ceil(d / 100)) != 0 ) continue;
				target = c;
				break;
			}
		case 3, 4:
			// goto place
			var x, y;
			while( true ) {
				x = Std.random(World.SIZE);
				y = Std.random(World.SIZE);
				var d = dist(x,y);
				if( d <= 0 ) continue;
				if( d > 50 && Std.random(Math.ceil(d / 50)) != 0 ) continue;
				target = { x : x, y : y };
				break;
			}
		case 5:
			// follow
			var n;
			var npcs = game.npcs.copy();
			while( true ) {
				n = npcs[Std.random(npcs.length)];
				if( n == null ) {
					chooseTarget();
					return;
				}
				npcs.remove(n);
				var d = dist(n.x,n.y);
				if( d <= 0 ) continue;
				if( d > 30 && Std.random(Math.ceil(d / 20)) != 0 ) continue;
				target = n;
				break;
			}
		default:
			throw "assert";
		}
		path = game.world.getPath(target.x, target.y);
	}

	function nextMove() {
		var p = path.pop();
		if( p == null ) {
			if( Std.random(100) == 0 )
				chooseTarget();
		} else if( !game.collide(p.x,p.y) ) {
			tx = p.x;
			ty = p.y;
		} else {
			game.world.initPath(x, y);
			path = game.world.getPath(target.x, target.y);
		}
	}
	
	override public function update() {
		if( canMove() ) {
			waitMove -= mspeed;
			if( waitMove < 0 ) nextMove();
		} else
			waitMove = 3;
			
		super.update();
	}
	
}
