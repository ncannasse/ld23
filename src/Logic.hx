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

