import Common;

class City {

	public var game : Game;
	public var x : Int;
	public var y : Int;
	
	public function new(g, x, y) {
		game = g;
		this.x = x;
		this.y = y;
	}
	
}

class Entity {

	static var ID = 0;
	public var id : Int;
	
	public var game : Game;
	public var x : Int;
	public var y : Int;
	public var kind : NpcKind;
	public var mc : SPR;
	public var bmp : BMP;
	
	public var moving : Bool;
	
	public var frame : Float;
	public var curFrame : Int;
	public var px : Float;
	public var py : Float;
	
	public var aspeed : Float;
	public var mspeed : Float;
	
	public function new(x, y, k) {
		id = ID++;
		game = Game.inst;
		kind = k;
		aspeed = 1;
		mspeed = 0.12;
		this.x = x;
		this.y = y;
		moving = false;
		px = x;
		py = y;
		this.bmp = new BMP(null, flash.display.PixelSnapping.ALWAYS);
		this.mc = new SPR();
		mc.addChild(bmp);
		game.dm.add(mc,Game.PLAN_NPC);
		frame = Math.random() * 10;
		curFrame = -1;
	}
	
	public function goto(tx,ty) {
		px = x = tx;
		py = y = ty;
	}
	
	public dynamic function onHit() {
		return false;
	}
	
	public function canMove() {
		var d = Math.abs(px - x) + Math.abs(py - y);
		return d <= mspeed;
	}
	
	public function alive() {
		return mc.parent != null;
	}
	
	public function remove() {
		mc.parent.removeChild(mc);
	}
	
	public function update() {
		frame += 0.12 * (1 + Math.random() * 0.02) * aspeed;
		var dx = Math.abs(px - x);
		if( dx > 0 ) {
			if( dx > mspeed ) {
				dx = mspeed;
				moving = true;
			} else
				moving = false;
			px += px > x ? -dx : dx;
		}
		var dy = Math.abs(py - y);
		if( dy > 0 ) {
			if( dy > mspeed ) {
				dy = mspeed;
				moving = true;
			} else
				moving = false;
			py += py > y ? -dy : dy;
		}
		
		this.mc.x = Std.int(px * 5) - 1;
		this.mc.y = Std.int(py * 5) - 2;
		var t = game.tiles.s[Type.enumIndex(kind)];
		var iframe = Std.int(frame) % t.length;
		if( iframe != curFrame ) {
			curFrame = iframe;
			bmp.bitmapData = t[iframe];
			if( iframe == 0 && kind == Twinkle ) {
				var dx = x - game.hero.x;
				var dy = y - game.hero.y;
				var d = dx * dx + dy * dy;
				bmp.visible = bmp.visible ? false : Std.random(d) == 0;
			}
		}
	}
	
	function dist(p1, p2) {
		game.world.initPath(p1.x, p1.y);
		return game.world.getDist(p2.x, p2.y);
	}
	
}
