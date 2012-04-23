import Common;

class Hero extends Entity {
	
	var cx : Int;
	var cy : Int;
	
	public var attack : Int;
	public var defense : Int;
	public var gold : Int;
	public var life : Int;
	public var maxLife : Int;
	var flags : IntHash<Bool>;
	public var wait : Float;
	public var items : Array<Item>;
	
	public function new(x, y) {
		super(x, y, HeroSprite);
		items = [];
		flags = new IntHash();
		cx = cy = 0;
		wait = 0;
		maxLife = 100;
	}
	
	public function hasFlag(p) {
		return flags.exists(game.world.addr(p.x, p.y));
	}
	
	public function addItem(i) {
		items.push(i);
	}
	
	public function hasItem(i) {
		return Lambda.has(items, i);
	}
	
	public function setFlag(p) {
		flags.set(game.world.addr(p.x, p.y), true);
	}
	
	override function update() {
		super.update();
		wait--;
		var ix = Std.int(px), iy = Std.int(py);
		if( ix != cx || iy != cy ) {
			ix = cx;
			iy = cy;
			if( game.world.clearFog(x, y) )
				game.redrawFog();
		}
	}
	
}