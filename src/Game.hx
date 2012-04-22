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
	static inline var PLAN_FX = 5;
	
	static var WIDTH = 640;
	static var HEIGHT = 480;
	
	static var SINDEX = 1;
	static var START = [
		{ x : 30, y : 97, att : 10, def : 5, gold : 0, life : 100 },
		{ x : 47, y : 88, att : 15, def : 15, gold : 5, life : 35 },
	];
	
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
	var sprites : Array<Sprite>;
	var worldBmp : flash.display.BitmapData;
	var lifes : Array<{ l : BMP, t : Float }>;
	
	var discover : Int;
	var monstersKilled : Int;
	
	var helpText : TF;
	
	var uiContent : SPR;
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
		uiContent = new SPR();
		root.parent.addChild(uiContent);
			
		dm = new DepthManager(root);
		root.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		root.scaleX = root.scaleY = 2;
		world = new World(this);
		tiles = new Tiles();
		
		lifes  = [];
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
		
		uiContent.addChild(helpText);
		
		fog = new flash.display.BitmapData(sizeX * 5, sizeY * 5, true, 0);
		fogMC = new BMP(fog);
		dm.add(fogMC, PLAN_FOG);
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
		uiContent.addChild(mc);
	}
	
	function initUI() {
		var uis = new SPR();
		
		uis.graphics.beginFill(0,0.7);
		uis.graphics.drawRect(0, 0, WIDTH, 20);
		uiContent.addChild(uis);
		
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
		if( hero.life <= 0 )
			gameOver();
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
	
	function askBuy( p, msg, amount:Int,callb ) {
		if( hero.hasFlag(p) )
			message("You already bought an item here");
		else
			ask(msg.split("$G").join(""+amount),function(b) {
				if( b ) buy(amount, function() {
					callb();
					hero.setFlag(p);
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
			message("You don't have enough gold !\nKill monsters or find some treasures !");
		else {
			hero.gold -= amount;
			callb();
		}
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
	
	function fight( mo : Monster ) {
		var m = mo.getStats();
		var l = hero.attack - m.def;
		if( l < 0 || hero.life <= 0 ) l = 0;
		mo.life -= l;
		popLife(mo, l);

		var l = m.att - hero.defense;
		if( l < 0 ) l = 0;
		hero.life -= l;
		if( hero.life < 0 ) hero.life = 0;
		popLife(hero, l);
		
		if( mo.life <= 0 ) {
			mo.remove();
			monsters.remove(mo);
			hero.gold += m.gold;
		}
		
		if( hero.life <= 0 )
			message("Game Over");
	}
	
	function popLife( t : Entity, l : Int ) {
		var life = newText(true);
		life.text = Std.string(l);
		life.textColor = t == hero ? 0xFF8080 : 0xFFFFFF;
		
		var b = life.getBounds(life);
		var lbmp = new flash.display.BitmapData(Math.ceil(b.width), Math.ceil(b.height), true, 0);
		lbmp.draw(life, new flash.geom.Matrix(1, 0, 0, 1, -b.left, -b.top));
		
		var p = t.mc.localToGlobal(new flash.geom.Point(3, -5));

		var life = new BMP(lbmp);
		life.x = p.x - (lbmp.width >> 1);
		life.y = p.y;
		//trace(life.x + "/" + life.y);
		uiContent.addChildAt(life,0);
		lifes.push({ l : life, t : 1. });
	}
	
	function init() {
		cities = [];
		npcs = [];
		monsters = [];
		sprites = [];
		rnd = new Rand(42);
		
		var start = START[SINDEX];
		hero = new Hero(start.x, start.y);
		hero.life = start.life;
		hero.gold = start.gold;
		hero.attack = start.att;
		hero.defense = start.def;
		
		for( x in 0...World.SIZE )
			for( y in 0...World.SIZE )
				switch( world.get(x,y) ) {
				case CityPos:
					var c = new City(this, x, y);
					cities.push(c);
				default:
				}

		var mids = [Blob, Spider, GreenOrc, Skeleton];
		for( m in world.monsters ) {
			var k = mids[m.i];
			if( k == null ) throw "Unknown monster #" + m.i;
			var m = new Monster(m.x, m.y, k);
			monsters.push(m);
		}

		var npcs = [Soldier, WoodCuter, King, Walker];
		for( i in 0...30 ) {
			var p = freeSpace();
			var n = addNPC(p.x, p.y, npcs[rnd.random(npcs.length)]);
			n.mspeed *= Math.random() + 0.5;
		}

		var n = addNPC(38, 93, Soldier);
		n.locked = true;
		n.onHit = function() {
			message("It's dangerous to go up there,\nyou will need a better weapon !");
			return true;
		}
		var n = addNPC(47, 87, Soldier);
		n.locked = true;
		n.onHit = function() {
			if( hero.hasFlag(n) )
				return false;
			if( hero.defense >= 15 ) {
				message("You have a good-enough armor to go north.\nBeware, monsters are stronger there !");
				hero.setFlag(n);
			} else
				message("It's dangerous to go up there,\nyou will need a better armor !");
			return true;
		}
		var n = addNPC(92, 101, King);
		n.locked = true;
		n.onHit = function()
		{
			if( hero.hasFlag(n) )
				return false;
			askBuy(n, "I'll let you pass safely for $G Gold, little boy", 25, function() {
				hero.setFlag(n);
				message("Thank you, my lord !");
			});
			return true;
		}
				
		world.initPath(hero.x, hero.y);
		drawWorld();
		update(null);
		root.addEventListener(flash.events.Event.ENTER_FRAME, update);
	}
	
	function addNPC(x, y, k) {
		var n = new Npc(x, y, k);
		npcs.push(n);
		return n;
	}
	
	function explore( x : Int, y : Int ) {
		switch( world.addr(x,y) )
		{
			case world.addr(51, 73):
				message("You found a bit of ore");
			default:
				trace("Unknown cave @" + x + "," + y);
		}
	}
	
	function collide( x : Int, y : Int, isHero = false ) {
		switch( world.get(x,y) )  {
		case Sea, DarkSea, Mountain:
			return true;
		case Cave:
			if( isHero ) {
				var p = { x : x, y : y };
				if( hero.hasFlag(p) )
					message("You have already explored this cave !");
				else {
					ask("Explore this cave ?", function(b) {
						if( b ) {
							if( !hero.hasTorch() )
								message("It's too dark inside here : you need a torch !");
							else {
								explore(p.x,p.y);
								hero.setFlag(p);
							}
						}
					});
				}
			}
			return true;
		default:
		}
		for( n in npcs )
			if( n.x == x && n.y == y )
				return !isHero || n.onHit();
		for( m in monsters )
			if( m.x == x && m.y == y ) {
				if( isHero ) {
					if( hero.wait < 0 && hero.life > 0 ) {
						fight(m);
						hero.wait = 30;
					}
				}
				return true;
			}
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
	
	function gameOver() {
		worldBmp.dispose();
		root.removeEventListener(flash.events.Event.ENTER_FRAME, update);
		root.parent.removeChild(uiContent);
		while( root.numChildren > 0 )
			root.removeChild(root.getChildAt(0));
		root.stage.focus = root.stage;
		haxe.Timer.delay(main,500);
	}
	
	function update(_) {
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
				} else if( hero.life <= 0 ) {
					if( action ) {
						gameOver();
						return;
					}
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
						case world.addr(33,95):
							askBuy(c, "Buy a dagger (+5 Att) for $G gold ?", 10, function() { hero.attack += 5; message("You attack has raised to " + hero.attack); } );
						case world.addr(13,116):
							askBuy(c, "Buy a shield (+5 Def) for $G gold ?", 20, function() { hero.defense += 5; message("Your defense has raised to " + hero.defense); } );
						case world.addr(72, 111):
							ask("Heal 30 Life for 30 gold ?", function(b) if( b ) {
								var delta = hero.maxLife - hero.life;
								if( delta < 30 )
									message("You are healthy enough !");
								else
									buy(30, function() { hero.life += 30; message("You now have " + hero.life + " life"); } );
							});
						case world.addr(100, 97):
							askBuy(c, "Buy a leather armor (+5 Def) for $G gold ?", 30, function() { hero.defense += 5; message("Your defense has raised to " + hero.defense); } );
						case world.addr(42, 86):
							askBuy(c, "The City of Wonders will heal you for free.\nOne Time", 0, function() { hero.life = hero.maxLife; message("You have been fully healed !"); } );
						default:
							trace("Unknown city @" + c.x + "," + c.y);
						}
					}
				if( !found )
					curCity = null;
				hero.frame = 0;
			}
		}
		hero.update();
		
		for( t in world.treasures ) {
			var dx = t.x - hero.x;
			var dy = t.y - hero.y;
			var d = dx * dx + dy * dy;
			if( t.twink != null && !t.twink.alive() )
				t.twink = null;
			if( d == 0 ) {
				world.treasures.remove(t);
				hero.setFlag(t);
				hero.gold += t.g;
				message("You found a treasure of " + t.g + " gold !");
			} else if( d <= 4 && Std.random(d * 40) == 0 && t.twink == null ) {
				var s = addSprite(t.x, t.y, Twinkle);
				s.mc.alpha = 1 / Math.sqrt(d);
				s.aspeed *= 4;
				t.twink = s;
			}
		}
		
		for( s in sprites.copy() )
			s.update();
		for( n in npcs )
			n.update();
		for( m in monsters )
			m.update();
			
		for( l in lifes.copy() ) {
			l.t -= 0.08;
			l.l.alpha = l.t * 2;
			l.l.y -= 0.7;
			if( l.t < 0 ) {
				l.l.bitmapData.dispose();
				lifes.remove(l);
			}
		}
			
		dm.ysort(PLAN_NPC);
	}
	
	function addSprite(x, y, k) {
		var e = new Sprite(x, y, k);
		sprites.push(e);
		return e;
	}
	
	function drawWorld() {
		worldBmp = new flash.display.BitmapData(World.SIZE * 5, World.SIZE * 5, true, 0);
		world.draw(worldBmp);
		dm.add(new flash.display.Bitmap(worldBmp),PLAN_WORLD);
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