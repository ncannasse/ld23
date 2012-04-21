@:bitmap("gfx/tiles.png")
class TilesBmp extends flash.display.BitmapData {
}

class Tiles {

	public var t : Array<Array<flash.display.BitmapData>>;
	public var colorBG : UInt;
	
	public function new() {
		t = [];
		var tiles = new TilesBmp(0, 0);
		colorBG = tiles.getPixel32(127, 127);
		for( y in 0...25 ) {
			t[y] = [];
			for( x in 0...25 ) {
				var b = new flash.display.BitmapData(5, 5, true, 0);
				b.copyPixels(tiles, new flash.geom.Rectangle(x * 5, y * 5, 5, 5), new flash.geom.Point(0, 0));
				if( isEmpty(b) ) {
					b.dispose();
					break;
				}
				t[y].push(b);
			}
		}
		tiles.dispose();
	}
	
	public function getColor( c : World.Block ) {
		return t[Type.enumIndex(c)][0].getPixel32(0, 0);
	}
	
	function isEmpty( b : flash.display.BitmapData ) {
		for( x in 0...5 )
			for( y in 0...5 )
				if( b.getPixel32(x, y) != colorBG )
					return false;
		return true;
	}
	
}