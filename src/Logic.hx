import Common;

class City {

	public var x : Int;
	public var y : Int;
	public var mc : BMP;
	
	public function new(x, y) {
		this.x = x;
		this.y = y;
		mc = new flash.display.Bitmap(Main.inst.tiles.t[5][0]);
		mc.x = x * 5;
		mc.y = y * 5;
		Main.inst.root.addChild(mc);
	}
	
}