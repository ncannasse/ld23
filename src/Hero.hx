class Hero extends Entity {
	
	var cx : Int;
	var cy : Int;
	
	public function new(g, x, y, k) {
		super(g, x, y, k);
		cx = cy = 0;
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