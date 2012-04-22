import Common;
import Entity;

private typedef K = flash.ui.Keyboard;

typedef Icon = {
	var tf : TF;
	var ico : BMP;
}

class Game implements haxe.Public {
	
	static inline var PLAN_WORLD = 0;
	static inline var PLAN_NPC = 2;
	static inline var PLAN_MONSTER = 3;
	static inline var PLAN_FOG = 4;
	
	static var WIDTH = 640;
	static var HEIGHT = 480;
	
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
	var messageMC : SPR;
	var messageText : TF;
	var messageAsk : { text : String, cur : Bool, callb : Bool -> Void };
	var curCity : City;
	
	var discover : Int;
	var monstersKilled : Int;
	
	var helpText : TF;
	
	var ui : {
		life : Icon,
		discover : TF,
		monsters : TF,
		att : Icon,
		def : Icon,
		gold : Icon,
	};
	
	var sizeX : Int;
	var sizeY : Int;
	
	function new(root) {
		this.root = root;
		dm = new DepthManager(root);
		root.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		root.scaleX = root.scaleY = 2;
		world = new World(this);
		tiles = new Tiles();
		
		sizeX = Math.ceil(WIDTH / (5 * root.scaleX)) + 1;
		sizeY = Math.ceil(HEIGHT / (5 * root.scaleX)) + 1;
		
		initMessage();
		initUI();
		message("Move with arrows/WASD !\nBeware of monsters !\n(Click me or space to start)");
		
		helpText = newText();
		helpText.x = 5;
		helpText.width = 800;
		helpText.y = 20;
		helpText.visible = false;
		
		root.parent.addChild(helpText);
		
		fog = new flash.display.BitmapData(sizeX * 5, sizeY * 5, true, 0);
		fogMC = new BMP(fog);
		//dm.add(fogMC, PLAN_FOG);
	}
	
	function message( str ) {
		messageAsk = null;
		messageMC.visible = true;
		messageText.text = str;
		messageText.y = Std.int(((150 - 6) -  messageText.textHeight) * 0.5);
	}
	
	function initMessage() {
		var mc = messageMC = new SPR();
		var tf = messageText = newText();
		var w = 400, h = 150;
		
		mc.addChild(tf);
		mc.graphics.lineStyle(2, 0);
		mc.graphics.drawRect(0, 0, w, h);
		mc.graphics.beginFill(0x000020, 0.9);
		mc.graphics.lineStyle(2, 0xFFFFFF);
		mc.graphics.drawRect(2, 2, w - 4, h - 4);
				
		tf.x = tf.y = 6;
		tf.width = w - 12;
		tf.height = h - 12;
		var fmt = tf.defaultTextFormat;
		fmt.align = flash.text.TextFormatAlign.CENTER;
		fmt.size = 18;
		tf.defaultTextFormat = fmt;
		
		mc.visible = false;
		mc.addEventListener(flash.events.MouseEvent.CLICK, function(_) hideMessage());
		mc.useHandCursor = true;
		mc.buttonMode = true;
		
		mc.x = (WIDTH - w) >> 1;
		mc.y = (HEIGHT - h) >> 1;
		root.parent.addChild(mc);
	}
	
	function initUI() {
		var uis = new SPR();
		
		uis.graphics.beginFill(0,0.7);
		uis.graphics.drawRect(0, 0, WIDTH, 20);
		root.parent.addChild(uis);
		
		var att = new BMP(tiles.i[0][0]);
		
		function addIcon(x, i, txt) {
			var i = {
				tf : newText(true),
				ico : new BMP(tiles.i[0][i]),
			};
			var spr = new SPR();
			spr.x = x;
			uis.addChild(spr);
			
			spr.addEventListener(flash.events.MouseEvent.MOUSE_OVER, function(_) help(txt));
			spr.addEventListener(flash.events.MouseEvent.MOUSE_OUT, function(_) help());
			
			spr.addChild(i.tf);
			spr.addChild(i.ico);
			i.tf.width = 70;
			i.tf.text = "999";
			i.ico.y = 2;
			i.ico.scaleX = i.ico.scaleY = 2;
			i.tf.x = 18;
			return i;
		}
		
		this.ui = {
			att : addIcon(5, 0,"Attack Power"),
			def : addIcon(45, 1,"Defense Power"),
			life : addIcon(85, 4,"Life points"),
			gold : addIcon(150, 3,"Gold Coins"),
			discover : newText(),
			monsters : newText(),
		};
		
	}
	
	function help( ?str ) {
		if( str == null )
			helpText.visible = false;
		else {
			helpText.text = str;
			helpText.visible = true;
		}
	}
	
	function hideMessage() {
		messageMC.visible = false;
		var ma = messageAsk;
		if( ma != null ) {
			messageAsk = null;
			ma.callb(ma.cur);
		}
	}
	
	function newText(?auto) {
		var tf = new TF();
		tf.selectable = false;
		if( auto ) {
			tf.width = 0;
			tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		}
		tf.height = 20;
		tf.mouseEnabled = false;
		tf.textColor = 0xFFFFFF;
		tf.filters = [new flash.filters.GlowFilter(0, 0.8, 2, 2, 10, 2)];
		return tf;
	}
	
	function ask( msg, callb ) {
		messageAsk = { text : msg, cur : true, callb : callb };
		updateAsk();
	}
	
	function askBuy( pos, msg, amount,callb ) {
		if( hero.bought.exists(pos) )
			message("You already bought item here");
		else
			ask(msg,function(b) {
				if( b ) buy(amount, function() {
					callb();
					hero.bought.set(pos,true);
				});
			});
	}
	
	function updateAsk() {
		var ma = messageAsk;
		message(ma.text + "\n\n" + (ma.cur?"[Yes]\t\t\t No ":" Yes \t\t\t[No]"));
		messageAsk = ma;
	}
	
	function buy(amount,callb) {
		if( hero.gold < amount )
			message("You don't have enough gold !");
		else
			callb();
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
			message("It's dangerous to go up there,\nyou will need a better weapon !");
			return true;
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
	
	function collide( x : Int, y : Int, isHero = false ) {
		switch( world.get(x,y) )  {
		case Sea, DarkSea, Mountain:
			return true;
		default:
		}
		for( n in npcs )
			if( n.x == x && n.y == y )
				return !isHero || n.onHit();
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
		var tx = hero.px * scale - (WIDTH >> 1);
		var ty = hero.py * scale - (HEIGHT >> 1);
		
		ui.att.tf.text = Std.string(hero.attack);
		ui.def.tf.text = Std.string(hero.defense);
		ui.gold.tf.text = Std.string(hero.gold);
		ui.life.tf.text = hero.life+"/"+hero.maxLife;
		
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
			if( messageMC.visible ) {
				// prevent move
				hero.frame = 0;
				var move = false;
				for( k in [K.LEFT, K.RIGHT, K.UP, K.DOWN, "A".code, "Q".code, "D".code, "Z".code, "W".code, "S".code] )
					if( Key.isToggled(k) ) {
						move = true;
						break;
					}
				var action = false;
				for( k in [K.SPACE, K.ENTER, "E".code] )
					if( Key.isToggled(k) ) {
						action = true;
						break;
					}
				
				if( messageAsk != null ) {
					if( move ) {
						messageAsk.cur = !messageAsk.cur;
						updateAsk();
					} else if( action )
						hideMessage();
				} else if( action || move )
					hideMessage();
			} else if( (Key.isDown(K.LEFT) || Key.isDown("A".code) || Key.isDown("Q".code)) && !collide(hero.x-1,hero.y,true) )
				hero.x--;
			else if( (Key.isDown(K.RIGHT) || Key.isDown("D".code)) && !collide(hero.x + 1, hero.y,true) )
				hero.x++;
			else if( (Key.isDown(K.UP) || Key.isDown("Z".code) || Key.isDown("W".code)) && !collide(hero.x,hero.y - 1,true) )
				hero.y--;
			else if( (Key.isDown(K.DOWN) || Key.isDown("S".code)) && !collide(hero.x, hero.y + 1,true) )
				hero.y++;
			else {
				var found = false;
				for( c in cities )
					if( c.x == hero.x && c.y == hero.y ) {
						found = true;
						if( curCity == c ) break;
						curCity = c;
						var pos = world.addr(c.x, c.y);
						switch( pos ) {
						case 12193:
							askBuy(pos, "Buy a dagger (+5 Att) for 10 gold ?", 10, function() { hero.attack += 5; message("You attack has raised to " + hero.attack); } );
						default:
							trace("Unknown city @" + world.addr(c.x, c.y));
						}
					}
				if( !found )
					curCity = null;
				hero.frame = 0;
			}
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