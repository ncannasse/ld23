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
		mc = new flash.display.Bitmap(game.tiles.t[5][0]);
		mc.x = x * 5;
		mc.y = y * 5;
		game.root.addChild(mc);
	}
	
}

class Monster {
	
	public var game : Game;
	public var x : Int;
	public var y : Int;
	public var kind : MonsterKind;
	public var mc : BMP;
	
	public var frame : Float;
	var curFrame : Int;
	var px : Float;
	var py : Float;
	
	public function new(g, x, y, k) {
		game = g;
		kind = k;
		this.x = x;
		this.y = y;
		px = x;
		py = y;
		this.mc = new BMP();
		game.root.addChild(mc);
		frame = Math.random() * 10;
		curFrame = -1;
	}
	
	public function update() {
		frame += 0.2 + Math.random() * 0.02;
		this.mc.x = Std.int(px * 5) - 1;
		this.mc.y = Std.int(py * 5) - 2;
		var t = game.tiles.s[Type.enumIndex(kind)];
		var iframe = Std.int(frame) % t.length;
		if( iframe != curFrame ) {
			curFrame = iframe;
			mc.bitmapData = t[iframe];
		}
	}
	
}
