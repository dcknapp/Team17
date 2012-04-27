package
{
	import org.flixel.*;

	public class PlayStateLevelTwo extends FlxState
	{
		public function PlayStateLevelTwo()
		{
		}
		
		public var enemies:FlxGroup = new FlxGroup;
		public var coordBox:FlxText;
		public var lifeCounter:FlxText;
		public var coords:FlxPoint;
		public var level:FlxTilemap;
		public var player:Player;
		private var paused:Boolean;
		public var pauseGroup:FlxGroup;
		private var quitBtn:FlxButton;
		private var cam:FlxCamera;
		private var bar:FlxSprite;
		private var endChest:worldObject;
		private var levelEnded:Boolean = false;
		private var endLevelTimer:FlxTimer = new FlxTimer();
		private var endLevelText:FlxText = new FlxText(200, 150, 100, "You beat the level"); 

		override public function create():void
		{
			FlxG.framerate = 30;
			FlxG.flashFramerate = 30;
			FlxG.bgColor = 0xffffffff;
			paused = false;
			pauseGroup = new FlxGroup();
			
			loadLevel();
			
			// adds a constantly updating textbox of the player's coordinates.  for testing
			coordBox = new FlxText(250, 4, 200);
			coordBox.scrollFactor.x = coordBox.scrollFactor.y = 0;
			coordBox.color = 0xfff0000;
			add(coordBox);
			
			drawHealthBar();
			
			cam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
			cam.follow(player);
			cam.setBounds(0, 0, level.width, level.height);
			FlxG.addCamera(cam);
			
			quitBtn = new FlxButton(120, 120, "Quit", onQuit); //put the button out of screen so we don't see in the two other cameras
			pauseGroup.add(quitBtn);

			// Create a camera focused on the quit button.
			// We do this because we don't want the quit button to be
			// tinted by the other cameras.
		}
		override public function update():void 
		{
			FlxG.collide();
			for (var k:int = 0; k < enemies.length; k++) {
				if (enemies.members[k].type == "spike")
					FlxG.overlap(enemies.members[k], player, doSpikeAttack(enemies.members[k]));
				else if (enemies.members[k].type == "boomeranger")
					FlxG.overlap(enemies.members[k].getAttackZone(), player, doBoomerangerAttack(enemies.members[k]));
			}
					
			bar.scale.x = player.health * 5;
			updateCoordBox();
			
			if (FlxG.keys.justPressed("P")) {
				FlxG.mouse.hide();
				paused = !paused;
			}
			
			if (paused) {
				FlxG.mouse.show();
				return pauseGroup.update();
			}
			
			if (FlxG.keys.justPressed("H")) {
				player.doDamage(1);
			}
			
			if (FlxG.keys.justPressed("G")) {
				player.heal(1);
			}
			
			if (FlxG.keys.justPressed("C")) {
				for (var i:int = 0; i < enemies.length; i++)
					if (enemies.members[i].type == "spike")
						player.attackSpike(enemies.members[i]);
					else if (enemies.members[i].type == "boomeranger")
						player.attackBoomeranger(enemies.members[i]);
				player.attackDelay.start(.3, 1);
				player.play("slash1");
			}
			
			//if player falls into a pit
			if (player.y > level.height) {
				player.isInvulnerable = false;
				player.doDamage(100);
			}
			//unless it's game over, update life counter
			if (player.lives > -1) lifeCounter.text = "Lives = " + player.lives.toString();
			if (player.health < 1) {
				player.reset(player.startingX, player.startingY);
			}
			
			if (!levelEnded) {
				if (enemies.countDead() == enemies.length) {
					add(endLevelText);
					endLevelTimer.start(5, 1);
					levelEnded = true;
				}
			}
			
			if (levelEnded && endLevelTimer.finished) {
				FlxG.switchState(new PlayStateLevelTwo);
			}
			
			super.update();
		}
		
		//loads level and eventually monster coordinate lists
		private function loadLevel():void {
			var _GroundBackdrop:Backdrop;
			var stringData:Object;
			var levelData:String;
			
			[Embed(source = "../assets/GrassTileSet.png")] var Tiles:Class;
			[Embed(source = "../assets/l1.txt", mimeType = "application/octet-stream")] var Data:Class;
			[Embed(source = "../assets/forest_small.png")] var ImgBackdrop:Class;
			_GroundBackdrop = new Backdrop( 0, 5, ImgBackdrop, 0);		
			add (_GroundBackdrop);
			stringData = new Data();
			levelData = stringData.toString(); // converts the level text file to a string for parsing.
			level = new FlxTilemap();
			level.loadMap(levelData, Tiles, 8, 8);
			level.height = 512;
			add(level);
			FlxG.worldBounds = new FlxRect(0, 0, level.width, level.height);
			//spawn player
			player = new Player(35, 220);
			add(player);
			
			loadEnemies();
		}
			
		private function loadEnemies():void {
			var enemySpike:Enemy;
			var enemyBoomeranger:Boomeranger;
			var stringEnemyData:Object;
			var oneEnemyData:Array;
			var oneEnemyNumber:Array;
		
			[Embed(source = "../assets/l1Enemies.txt", mimeType = "application/octet-stream")] var enemyData:Class;
			var stringEnemyData:Object = new enemyData();
			var oneEnemyData:Array = stringEnemyData.toString().split(';');
			var oneEnemyNumber:Array = new Array;
			for (var i:int = 0; i < oneEnemyData.length; i++)
				oneEnemyNumber[i] = oneEnemyData[i].toString().split(',');				

			for (var j:int = 0; j < oneEnemyNumber.length; j++) {
				if (oneEnemyNumber[j][0].toString() == "spike") {
					enemySpike = new Enemy(oneEnemyNumber[j][1], oneEnemyNumber[j][2], oneEnemyNumber[j][3], oneEnemyNumber[j][4], oneEnemyNumber[j][5], oneEnemyNumber[j][6]);
					add(enemySpike);
					enemies.add(enemySpike);
				}
				else if (oneEnemyNumber[j][0] == "boomeranger") {
					enemyBoomeranger = new Boomeranger(oneEnemyNumber[j][1], oneEnemyNumber[j][2], oneEnemyNumber[j][3], oneEnemyNumber[j][4], oneEnemyNumber[j][5], oneEnemyNumber[j][6]);
					add(enemyBoomeranger);
					enemies.add(enemyBoomeranger);
				}
			}
		}
		
		//draws the health bar sprites and the life counter.
		private function drawHealthBar():void {
			var frame:FlxSprite = new FlxSprite(4,4);
			frame.makeGraphic(52,10); //White frame for the health bar
			frame.scrollFactor.x = frame.scrollFactor.y = 0;
			add(frame);
 
			var inside:FlxSprite = new FlxSprite(5,5);
			inside.makeGraphic(50,8,0xff000000); //Black interior, 48 pixels wide
			inside.scrollFactor.x = inside.scrollFactor.y = 0;
			add(inside);
 
			bar = new FlxSprite(5,5);
			bar.makeGraphic(1,8,0xffff0000); //The red bar itself
			bar.scrollFactor.x = bar.scrollFactor.y = 0;
			bar.origin.x = bar.origin.y = 0; //Zero out the origin
			bar.scale.x = 50; //Fill up the health bar all the way
			add(bar);
			
			lifeCounter = new FlxText(60, 3, 50, "Lives = " + player.lives.toString());
			lifeCounter.scrollFactor.x = lifeCounter.scrollFactor.y = 0;
			add(lifeCounter);
		}
		
		//updates player coordinates. delete for final
		public function updateCoordBox():void {
			coords = player.getScreenXY();
			coordBox.text = "X: " + coords.x.toFixed(0).toString() + ", Y: " + coords.y.toFixed(0).toString();
		}
		
		override public function draw():void {
			if(paused) return pauseGroup.draw();
			super.draw();
		}
		
		private function onQuit():void {
			// Go back to the MenuState
			FlxG.switchState(new MenuState);
		}
		
		private function doSpikeAttack(e:Enemy) {
			if (e.tryAttack(player))
				e.justAttacked();
		}
		
		private function doBoomerangerAttack(b:Boomeranger) {
			if (b.tryAttack(player))
				b.justAttacked();
		}
	}
}