
class Npc extends Entity {
	
	var target : { x : Int, y : Int };
	var path : Array<{ x : Int, y : Int }>;
	var waitMove : Float;
	public var locked : Bool;
	
	public function new(x, y, k) {
		super(x, y, k);
		waitMove = 0;
		path = [];
	}

	public static var TEXTS = [
		"Elfs love cabbage.\nA lot !",
		"There is a Dragon somewhere,\na big one...",
		"Dwarfs like money a lot,\nonly their friends get good prices",
		"The north is entirely frozen,\nexcept the place where the Dragon live",
		"I've seen many people in my life.\nI mean, including you.",
		"Did you knew that shadows are very weak\nagainst magic ?",
		"I would like one time to go\ntake a bath at one of the\ncity of wonders...",
		"Gold or Life ?\nSometimes it's hard to choose.\nIn many different ways actually...",
		"I you push people they might\nrun away from you.\nMaybe.",
		"This is the land of Noland.\nDo you believe it ?",
		"There is a lost city somewhere\nsince nobody goes there I heard\nthey are happy to have visitors",
		"A city which cannot be seen ?\nNever heard such a story...",
		"Sometimes there are shorter paths\nsomethimes they are longer ones.\nDepends on your luck ?",
		"Demons are strong creatures.\nDon't fight them until you're ready !",
		"The King was supposed to protect us.\nI guess he's having fun again instead...\nThat's what King are doing right ?",
		"Next time I'll vote for another King.\nYes, Noland is a Kingocracy",
		"I've seen the Dragon !\nNo I'm joking...\nI would be dead in that case...",
		"You need a Torch to enter a cave\nbut maybe you know that already.",
		"Some caves lead to other part of the world.\nBe careful sometimes you can't return !",
		"Don't forget to kill weak monsters !\nYou'll get some extra gold !",
		"I wish I could walk on the sea\nso I can leave Noland to go on a trip in Europa.",
		"I have to idea with a 'Computer' is.\nWhat about you ?",
		"Dwarfs are leaving at the top of a of mountain",
		"I am ERROR.\n... I guess",
		"I lost my NyanCat !\nTell me if you find it somewhere !",
		"I fight monsters all the day.\nDuring the week-end I fight with my wife.\nShe's the most frightening !",
		"The ruins of Coren are at the North-West\nof Noland.\nThey are dangerous !",
		"I wish I could have play some music.\nBut looks like I didn't have time for it",
		"Blobs tend to gather in forests.\nI'm happy to slash them anytime.\nPoor creatures...",
	];
	
	public dynamic override function onHit() {
		game.message(TEXTS[id - game.npcs[0].id]);
		if( target == null || path == null || path.length == 0 || (target.x == game.hero.x && target.y == game.hero.y) )
			chooseTarget();
		return true;
	}
	
	public function chooseTarget() {
		game.world.initPath(x, y);
		function dist(x, y) return game.world.getDist(x, y);
		switch( Std.random(6) ) {
		case 0, 1, 2:
			// goto city
			var c;
			var cities = game.cities.copy();
			while( true ) {
				c = cities[Std.random(cities.length)];
				if( c == null ) {
					chooseTarget();
					return;
				}
				cities.remove(c);
				var d = dist(c.x,c.y);
				if( d <= 0 ) continue;
				if( d > 100 && Std.random(Math.ceil(d / 100)) != 0 ) continue;
				target = c;
				break;
			}
		case 3, 4:
			// goto place
			var x, y;
			while( true ) {
				x = Std.random(World.SIZE);
				y = Std.random(World.SIZE);
				var d = dist(x,y);
				if( d <= 0 ) continue;
				if( d > 50 && Std.random(Math.ceil(d / 50)) != 0 ) continue;
				target = { x : x, y : y };
				break;
			}
		case 5:
			// follow
			var n;
			var npcs = game.npcs.copy();
			while( true ) {
				n = npcs[Std.random(npcs.length)];
				if( n == null ) {
					chooseTarget();
					return;
				}
				npcs.remove(n);
				var d = dist(n.x,n.y);
				if( d <= 0 ) continue;
				if( d > 30 && Std.random(Math.ceil(d / 20)) != 0 ) continue;
				target = n;
				break;
			}
		default:
			throw "assert";
		}
		path = game.world.getPath(target.x, target.y);
	}

	function nextMove() {
		var p = path.pop();
		if( p == null ) {
			if( Std.random(100) == 0 )
				chooseTarget();
		} else if( !game.collide(p.x,p.y) ) {
			x = p.x;
			y = p.y;
		} else {
			game.world.initPath(x, y);
			path = game.world.getPath(target.x, target.y);
		}
	}
	
	override public function update() {
		if( canMove() && !locked ) {
			waitMove -= mspeed;
			if( waitMove < 0 ) nextMove();
		} else
			waitMove = 3;
			
		super.update();
	}
	
}
