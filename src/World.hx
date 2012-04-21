import Common;

@:bitmap("gfx/world.png")
class WorldBmp extends flash.display.BitmapData {
}

class World {
	
	public static inline var SIZE = 128;
	
	public var t : Array<Array<Block>>;
	
	public function new() {
		t = [];
		var bmp = new WorldBmp(0, 0);
		for( x in 0...SIZE ) {
			t[x] = [];
			for( y in 0...SIZE ) {
				t[x][y] = switch( bmp.getPixel(x,y) ) {
				case 0x0000FE: Sea;
				case 0x00FE00: Field;
				case 0x7F7F7F: Mountain;
				case 0x007F00: Forest;
				case 0xFEFE00: Sand;
				default: trace("Unknown " + StringTools.hex(bmp.getPixel(x, y))); Sea;
				}
			}
		}
		bmp.dispose();
	}
	
	public inline function get(x, y) {
		return t[x][y];
	}

	public function set(x, y, k) {
		t[x][y] = k;
	}
	
}