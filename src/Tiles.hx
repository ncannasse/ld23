import Common;

@:bitmap("gfx/tiles.png")
class TilesBmp extends flash.display.BitmapData {
}

@:bitmap("gfx/sprites.png")
class SpritesBmp extends flash.display.BitmapData {
}

@:bitmap("gfx/icons.png")
class IconsBmp extends flash.display.BitmapData {
}

class Tiles {

	public var t : Array<Array<flash.display.BitmapData>>;
	public var s : Array<Array<flash.display.BitmapData>>;
	public var i : Array<Array<flash.display.BitmapData>>;
	
	public function new() {
		t = initTiles(new TilesBmp(0, 0), 5);
		s = initTiles(new SpritesBmp(0, 0), 7);
		i = initTiles(new IconsBmp(0, 0), 8);
	}
	
	function initTiles( tiles : flash.display.BitmapData, size : Int ) {
		var colorBG = tiles.getPixel32(tiles.width - 1, tiles.height - 1);
		var t = [];
		for( y in 0...Std.int(tiles.width/size) ) {
			t[y] = [];
			for( x in 0...Std.int(tiles.height/size) ) {
				var b = new flash.display.BitmapData(size, size, true, 0);
				b.copyPixels(tiles, new flash.geom.Rectangle(x * size, y * size, size, size), new flash.geom.Point(0, 0));
				if( isEmpty(b,colorBG) ) {
					b.dispose();
					break;
				}
				t[y].push(b);
			}
		}
		tiles.dispose();
		return t;
	}
	
	public function getColor( c : Block ) {
		return t[Type.enumIndex(c)][0].getPixel32(0, 0);
	}
	
	function isEmpty( b : flash.display.BitmapData, bg : UInt ) {
		var empty = true;
		for( x in 0...b.width )
			for( y in 0...b.height ) {
				var color = b.getPixel32(x, y);
				if( color != bg )
					empty = false;
				if( Std.int(color) == 0xFFFE00FE || Std.int(color) == 0xFFFF00FF )
					b.setPixel32(x, y, 0);
			}
		return empty;
	}
	
}