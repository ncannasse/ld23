import Common;

@:bitmap("gfx/world.png")
class WorldBmp extends flash.display.BitmapData {
}

class World {
	
	public static inline var SIZE = 128;
	
	public var t : Array<Array<Block>>;
	
	var game : Game;
	var path : flash.Vector<Int>;
	var tmp : flash.Vector<Int>;
	var tmpPos : Int;
	
	public function new(g) {
		game = g;
		path = new flash.Vector(SIZE * SIZE);
		tmp = new flash.Vector();
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
	
	inline function addr(x, y) {
		return x | (y << 7);
	}
	
	@:nodebug
	public function initPath( x, y ) {
		// init Path
		for( i in 0...SIZE * SIZE )
			path[i] = SIZE * SIZE;
		for( x in 0...SIZE )
			for( y in 0...SIZE )
				switch( t[x][y] ) {
				case Sea, DarkSea, Mountain:
					path[addr(x, y)] = -1;
				default:
				}
		for( n in game.npcs )
			path[addr(n.x, n.y)] = -1;
		// free out pos
		path[addr(x, y)] = 0;
		// start recursion
		var wpos = 0;
		tmp[wpos++] = addr(x, y);
		var rpos = 0;
		while( rpos < wpos ) {
			var a = tmp[rpos++];
			var x = a & 127;
			var y = a >> 7;
			var d = path[a] + 1;
			if( path[a - 1] > d ) {
				path[a - 1] = d;
				tmp[wpos++] = a - 1;
			}
			if( path[a + 1] > d ) {
				path[a + 1] = d;
				tmp[wpos++] = a + 1;
			}
			if( path[a + SIZE] > d ) {
				path[a + SIZE] = d;
				tmp[wpos++] = a + SIZE;
			}
			if( path[a - SIZE] > d ) {
				path[a - SIZE] = d;
				tmp[wpos++] = a - SIZE;
			}
		}
	}
	
	public function getDist(x,y) {
		return path[addr(x, y)];
	}
	
	@:nodebug
	public function getPath(x, y) {
		var p = [];
		var a = addr(x, y);
		while( true ) {
			var d = path[a];
			if( d <= 0 )
				break;
			p.push( { x : x, y : y } );
			if( path[a + 1] < d && path[a+1] >= 0 ) {
				a++;
				x++;
			} else if( path[a - 1] < d && path[a-1] >= 0 ) {
				a--;
				x--;
			} else if( path[a - SIZE] < d && path[a-SIZE] >= 0 ) {
				a -= SIZE;
				y--;
			} else if( path[a + SIZE] < d && path[a+SIZE] >= 0 ) {
				a += SIZE;
				y++;
			} else
				return []; // loose-end
		}
		return p;
	}
	
	public inline function get(x, y) {
		return t[x][y];
	}

	public function set(x, y, k) {
		t[x][y] = k;
	}
	
	function soilKind( k : Block ) {
		return switch(k) {
			case Sea: -1;
			case Sand: 1;
			default: 2;
		}
	}
	
	public function draw( w : flash.display.BitmapData ) {
		var rall = new flash.geom.Rectangle(0, 0, 5, 5);
		var p = new flash.geom.Point();
		var p0 = new flash.geom.Point();
		var rnd = new Rand(42);
		for( y in 0...World.SIZE )
			for( x in 0...World.SIZE ) {
				var t = get(x, y);
				var dx = 0, dy = 0;
				switch(t)
				{
					case Forest, Mountain:
						// draw soil
						var s = game.tiles.t[Type.enumIndex(Field)];
						p.x = x * 5;
						p.y = y * 5;
						w.copyPixels(s[Rand.hash(x + y * World.SIZE) % s.length], rall, p);
						// move tree around
						dx = rnd.random(3) - 1;
						dy = rnd.random(4) == 0 ? -1 : 0;
					default:
				}
				var t = game.tiles.t[Type.enumIndex(t)];
				p.x = x * 5 + dx;
				p.y = y * 5 + dy;
				var bmp = t[Rand.hash(x + y * World.SIZE) % t.length];
				w.copyPixels(bmp, rall, p, bmp, p0, true);
			}
		function set(x, y, t) { var c = game.tiles.getColor(t); if( c > 0 ) w.setPixel32(x, y, c); }
		for( x in 1...World.SIZE-1 )
			for( y in 1...World.SIZE-1 ) {
				var t = get(x,y);
				var tleft = get(x - 1,y);
				var tright = get(x + 1,y);
				var tup = get(x,y-1);
				var tdown = get(x,y+1);
				var k = soilKind(t);
				var left = soilKind(tleft);
				var right = soilKind(tright);
				var up = soilKind(tup);
				var down = soilKind(tdown);
				if( k == 20 ) {
					if( left != k && up != k )
						set(x * 5, y * 5, (left > up ? tleft : tup));
					if( right != k && up != k )
						set(x * 5 + 4, y * 5, (right > up ? tright : tup));
					if( left != k && down != k )
						set(x * 5, y * 5 + 4, (left > down ? tleft : tdown));
					if( right != k && down != k )
						set(x * 5 + 4, y * 5 + 4, (right > down ? tright : tdown));
				} else {
					if( left != k && up != k )
						set(x * 5, y * 5, (left > k || up > k ? left > up ? tleft : tup : (left < 0 && up < 0 ? tleft : t)));
					if( right != k && up != k )
						set(x * 5 + 4, y * 5, (right > k || up > k ? right > up ? tright : tup : (right < 0 && up < 0 ? tright : t)));
					if( left != k && down != k )
						set(x * 5, y * 5 + 4, (left > k || down > k ? left > down ? tleft : tdown : (left < 0 && down < 0 ? tleft : t)));
					if( right != k && down != k )
						set(x * 5 + 4, y * 5 + 4, (right > k || down > k ? right > down ? tright : tdown : (right < 0 && down < 0 ? tright : t)));
				}
			}
	}
	
}