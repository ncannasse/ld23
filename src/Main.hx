import Common;
import Logic;

class Main implements haxe.Public {
	
	var root : SPR;
	var ui : SPR;
	var world : World;
	var tiles : Tiles;
	var cities : Array<City>;
	var rnd : Rand;
	
	function new(root) {
		this.root = root;
		root.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		root.scaleX = root.scaleY = 2;
		ui = new SPR();
		root.parent.addChild(ui);
		world = new World();
		tiles = new Tiles();
	}
	
	function init() {
		cities = [];
		rnd = new Rand(42);
		for( i in 0...20 ) {
			var x, y;
			do {
				x = rnd.random(World.SIZE);
				y = rnd.random(World.SIZE);
				switch( world.get(x,y) )
				{
					case Sea, Mountain:
						continue;
					case Forest:
						world.set(x, y, Field);
						break;
					default:
						break;
				}
			} while( true );
			cities.push(new City(x,y));
		}
		drawWorld();
	}

	
	function soilKind( k : Block ) {
		return switch(k) {
			case Sea: -1;
			case Sand: 1;
			default: 2;
		}
	}
	
	function drawWorld() {
		var w = new flash.display.BitmapData(World.SIZE * 5, World.SIZE * 5, true, 0);
		var rall = new flash.geom.Rectangle(0, 0, 5, 5);
		var p = new flash.geom.Point();
		var p0 = new flash.geom.Point();
		for( y in 0...World.SIZE )
			for( x in 0...World.SIZE ) {
				var t = world.get(x, y);
				var dx = 0, dy = 0;
				switch(t)
				{
					case Forest, Mountain:
						// draw soil
						var s = tiles.t[Type.enumIndex(Field)];
						p.x = x * 5;
						p.y = y * 5;
						w.copyPixels(s[Rand.hash(x + y * World.SIZE) % s.length], rall, p);
						// move tree around
						dx = rnd.random(3) - 1;
						dy = rnd.random(4) == 0 ? -1 : 0;
					default:
				}
				var t = tiles.t[Type.enumIndex(t)];
				p.x = x * 5 + dx;
				p.y = y * 5 + dy;
				var bmp = t[Rand.hash(x + y * World.SIZE) % t.length];
				w.copyPixels(bmp, rall, p, bmp, p0, true);
			}
		for( x in 1...World.SIZE-1 )
			for( y in 1...World.SIZE-1 ) {
				var t = world.t[x][y];
				var tleft = world.t[x - 1][y];
				var tright = world.t[x + 1][y];
				var tup = world.t[x][y-1];
				var tdown = world.t[x][y + 1];
				var k = soilKind(t);
				var left = soilKind(tleft);
				var right = soilKind(tright);
				var up = soilKind(tup);
				var down = soilKind(tdown);
				if( k == 20 ) {
					if( left != k && up != k )
						w.setPixel32(x * 5, y * 5, tiles.getColor(left > up ? tleft : tup));
					if( right != k && up != k )
						w.setPixel32(x * 5 + 4, y * 5, tiles.getColor(right > up ? tright : tup));
					if( left != k && down != k )
						w.setPixel32(x * 5, y * 5 + 4, tiles.getColor(left > down ? tleft : tdown));
					if( right != k && down != k )
						w.setPixel32(x * 5 + 4, y * 5 + 4, tiles.getColor(right > down ? tright : tdown));
				} else {
					if( left != k && up != k )
						w.setPixel32(x * 5, y * 5, tiles.getColor(left > k || up > k ? left > up ? tleft : tup : (left < 0 && up < 0 ? tleft : t)));
					if( right != k && up != k )
						w.setPixel32(x * 5 + 4, y * 5, tiles.getColor(right > k || up > k ? right > up ? tright : tup : (right < 0 && up < 0 ? tright : t)));
					if( left != k && down != k )
						w.setPixel32(x * 5, y * 5 + 4, tiles.getColor(left > k || down > k ? left > down ? tleft : tdown : (left < 0 && down < 0 ? tleft : t)));
					if( right != k && down != k )
						w.setPixel32(x * 5 + 4, y * 5 + 4, tiles.getColor(right > k || down > k ? right > down ? tright : tdown : (right < 0 && down < 0 ? tright : t)));
				}
			}
		root.addChildAt(new flash.display.Bitmap(w),0);
	}
	
	public static var inst : Main;
	
	static function main() {
		haxe.Log.setColor(0xFF0000);
		inst = new Main(flash.Lib.current);
		inst.init();
	}
}