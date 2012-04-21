import Common;
import Entity;

private typedef K = flash.ui.Keyboard;

class Game implements haxe.Public {
	
	static inline var PLAN_WORLD = 0;
	static inline var PLAN_NPC = 2;
	static inline var PLAN_MONSTER = 3;
	static inline var PLAN_FOG = 4;
	
	var root : SPR;
	var dm : DepthManager;
	var world : World;
	var tiles : Tiles;
	var cities : Array<City>;
	var rnd : Rand;
	var npcs : Array<Npc>;
	var monsters : Array<Monster>;
	var hero : Hero;
	var scroll : { x : Float, y : Float, ix : Int, iy : Int };
	var fog : flash.display.BitmapData;
	var fogMC : BMP;
	
	var sizeX : Int;
	var sizeY : Int;
	
	function new(root) {
		this.root = root;
		dm = new DepthManager(root);
		root.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		root.scaleX = root.scaleY = 2;
		world = new World(this);
		tiles = new Tiles();
		
		sizeX = Math.ceil(root.stage.stageWidth / (5 * root.scaleX)) + 1;
		sizeY = Math.ceil(root.stage.stageHeight / (5 * root.scaleX)) + 1;
		
		fog = new flash.display.BitmapData(sizeX * 5, sizeY * 5, true, 0);
		fogMC = new BMP(fog);
		dm.add(fogMC, PLAN_FOG);
	}
	
	function freeSpace() {
		var x, y;
		while( true ) {
			x = rnd.random(World.SIZE);
			y = rnd.random(World.SIZE);
			switch( world.get(x,y) )
			{
				case DarkSea, Sea, Mountain:
					continue;
				default:
					var found = false;
					for( c in cities )
						if( c.x == x && c.y == y ) {
							found = true;
							break;
						}
					for( n in npcs )
						if( n.x == x && n.y == y ) {
							found = true;
							break;
						}
					for( m in monsters )
						if( m.x == x && m.y == y ) {
							found = true;
							break;
						}
					if( x == hero.x && y == hero.y )
						found = true;
					if( !found )
						return { x : x, y : y };
			}
		}
		return null;
	}
	
	function fight( m : Monster ) {
		m.remove();
		monsters.remove(m);
	}
	
	function init() {
		cities = [];
		npcs = [];
		monsters = [];
		rnd = new Rand(42);
		
		hero = new Hero(30, 97);
		
		for( x in 0...World.SIZE )
			for( y in 0...World.SIZE )
				switch( world.get(x,y) ) {
				case CityPos:
					var c = new City(this, x, y);
					cities.push(c);
				default:
				}

		var all = Type.allEnums(NpcKind);
		for( m in world.monsters ) {
			var m = new Monster(m.x, m.y, all[m.i + Type.enumIndex(Blob)]);
			monsters.push(m);
		}
		
		for( i in 0...30 ) {
			var p = freeSpace();
			var n = addNPC(p.x, p.y, all[rnd.random(all.length)]);
			n.mspeed *= Math.random() + 0.5;
		}

		var n = addNPC(38, 93, Soldier);
		n.locked = true;
		n.onHit = function() {
			return false;
		}
				
		world.initPath(hero.x, hero.y);
		drawWorld();
		update();
		root.addEventListener(flash.events.Event.ENTER_FRAME, function(_) update());
	}
	
	function addNPC(x, y, k) {
		var n = new Npc(x, y, k);
		npcs.push(n);
		return n;
	}
	
	function collide( x : Int, y : Int ) {
		switch( world.get(x,y) )  {
		case Sea, DarkSea, Mountain:
			return true;
		default:
		}
		for( n in npcs )
			if( n.x == x && n.y == y )
				return true;
		if( x == hero.x && y == hero.y )
			return true;
		return false;
	}
	
	function redrawFog() {
		fog.fillRect(fog.rect, 0);
		var r = new flash.geom.Rectangle(0, 0, 5, 5);
		for( x in 0...sizeX )
			for( y in 0...sizeY ) {
				var rx = x + scroll.ix;
				var ry = y + scroll.iy;
				var f = rx < 0 || ry < 0 || rx >= World.SIZE || ry >= World.SIZE ? 1 : world.fog[rx][ry];
				if( f == 0 ) continue;
				r.x = x * 5;
				r.y = y * 5;
				fog.fillRect(r, Std.int(f * 255) << 24);
			}
		fogMC.x = scroll.ix * 5;
		fogMC.y = scroll.iy * 5;
	}
	
	function update() {
		var scale = 5 * root.scaleX;
		var tx = hero.px * scale - (root.stage.stageWidth >> 1);
		var ty = hero.py * scale - (root.stage.stageHeight >> 1);
		
		if( scroll == null )
			scroll = { x : tx, y : ty, ix : -1, iy : -1 };
		else {
			scroll.x = scroll.x * 0.8 + 0.2 * tx;
			scroll.y = scroll.y * 0.8 + 0.2 * ty;
		}
		root.x = -scroll.x;
		root.y = -scroll.y;
		
		var ix = Std.int(scroll.x / scale);
		var iy = Std.int(scroll.y / scale);
		if( ix != scroll.ix || iy != scroll.iy ) {
			scroll.ix = ix;
			scroll.iy = iy;
			redrawFog();
		}
		
		if( hero.canMove() ) {
			if( (Key.isDown(K.LEFT) || Key.isDown("A".code) || Key.isDown("Q".code)) && !collide(hero.x-1,hero.y) )
				hero.x--;
			else if( (Key.isDown(K.RIGHT) || Key.isDown("D".code)) && !collide(hero.x + 1, hero.y) )
				hero.x++;
			else if( (Key.isDown(K.UP) || Key.isDown("Z".code) || Key.isDown("W".code)) && !collide(hero.x,hero.y - 1) )
				hero.y--;
			else if( (Key.isDown(K.DOWN) || Key.isDown("S".code)) && !collide(hero.x, hero.y + 1) )
				hero.y++;
			else
				hero.frame = 0;
		}
		hero.update();
		
		for( n in npcs )
			n.update();
		for( m in monsters )
			m.update();
			
		dm.ysort(PLAN_NPC);
	}
	
	function drawWorld() {
		var w = new flash.display.BitmapData(World.SIZE * 5, World.SIZE * 5, true, 0);
		world.draw(w);
		dm.add(new flash.display.Bitmap(w),PLAN_WORLD);
	}
	
	public static var inst : Game;
	
	static function main() {
		haxe.Log.setColor(0xFF0000);
		inst = new Game(flash.Lib.current);
		inst.init();
		Key.init();
		Key.enableJSKeys("game");
	}
}