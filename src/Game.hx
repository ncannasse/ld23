import Common;
import Entity;

private typedef K = flash.ui.Keyboard;

class Game implements haxe.Public {
	
	static inline var PLAN_WORLD = 0;
	static inline var PLAN_CITY = 1;
	static inline var PLAN_NPC = 2;
	
	var root : SPR;
	var dm : DepthManager;
	var world : World;
	var tiles : Tiles;
	var cities : Array<City>;
	var rnd : Rand;
	var npcs : Array<Npc>;
	var hero : Hero;
	var scroll : { x : Float, y : Float };
	
	function new(root) {
		this.root = root;
		dm = new DepthManager(root);
		root.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		root.scaleX = root.scaleY = 4;
		world = new World(this);
		tiles = new Tiles();
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
					if( !found )
						return { x : x, y : y };
			}
		}
		return null;
	}
	
	
	function init() {
		cities = [];
		npcs = [];
		rnd = new Rand(42);
		for( i in 0...20 ) {
			var p = freeSpace();
			if( world.get(p.x, p.y) == Forest )
				world.set(p.x, p.y, Field);
			var c = new City(this, p.x, p.y);
			cities.push(c);
		}
		for( i in 0...30 ) {
			var p = freeSpace();
			var all = Type.allEnums(NpcKind);
			var n = new Npc(this, p.x, p.y, all[rnd.random(all.length)]);
			n.mspeed *= Math.random() + 0.5;
			npcs.push(n);
		}
		for( n in npcs )
			n.chooseTarget();
		hero = new Hero(this, 25, 97, Walker);
		world.initPath(hero.x, hero.y);
		drawWorld();
		update();
		root.addEventListener(flash.events.Event.ENTER_FRAME, function(_) update());
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
	
	function update() {
		var tx = hero.px * 5 * root.scaleX - (root.stage.stageWidth >> 1);
		var ty = hero.py * 5 * root.scaleY - (root.stage.stageWidth >> 1);
		if( tx < 0 ) tx = 0;
		if( ty < 0 ) ty = 0;
		var xmax = World.SIZE * 5 * root.scaleX - root.stage.stageWidth;
		var ymax = World.SIZE * 5 * root.scaleY - root.stage.stageHeight;
		if( tx > xmax ) tx = xmax;
		if( ty > ymax ) ty = ymax;
		
		if( scroll == null )
			scroll = { x : tx, y : ty };
		else {
			scroll.x = scroll.x * 0.8 + 0.2 * tx;
			scroll.y = scroll.y * 0.8 + 0.2 * ty;
		}
		root.x = -scroll.x;
		root.y = -scroll.y;
		
		if( hero.canMove() ) {
			if( Key.isDown(K.LEFT) && !collide(hero.tx-1,hero.ty) )
				hero.tx--;
			else if( Key.isDown(K.RIGHT) && !collide(hero.tx + 1, hero.ty) )
				hero.tx++;
			else if( Key.isDown(K.UP) && !collide(hero.tx,hero.ty - 1) )
				hero.ty--;
			else if( Key.isDown(K.DOWN) && !collide(hero.tx, hero.ty + 1) )
				hero.ty++;
			else
				hero.frame = 0;
		}
		hero.update();
		
		for( n in npcs )
			n.update();
			
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