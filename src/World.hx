import Common;
import Logic;

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
		for( x in 0...SIZE )
			for( y in 0...SIZE )
				if( get(x, y) == Sea ) {
					var found = false;
					for( dx in -2...3 )
						for( dy in -2...3 )
							if( x + dx >= 0 && y + dy >= 0 && x + dx < SIZE && y + dy < SIZE )
								switch(t[x+dx][y+dy])
								{
									case Sea,DarkSea:
									default:
										found = true;
								}
					if( !found )
						set(x, y, DarkSea);
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