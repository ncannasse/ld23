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
	
	static var DEBUG = true;
	
	static var SINDEX = DEBUG ? 8 : 0;
	static var START = [
		{ x : 30, y : 97, att : 10, def : 5, gold : 0, life : 100, items : [] },
		{ x : 47, y : 88, att : 15, def : 15, gold : 5, life : 35, items : [] }, // 1 spider reste
		{ x : 56, y : 60, att : 15, def : 15, gold : 1, life : 30, items : [Blessing, Magic] },
		{ x : 72, y : 79, att : 15, def : 20, gold : 30, life : 80, items : [Blessing, Magic] },
		{ x : 26, y : 80, att : 15, def : 20, gold : 42, life : 45, items : [Blessing, Magic, Torch] },
		{ x : 83, y : 41, att : 25, def : 20, gold : 0, life : 35, items : [Blessing, Magic, Torch] },
		{ x : 105, y : 54, att : 25, def : 20, gold : 15, life : 150, items : [Blessing, Magic, Torch] },
		{ x : 80, y : 24, att : 30, def : 25, gold : 5, life : 75, items : [Blessing, Magic, Torch] },
		{ x : 39, y : 24, att : 30, def : 30, gold : 0, life : 150, items : [Blessing, Magic, Torch] },
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
		var lines = ma.text.split("\n").length;
		message(ma.text + (lines >= 4 ? "\n" : "\n\n") + (ma.cur?"[Yes]\t\t\t No ":" Yes \t\t\t[No]"));
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
			if( !collide(x, y) )
				return { x : x, y : y };
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
			if( mo.kind == Dragon && hero.life > 0 ) {
				var pts = hero.life * 2 + hero.gold;
				function loop() {
					ask("Come on !\nI'm sure you can do better than " + pts + " points !", function(b) {
						if( !b ) loop() else haxe.Timer.delay(gameOver, 1);
					});
				}
				ask("Congratulation !\nYou killed the villain bad evil Dragon !\nYour score is " + pts + " !\n(Life x 2 + Gold)\nCan you do better ?", function(b) {
					if( !b )
						loop();
					else
						haxe.Timer.delay(gameOver, 1);
				});
			}
		}
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
	
	function regen( life : Int, msg : String ) {
		if( hero.life == hero.maxLife )
			return false;
		hero.life += life;
		if( hero.life > hero.maxLife ) hero.life = hero.maxLife;
		message(msg);
		return true;
	}
	
	function init() {
		cities = [];
		npcs = [];
		monsters = [];
		rnd = new Rand(42);
		
		var start = START[SINDEX];
		hero = new Hero(start.x, start.y);
		hero.life = start.life;
		hero.gold = start.gold;
		hero.attack = start.att;
		hero.defense = start.def;
		if( SINDEX >= 6 ) hero.maxLife = 150;
		for( i in start.items )
			hero.addItem(i);
		
		for( x in 0...World.SIZE )
			for( y in 0...World.SIZE )
				switch( world.get(x,y) ) {
				case CityPos:
					var c = new City(this, x, y);
					cities.push(c);
				default:
				}
		// hidden
		cities.push(new City(this, 81, 47));

		var mids = [Blob, Spider, GreenOrc, Skeleton, Shadow, KillerEye, Sparkling, Demon, Dragon];
		for( m in world.monsters ) {
			var k = mids[m.i];
			if( k == null ) throw "Unknown monster #" + m.i+" @"+m.x+","+m.y;
			var m = new Monster(m.x, m.y, k);
			monsters.push(m);
		}

		var npcs = [Soldier, WoodCuter, King, Walker];
		for( i in 0...30 ) {
			var p = freeSpace();
			var n = addNPC(p.x, p.y, npcs[rnd.random(npcs.length)]);
			n.mspeed *= Math.random() + 0.5;
		}
		
		for( t in world.treasures ) {
			var k;
			var onHit = switch( t.i ) {
				case 0:
					k = Treasure;
					function() {
						var g = 10;
						hero.gold += g;
						message("You found a treasure of " + g + " gold !");
						return true;
					}
				case 1:
					k = Twinkle;
					function() {
						var g = 10;
						hero.gold += g;
						message("You found a treasure of " + g + " gold !");
						return true;
					}
				case 2:
					k = Twinkle;
					function() {
						var g = 20;
						hero.gold += g;
						message("You found a treasure of " + g + " gold !");
						return true;
					}
				case 3:
					k = Treasure;
					function() {
						hero.addItem(DwarfRing);
						message("You found a Dwarf Ring !\nIt makes you friend of the Dwarfs !");
						return true;
					}
				case 4:
					k = Treasure;
					function() {
						if( !regen(30,"You found a small potion !\n(you got +30 life)") )
							message("The potion just broke in your hands");
						return true;
					}
				case 5:
					k = Treasure;
					function()
					{
						hero.defense += 5;
						message("You found the Elves Helmet !\nYou get +5 in Def");
						return true;
					}
				case 6:
					k = Treasure;
					function()
					{
						hero.attack++;
						message("You got the ULTIMATE WEAPON IMPROVEMENT !\nYou get +1 in Att");
						return true;
					}
				default:
					throw "Unknon treasure #" + t.i + " @" + t.x + "," + t.y;
			}
			t.e = new Entity(t.x, t.y, k);
			if( k == Twinkle )
				t.e.aspeed *= 4;
			t.e.onHit = onHit;
		}

		var n = addNPC(38, 93, Soldier);
		n.locked = true;
		n.onHit = function() {
			if( hero.hasFlag(n) )
				return false;
			if( hero.items.remove(KingLetter) ) {
				hero.setFlag(n);
				message("Oh you got a letter for the king ?\nYou shall pass then...");
				return true;
			} else {
				message("This place is restricted to the Royal Family,\nleave at once or die !");
				return true;
			}
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
		
		var n = addNPC(55, 48, WoodCuter);
		n.locked = true;
		n.onHit = function() {
			if( hero.x < n.x )
				return false;
			message("While I'm looking this way,\nI'll not let you go there !");
			return true;
		};
		
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
		function spawn(k, dx, dy) {
			var m = new Monster(x + dx, y + 1 + dy, k);
			monsters.push(m);
		}
		switch( world.addr(x,y) )
		{
			case world.addr(54, 56):
				hero.goto(52, 88);
				return false;
			case world.addr(52, 87):
				hero.goto(54, 57);
				return false;
			case world.addr(51, 73):
				var g = 30;
				message("You found " + g + " gold in that cave !");
				hero.gold += g;
			case world.addr(35, 87):
				spawn(Shadow, 0, -1);
				spawn(Shadow, -1, 0);
				spawn(Shadow, 0, 1);
				message("Some monsters have appeared !");
			case world.addr(26, 79):
				hero.goto(24, 45);
				return false;
			case world.addr(24, 44):
				message("Uh-oh !\nSeems like you can't go back from here !");
				return false;
			case world.addr(52, 8):
				hero.goto(53, 24);
				return false;
			case world.addr(53, 23):
				hero.goto(52, 9);
				return false;
			case world.addr(46, 27):
				var g = 5;
				message("You found " + g + " gold in that cave !");
				hero.gold += g;
			default:
				throw ("Unknown cave @" + x + "," + y);
		}
		return true;
	}
	
	function collide( x : Int, y : Int, isHero = false ) {
		var t = world.get(x, y);
		switch( t )  {
		case Cave:
			if( isHero ) {
				var p = { x : x, y : y };
				if( hero.hasFlag(p) )
					message("You have already explored this cave !");
				else {
					ask("Explore this cave ?", function(b) {
						if( b ) {
							if( !hero.hasItem(Torch) )
								message("It's too dark inside here : you need a torch !");
							else if( explore(p.x,p.y) )
								hero.setFlag(p);
						}
					});
				}
			}
			return true;
		default:
			if( world.collide(t) ) {
				if( t == FakeWater && isHero )
					return false;
				return true;
			}
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
		
		if( !messageMC.visible && hero.life <= 0 ) {
			hero.life = 0;
			message("Game Over");
		}
		
		if( DEBUG ) {
			if( Key.isToggled("G".code) )
				hero.gold += 5;
			if( Key.isToggled("L".code) )
				hero.life += 5;
			if( Key.isToggled("T".code) ) {
				var x = Std.int(root.mouseX / 5);
				var y = Std.int(root.mouseY / 5);
				hero.goto(x, y);
			}
		}
		
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
						case world.addr(72, 111), world.addr(56,39):
							ask("Heal 30 Life for 30 gold ?", function(b) if( b ) {
								var delta = hero.maxLife - hero.life;
								if( delta < 30 )
									message("You are healthy enough !");
								else
									buy(30, function() { hero.life += 30; message("You now have " + hero.life + " life"); } );
							});
						case world.addr(100, 97):
							askBuy(c, "Buy a leather armor (+5 Def) for $G gold ?", 30, function() { hero.defense += 5; message("Your defense has raised to " + hero.defense); } );
						case world.addr(42, 86), world.addr(45,63), world.addr(55,54):
							askBuy(c, "This City of Wonders will heal you for free.\nOne Time", 0, function() { hero.life = hero.maxLife; message("You have been fully healed !"); } );
						case world.addr(23, 64):
							if( hero.hasFlag(c) )
								message("The Shadows want more of your Life but have\nnothing to trade for it !");
							else
								ask("This City of Shadows will eat 30 of your Life\nin exchange of a King letter", function(b) {
									if( b ) {
										hero.life -= 30;
										hero.setFlag(c);
										hero.addItem(KingLetter);
										message("You got the King letter !\nBut who need this ?");
									}
								});
						case world.addr(12, 90):
							askBuy(c, "Welcome to the city of priests,\ndo you want blessing for $G gold ?\n(skeletons get -5 Att)", 40, function() { hero.addItem(Blessing); message("You got some blessing !"); } );
						case world.addr(42, 56):
							askBuy(c, "The shades are weak against magic.\nWizardry can help if you have $G gold.\n(shades loose immunity)", 20, function() { hero.addItem(Magic); message("You got magic !"); } );
						case world.addr(29, 71):
							askBuy(c, "A copper armor is not that bad, you know ?\nAt least it's cheap : $G gold (+5 Def)", 25, function() { hero.defense += 5; message("You got the Copper armor !\nDoes it really work ???"); } );
						case world.addr(73, 79):
							askBuy(c, "Dwarf don't like dark.\nDwarf make torches.\nYou buy for $G ?", hero.hasItem(DwarfRing) ? 30 : 50, function() { hero.addItem(Torch); message("You got torches !\nTime to explore some caves, maybe ?\nBut be careful !"); } );
						case world.addr(81, 47):
							askBuy(c, "Welcome to the Hidden City of Stormfall\nWe make strong weapons.\nWant to buy a sword for $G ?\n(+10 Att)", 100, function() { hero.attack += 10; message("You got a great sword !"); } );
						case world.addr(110, 70):
							if( hero.hasFlag(c) )
								message("Thank you for visiting us !");
							else
								ask("It's been a very long time with no visitor !\nTo reward you, we will raise your max life !", function(b) {
									if( b ) {
										hero.maxLife += 50;
										hero.setFlag(c);
										message("You got +50 max life !");
									}
								});
						case world.addr(80, 22):
							askBuy(c, "If you want the ultimate weapon, it's yours !\n(Only $G gold for +5 Att)", 100, function() {
								hero.attack += 5;
								message("You got the ULTIMATE WEAPON !\nIs it real ???");
							});
						case world.addr(38, 16):
							askBuy(c, "Welcome to the ruins of Coren.\nThe dragon is not very far, you should heal yourself.\nHeal for $G gold ?", 80, function() {
								hero.life = hero.maxLife;
								message("Your life as returned !");
							});
						case world.addr(34, 30):
							askBuy(c, "Welcome to the ruins of Coren.\nIf you want the ultimate armor, it's your !\n(Only $G gold for +5 Def)", 80, function() {
								hero.defense += 5;
								message("You got the ULTIMATE ARMOR !\n(looks like it's made in plastic)");
							});
						default:
							throw ("Unknown city @" + c.x + "," + c.y);
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
			t.e.update();
			if( d == 0 && t.e.onHit() ) {
				world.treasures.remove(t);
				t.e.remove();
				hero.setFlag(t);
			}
		}
		
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