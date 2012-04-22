class Sprite extends Entity {
	
	override public function update() {
		var old = curFrame;
		super.update();
		if( curFrame >= 0 && old > curFrame ) {
			remove();
			game.sprites.remove(this);
		}
	}
}