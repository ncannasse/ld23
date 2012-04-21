import Common;

class City {

	public var game : Game;
	public var x : Int;
	public var y : Int;
	public var mc : BMP;
	
	public function new(g, x, y) {
		game = g;
		this.x = x;
		this.y = y;
		mc = new flash.display.Bitmap(game.tiles.t[6][0]);
		mc.x = x * 5;
		mc.y = y * 5;
		game.dm.add(mc,Game.PLAN_CITY);
	}
	
}

class Entity {
	
	public var game : Game;
	public var x : Int;
	public var y : Int;
	public var kind : NpcKind;
	public var mc : BMP;
	
	public var tx : Int;
	public var ty : Int;
	public var moving : Bool;
	
	public var frame : Float;
	public var curFrame : Int;
	public var px : Float;
	public var py : Float;
	
	public var mspeed : Float;
	
	public function new(g, x, y, k) {
		game = g;
		kind = k;
		mspeed = 0.12;
		this.x = tx = x;
		this.y = ty = y;
		moving = false;
		px = x;
		py = y;
		this.mc = new BMP(null,flash.display.PixelSnapping.ALWAYS);
		game.dm.add(mc,Game.PLAN_NPC);
		frame = Math.random() * 10;
		curFrame = -1;
	}
	
	public function canMove() {
		var d = Math.abs(px - tx) + Math.abs(py - ty);
		return d <= mspeed;
	}
	
	public function update() {
		frame += 0.12 * (1 + Math.random() * 0.02);
		var dx = Math.abs(px - tx);
		if( dx > 0 ) {
			if( dx > mspeed ) {
				dx = mspeed;
				moving = true;
			} else
				moving = false;
			px += px > tx ? -dx : dx;
			x = Std.int(px);
		}
		var dy = Math.abs(py - ty);
		if( dy > 0 ) {
			if( dy > mspeed ) {
				dy = mspeed;
				moving = true;
			} else
				moving = false;
			py += py > ty ? -dy : dy;
			y = Std.int(py);
		}
		
		this.mc.x = Std.int(px * 5) - 1;
		this.mc.y = Std.int(py * 5) - 2;
		var t = game.tiles.s[Type.enumIndex(kind)];
		var iframe = Std.int(frame) % t.length;
		if( iframe != curFrame ) {
			curFrame = iframe;
			mc.bitmapData = t[iframe];
		}
	}
	
	function dist(p1, p2) {
		game.world.initPath(p1.x, p1.y);
		return game.world.getDist(p2.x, p2.y);
	}
	
}
