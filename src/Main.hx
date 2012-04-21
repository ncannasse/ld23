import World;

typedef SPR = flash.display.Sprite;

class Main {
	
	var root : SPR;
	var world : World;
	var tiles : Tiles;
	
	function new(root) {
		this.root = root;
		root.y = 20;
		world = new World();
		tiles = new Tiles();
		drawWorld();
	}

	function hash(n) {
		for( i in 0...5 ) {
			n ^= (n << 7) & 0x2b5b2500;
			n ^= (n << 15) & 0x1b8b0000;
			n ^= n >>> 16;
			n &= 0x3FFFFFFF;
			var h = 5381;
			h = (h << 5) + h + (n & 0xFF);
			h = (h << 5) + h + ((n >> 8) & 0xFF);
			h = (h << 5) + h + ((n >> 16) & 0xFF);
			h = (h << 5) + h + (n >> 24);
			n = h & 0x3FFFFFFF;
		}
		return n;
	}
	
	function drawWorld() {
		var w = new flash.display.BitmapData(World.SIZE * 5, World.SIZE * 5, true, 0);
		var rall = new flash.geom.Rectangle(0, 0, 5, 5);
		var p = new flash.geom.Point();
		for( x in 0...World.SIZE )
			for( y in 0...World.SIZE ) {
				var t = tiles.t[Type.enumIndex(world.t[x][y])];
				p.x = x * 5;
				p.y = y * 5;
				w.copyPixels(t[hash(x + y * World.SIZE) % t.length], rall, p);
			}
		root.addChild(new flash.display.Bitmap(w));
	}
	
	public static var inst : Main;
	
	static function main() {
		haxe.Log.setColor(0xFF0000);
		inst = new Main(flash.Lib.current);
	}
}