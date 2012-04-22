class Hero extends Entity {
	
	var cx : Int;
	var cy : Int;
	
	public var attack : Int;
	public var defense : Int;
	public var gold : Int;
	public var life : Int;
	public var maxLife : Int;
	public var bought : IntHash<Bool>;
	
	public function new(x, y) {
		super(x, y, Walker);
		bought = new IntHash();
		cx = cy = 0;
		attack = 10;
		defense = 5;
		gold = 10;
		life = maxLife = 10;
	}
	
	override function update() {
		super.update();
		var ix = Std.int(px), iy = Std.int(py);
		if( ix != cx || iy != cy ) {
			ix = cx;
			iy = cy;
			if( game.world.clearFog(x, y) )
				game.redrawFog();
		}
	}
	
}