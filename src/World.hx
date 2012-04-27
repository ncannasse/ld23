import Common;

@:bitmap("gfx/world.png")
class WorldBmp extends flash.display.BitmapData {
}

class World {
	
	public static inline var SIZE = 128;
	
	public var t : Array<Array<Block>>;
	public var fog : Array<Array<Float>>;
	
	var game : Game;
	var path : flash.Vector<Int>;
	var tmp : flash.Vector<Int>;
	var tmpPos : Int;
	public var monsters : Array<{ x : Int, y : Int, i : Int }>;
	public var treasures : Array<{ x : Int, y : Int, i : Int, e : Entity }>;
	
	public function new(g) {
		game = g;
		path = new flash.Vector(SIZE * SIZE);
		tmp = new flash.Vector();
		t = [];
		fog = [];
		monsters = [];
		treasures = [];
		var bmp = new WorldBmp(0, 0);
		for( x in 0...SIZE ) {
			t[x] = [];
			fog[x] = [];
			for( y in 0...SIZE ) {
				fog[x][y] = Game.DEBUG ? 0 : 1;
				var v = bmp.getPixel(x, y);
				#if !haxe_210
				// FIX : this will fix invalid 24-bit PNG decoding by flash
				var r = v >> 16;
				var g = (v >> 8) & 0xFF;
				var b = v & 0xFF;
				if( r != 0 ) r++;
				if( g != 0 ) g++;
				if( b != 0 ) b++;
				v = (r << 16) | (g << 8) | b;
				if( v == 0xC7 ) v = 0x01C7;
				if( v == 0x6F2A00 ) v++;
				#end
				t[x][y] = switch( v ) {
				case 0x000080: Sea;
				case 0x00FF00: Field;
				case 0x808080: Mountain;
				case 0x008000: Forest;
				case 0x004C00: SwampMountain;
				case 0xFFFF00: Sand;
				case 0xFFFFFF: CityPos;
				case 0x000000: Cave;
				case 0x83D284: Swamp;
				case 0xB2B2B2: SnowMountain;
				case 0xBEFF00: DarkField;
				case 0x616161: DarkMountain;
				case 0x428A00: DarkForest;
				case 0x5EECB6: FloodField;
				case 0x15B277: FloodForest;
				case 0x454280: FloodMountain;
				case 0x0001C7: FakeWater;
				case 0x9D3B02: Magma;
				case 0xFD8F4D:
					treasures.push( { x:x, y:y, i : 0, e : null } );
					bestSoil(x, y);
				case 0xE35502:
					treasures.push( { x:x, y:y, i : 1, e : null } );
					bestSoil(x, y);
				case 0xBB4602:
					treasures.push( { x:x, y:y, i : 2, e : null } );
					bestSoil(x, y);
				case 0xC04802:
					treasures.push( { x:x, y:y, i : 3, e : null } );
					bestSoil(x, y);
				case 0x005FFF:
					treasures.push( { x:x, y:y, i : 4, e : null } );
					bestSoil(x, y);
				case 0xED5902:
					treasures.push( { x:x, y:y, i : 5, e : null } );
					bestSoil(x, y);
				case 0x6F2A01:
					treasures.push( { x:x, y:y, i : 6, e : null } );
					bestSoil(x, y);
				default:
					if( v & 0xFFFF == 0 ) {
						monsters.push( { x : x, y : y, i : 0xFF - (v >> 16) } );
						bestSoil(x, y);
					} else {
						trace("");
						trace("Unknown " + StringTools.hex(bmp.getPixel(x, y))+" @"+x+","+y);
						Sea;
					}
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
								switch(t[x+dx][y+dy]) {
								case Sea,DarkSea:
								default:
									found = true;
								}
					if( !found )
						set(x, y, DarkSea);
				}
		bmp.dispose();
	}

	function bestSoil(x, y) {
		var s = get(x, y - 1);
		return switch( s ) {
		case Field, Sand: s;
		case DarkField, DarkForest, DarkMountain: DarkField;
		case FloodForest, FloodMountain, FloodField: FloodField;
		case Swamp, SwampMountain: Swamp;
		case Magma: Magma;
		default: Field;
		}
	}
	
	public function clearFog( x, y ) {
		var changed = false;
		for( dx in -5...6 )
			for( dy in -5...5 ) {
				var x = x + dx, y = y + dy;
				if( x < 0 || y < 0 || x >= SIZE || y >= SIZE || fog[x][y] == 0 ) continue;
				var r = Math.sqrt(dx * dx + dy * dy);
				if( r > 5 )
					continue;
				var k = 1  - 3 / (r + 1);
				if( k < 0 ) k = 0;
				if( fog[x][y] > k ) {
					fog[x][y] = k;
					changed = true;
				}
			}
		return changed;
	}
	
	public inline function addr(x, y) {
		return x | (y << 7);
	}
	
	public function collide(t) {
		return switch( t ) {
			case Sea, DarkSea, Mountain, DarkMountain, Cave, SnowMountain, FloodMountain, SwampMountain, FakeWater: true;
			default: false;
		}
	}
	
	@:nodebug
	public function initPath( x, y ) {
		// init Path
		for( i in 0...SIZE * SIZE )
			path[i] = SIZE * SIZE;
		for( x in 0...SIZE )
			for( y in 0...SIZE ) {
				var t = t[x][y];
				if( collide(t) || t == FakeWater )
					path[addr(x, y)] = -1;
			}
		for( n in game.npcs )
			path[addr(n.x, n.y)] = -1;
		for( m in game.monsters )
			path[addr(m.x, m.y)] = -1;
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
			case SwampMountain, Swamp: 2;
			case DarkForest, DarkField, DarkMountain: 3;
			case Magma: 4;
			case FloodField, FloodForest, FloodMountain: 5;
			default: 6;
		}
	}
	
	public inline function getTileAt(t:Block, x, y) {
		var t = game.tiles.t[Type.enumIndex(t)];
		return t[Rand.hash(x + y * World.SIZE) % t.length];
	}
	
	public function draw( w : flash.display.BitmapData ) {
		var rall = new flash.geom.Rectangle(0, 0, 5, 5);
		var p = new flash.geom.Point();
		var p0 = new flash.geom.Point();
		var rnd = new Rand(42);
		for( y in 0...World.SIZE )
			for( x in 0...World.SIZE ) {
				var t = get(x, y);
				p.x = x * 5;
				p.y = y * 5;
				switch(t)
				{
					case Forest, Mountain, SnowMountain:
						// draw soil under
						w.copyPixels(getTileAt(Field,x,y), rall, p);
						// move it around
						p.x += rnd.random(3) - 1;
						p.y += rnd.random(4) == 0 ? -1 : 0;
					case SwampMountain:
						w.copyPixels(getTileAt(Swamp,x,y), rall, p);
						// move it around
						p.x += rnd.random(3) - 1;
						p.y += rnd.random(4) == 0 ? -1 : 0;
					case DarkMountain, DarkForest:
						w.copyPixels(getTileAt(DarkField,x,y), rall, p);
						// move it around
						p.x += rnd.random(3) - 1;
						p.y += rnd.random(4) == 0 ? -1 : 0;
					case FloodForest, FloodMountain:
						w.copyPixels(getTileAt(FloodField,x,y), rall, p);
						// move it around
						p.x += rnd.random(3) - 1;
						p.y += rnd.random(4) == 0 ? -1 : 0;
					case CityPos, Cave:
						w.copyPixels(getTileAt(bestSoil(x,y),x,y), rall, p);
					default:
				}
				var bmp = getTileAt(t,x,y);
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