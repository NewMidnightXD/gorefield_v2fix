package funkin.menus;

import haxe.Json;
import funkin.backend.FunkinText;
import funkin.menus.credits.CreditsMain;
import flixel.FlxState;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import funkin.backend.scripting.Script;
import funkin.game.Data;
import funkin.menus.TitleState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import funkin.backend.scripting.events.*;
import funkin.options.OptionsMenu;
import funkin.menus.ModSwitchMenu;
import funkin.editors.EditorPicker;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;
import funkin.backend.system.Conductor;
import funkin.backend.utils.DiscordUtil;
import funkin.backend.shaders.GlowShader;
import funkin.backend.shaders.HeatWaveShader;
import funkin.backend.shaders.GlitchShader;
import mobile.substates.MobileControlSelectSubState;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var options:Array<String> = [
	'story_mode',
	'freeplay',
	'options',
	'credits',
];

var optionsTexts:Map<String, String> = [
	'story_mode' => "Be very careful, be cautious!!",
	'freeplay' => "Sing along with GoreField",
	'options' => "The options you expected?",
	'credits' => "Credits to those who helped!",
];

// SPANISH - Jloor
var optionsTextsSPANISH:Map<String, String> = [
	'story_mode' => "Ten mucho cuidado, se cauteloso!!",
	'freeplay' => "Canta junto a Gorefield...",
	'options' => "Opciones..., Que esperabas?",
	'credits' => "Quienes trabajaron en el Mod!",
];

public static var curMainMenuSelected:Int = 0;
var menuItems:FlxTypedGroup<FlxSprite>;
var cutscene:FlxSprite;
var curSelected:Int = curMainMenuSelected;

var menuInfomation:FlxText;
var logoBl:FlxSprite;
var fire:FlxSprite;
var gorefield:FlxSprite;
public static var script:String = "";
public var pauseScript:Script;
var vigentte:FlxSprite;

//PROMPT
var boxSprite:FlxSprite;
var glow:GlowShader;
var glitch:GlitchShader;
var heatWave:HeatWaveShader;
var isInProgPrompt:Bool = false;
var yesText:Alphabet;
var noText:Alphabet;
var progInfoText:Alphabet;
var onYes:Bool = true;

	override function create()
	{
	super.create();

	pauseScript = Script.create(Paths.script(script));
	pauseScript.setParent(this);
	pauseScript.load();
	
	pauseScript.call('create');
		
	PlayState.deathCounter = 0;
	DiscordUtil.changePresence('Scrolling Through Menus...', "Main Menu");
	CoolUtil.playMenuSong();
	FlxG.camera.bgColor = FlxColor.fromRGB(17,5,33);

	fire = new FlxSprite(-100, -60);
	fire.frames = Paths.getSparrowAtlas('stages/skyFire/fire_f4');
	fire.animation.addByPrefix("fire", "FIRE", 24, true);
	fire.animation.play("fire");
	insert(0,fire); fire.visible = false;

	gorefield = new FlxSprite();
	gorefield.frames = Paths.getSparrowAtlas('menus/mainmenu/gorefield_menu');
	gorefield.animation.addByPrefix('idle', 'MenuIdle0000', 1);
	gorefield.animation.addByPrefix('beat', 'MenuIdle', 24,false);
	gorefield.animation.addByPrefix('jeje', 'JEJE', 24);
	gorefield.animation.play('idle');
	gorefield.updateHitbox();
	gorefield.x = 586; gorefield.y = 40;
	gorefield.antialiasing = true;
	insert(1,gorefield);

	logoBl = new FlxSprite();
	logoBl.frames = Paths.getSparrowAtlas('menus/logoMod');
	logoBl.animation.addByPrefix('bump', 'logo bumpin', 24,false);
	logoBl.animation.play('bump');
	logoBl.scale.set(0.6, 0.6);
	logoBl.updateHitbox();
	logoBl.x = 80;
	logoBl.antialiasing = true;
	insert(1,logoBl);

	menuInfomation = new FlxText(0, 675, FlxG.width, "Please select a option.", 28);
	menuInfomation.setFormat("fonts/pixelart.ttf", 28, FlxColor.WHITE, "center");
	menuInfomation.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 5, 50);
	menuInfomation.borderSize = 2;
	insert(3,menuInfomation);

	menuItems = new FlxTypedGroup();
	insert(1,menuItems);

	for (i=>option in options)
	{
		var menuItem:FlxSprite = new FlxSprite(0, 0);
		menuItem.frames = Paths.getSparrowAtlas('menus/mainmenu/menu_' + option);
		menuItem.animation.addByPrefix('idle', option + " basic", 24);
		menuItem.animation.addByPrefix('selected', option + " white", 24);
		menuItem.animation.play('idle');
		menuItem.updateHitbox();
		menuItem.antialiasing = true;

		menuItem.x = 520 - menuItem.width - (100 + (i*50));
		menuItem.y = 320 + ((menuItem.ID = i) * 92.5);

		menuItems.add(menuItem);
	}

	cutscene = new FlxSprite();
	cutscene.frames = Paths.getSparrowAtlas('menus/mainmenu/garfield_menu_startup');
	cutscene.animation.addByPrefix('_', "GARFIELD", 24, false);
	cutscene.updateHitbox(); cutscene.screenCenter();
	cutscene.visible = false;

	if (!TitleState.seenMenuCutscene) {
		selectedSomthin = TitleState.seenMenuCutscene = true;
		menuItems.visible = false;
		menuInfomation.visible = false;
		gorefield.visible = false;
		logoBl.visible = false;
		add(cutscene);

		new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			cutscene.animation.play("_", cutscene.visible = true);
		});
		cutscene.animation.finishCallback = function (name : String) {
			changeItem(0);
		menuItems.visible = true;
		menuInfomation.visible = true;
		gorefield.visible = true;
		logoBl.visible = true;
			remove(cutscene);

			menuInfomation.y += 100;
			FlxTween.tween(menuInfomation, {y: menuInfomation.y - 100}, (Conductor.stepCrochet / 1000) * 4, {ease: FlxEase.circOut});

			logoBl.alpha = 0;
			FlxTween.tween(logoBl, {alpha: 1 , angle: 0}, (Conductor.stepCrochet / 1000) * 2, {ease: FlxEase.circOut});

			menuItems.forEach(function(item:FlxSprite) {
				item.x -= 500;
				if (item.ID == curSelected) FlxTween.tween(item, {x: 580 - item.width + 50}, (Conductor.stepCrochet / 1000) * 2);
				else FlxTween.tween(item, {x: 520 - item.width}, (Conductor.stepCrochet / 1000) * 2);
			});
			selectedSomthin = false;
		}
	}
	else{
		changeItem(0);
	}

	vigentte = new FlxSprite().loadGraphic(Paths.image("menus/black_vignette"));
	vigentte.alpha = 0.2; vigentte.scrollFactor.set(0,0);
	add(vigentte);

	

	boxSprite = new FlxSprite(0,730).loadGraphic(Paths.image("menus/storymenu/TEXT_BOX"));
	boxSprite.scale.set(1.1,1.1);
	boxSprite.updateHitbox();
	boxSprite.screenCenter(FlxAxes.X);
	boxSprite.scrollFactor.set();
	insert(99998,boxSprite);

	yesText = new Alphabet(0, 0, FlxG.save.data.spanish ? "SI" : "YES", true);
	yesText.scrollFactor.set();
	insert(99999,yesText);

	noText = new Alphabet(0, 0, "NO", true);
	noText.scrollFactor.set();
	insert(99999,noText);

	progInfoText = new Alphabet(0, 0, FlxG.save.data.spanish ? "Te Gustaria Continuar?" : "Would You Like To Continue?", false);
	progInfoText.scrollFactor.set();
	progInfoText.screenCenter(FlxAxes.X);
	insert(99999,progInfoText);

	pauseScript.call("postCreate");
	}
	
function checkWeekProgress() {
	if(Data.weekProgress != null){
		if (Data.weekProgress.exists("Principal Week...")){
			progInfoText.visible = true;
			openProgressPrompt(true,function(){
				isPlayingFromPreviousWeek = false;
				goToItem();
			},function(){
				isPlayingFromPreviousWeek = true;
				goToItem();
			},function() {selectedSomthin = false;}
			);
		}
		else{
			isPlayingFromPreviousWeek = false;
			goToItem();
		}
	}
	else{
		isPlayingFromPreviousWeek = false;
		goToItem();
	}
}

public var finishedCallback:Void->Void;
public var acceptedCallback:Void->Void;
var cancelCallback:Void->Void;
function openProgressPrompt(entered:Bool, ?finishCallback, ?accepted, ?cancel){
	isInProgPrompt = entered;
	FlxTween.cancelTweensOf(boxSprite);
	FlxTween.tween(boxSprite, {y: entered ? 150 : 730}, entered ? 0.7 : 0.4, {ease: FlxEase.cubeOut});

	finishedCallback = entered ? finishCallback : null;
	acceptedCallback = entered ? accepted : null;
	if (cancel != null)
		cancelCallback = cancel;
}

function handleProgressPrompt(){
	var scales:Array<Float> = [0.75, 1];
	var alphas:Array<Float> = [0.6, 1];
	var confirmInt:Int = onYes ? 1 : 0;

	yesText.alpha = alphas[confirmInt];
	yesText.scale.set(scales[confirmInt], scales[confirmInt]);
	noText.alpha = alphas[1 - confirmInt];
	noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
}


/*function loadCheckpoint(point) {
	if(point == null) {
		FlxG.sound.play(Paths.sound("menu/story/locked"));
		return;
	}

	selectedSomthin = true;

	var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound("menu/confirmMenu")); sound.volume = 1; sound.play();

	(new FlxTimer()).start(2, function() {
		FlxG.camera.fade(FlxColor.RED, 3.2, false, function() {
			PlayState.storyWeek = point.storyWeek;
			PlayState.storyPlaylist = point.storyPlaylist;
			PlayState.isStoryMode = true;
			PlayState.campaignScore = point.campaignScore;
			PlayState.campaignMisses = point.campaignMisses;
			PlayState.campaignAccuracyTotal = point.campaignAccuracyTotal;
			PlayState.campaignAccuracyCount = point.campaignAccuracyCount;
			PlayState.opponentMode = point.opponentMode;
			PlayState.coopMode = point.coopMode;
			PlayState.chartingMode = false;
			PlayState.difficulty = point.difficulty;
			PlayState.__loadSong(PlayState.storyPlaylist[0], PlayState.difficulty);
			FlxG.switchState(new ModState("gorefield/LoadingScreen"));
		});
	});
}*/

function changeItem(change:Int = 0) {
	curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length-1);

	FlxG.sound.play(Paths.sound("menu/scrollMenu"));

	menuItems.forEach(function(item:FlxSprite) {
		FlxTween.cancelTweensOf(item);
		item.animation.play(item.ID == curSelected ? 'selected' : 'idle');

		item.updateHitbox();

		if (item.ID == curSelected)
			FlxTween.tween(item, {x: 580 - item.width + 50}, (Conductor.stepCrochet / 1000), {ease: FlxEase.quadInOut});
		else
			FlxTween.tween(item, {x: 520 - item.width}, (Conductor.stepCrochet / 1000) * 1.5, {ease: FlxEase.circOut});
	});

	if (FlxG.save.data.spanish) {
		menuInfomation.text = optionsTextsSPANISH.get(options[curSelected]);
	} else {
		menuInfomation.text = optionsTexts.get(options[curSelected]);
	}
}

var isPlayingFromPreviousWeek:Bool = false;
function goToItem() {
	selectedSomthin = true;

	var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound("menu/confirmMenu")); sound.volume = 1; sound.play();
	switch (options[curSelected]) {
		case "story_mode": 
			FlxG.sound.play(Paths.sound('menu/pressStorymode'));
			gorefield.animation.play('jeje'); gorefield.x = 250;
			gorefield.offset.y = 15; gorefield.offset.x = -25;
			gorefield.color = 0xFFDE8888;

			FlxG.sound.music.stop();
			FlxG.camera.shake(0.005, 5.2);

			FlxG.camera.flash(FlxColor.WHITE, 1);

			FlxG.camera.bgColor = 0xff80261f;
			fire.visible = true;
			fire.animation.play('fire');

			FlxTween.tween(vigentte, {alpha: .4}, 3.2);

	        heatWave = new HeatWaveShader();

	        glitch = new GlitchShader();
	        glow = new GlowShader();
	        glow.Quality.value = [8.0];
	        glow.Directions.value = [16.0];
			FlxG.camera.setFilters([new ShaderFilter(glow), new ShaderFilter(heatWave), new ShaderFilter(glitch)]);

			for (member in members)
				if (Std.isOfType(member, FlxBasic)) member.visible = member == fire || member == gorefield || member == vigentte;

			MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
			(new FlxTimer()).start(2, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.RED, 3.2, false, function() {
					if(isPlayingFromPreviousWeek){
						if (Data.weekProgress.exists("Principal Week...")){
							trace("Loading the Previous Progress for " + "Principal Week...");
							var resumeInfo = Data.weekProgress.get("Principal Week...");
				
							var songArrayNames:Array<String> = [for (song in ["The Great Punishment", "Curious Cat", "Metamorphosis", "Hi Jon", "Terror in the Heights", "BIGotes"]) song.toLowerCase()]; //grab the name list
							songArrayNames = songArrayNames.slice(songArrayNames.indexOf(resumeInfo.song.toLowerCase()));
				
							var songArray:Array<WeekSong1> = []; //convert to weeksong format
							for (song in songArrayNames){
								songArray.push({name: song, hide: false});
							}
							PlayState.loadWeek({
									name: "Principal Week...",
									id: "Principal Week...",
									sprite: null,
									chars: [null, null, null],
									songs: songArray,
									difficulties: ['hard']
								}, "hard");
							PlayState.campaignMisses = resumeInfo.weekMisees;
							PlayState.campaignScore = resumeInfo.weekScore;
							PlayState.deathCounter = resumeInfo.deaths;
						}	
						else{
							PlayState.loadWeek({
								name: "Principal Week...",
								id: "Principal Week...",
								sprite: null,
								chars: [null, null, null],
								songs: [for (song in ["The Great Punishment", "Curious Cat", "Metamorphosis", "Hi Jon", "Terror in the Heights", "BIGotes"]) {name: song, hide: false}],
								difficulties: ['hard']
							}, "hard");
						}
					}
					else{						
						PlayState.loadWeek({
							name: "Principal Week...",
							id: "Principal Week...",
							sprite: null,
							chars: [null, null, null],
							songs: [for (song in ["The Great Punishment", "Curious Cat", "Metamorphosis", "Hi Jon", "Terror in the Heights", "BIGotes"]) {name: song, hide: false}],
							difficulties: ['hard']
						}, "hard");
					}
					        FlxG.switchState(new LoadingScreen());
				});
			});
		case "freeplay": FlxG.switchState(new StoryMenuState());
		case "options": FlxG.switchState(new OptionsMenu());
		case "credits": FlxG.switchState(new CreditsScreen());
		default: selectedSomthin = false;
}
}

var tottalTime:Float = 0;
var selectedSomthin:Bool = false;
override function update(elapsed:Float) {
	super.update(elapsed);
	tottalTime += elapsed;

	pauseScript.call("update", [elapsed]);
	
	fire.y = -50 + (FlxMath.fastSin(tottalTime) * 10);
	if (gorefield.animation.name == "jeje") {
		gorefield.offset.y = 15 + FlxG.random.float(-6,6); gorefield.offset.x = -25 + FlxG.random.float(-2,2);
	}

	if (FlxG.sound.music != null)
		Conductor.songPosition = FlxG.sound.music.time;

	yesText.x = boxSprite.x * 4.2;
	yesText.y = boxSprite.y + 360;

	noText.x = boxSprite.x * 16.5;
	noText.y = boxSprite.y + 360;

	progInfoText.x = boxSprite.x * 3.6;
	progInfoText.y = boxSprite.y + 140;

	if (FlxG.keys.justPressed.SEVEN || virtualPad.buttonE.justPressed && FlxG.save.data.dev) {
		persistentUpdate = !(persistentDraw = true);
		openSubState(new EditorPicker());
	}

	#if !GOREFIELD_CUSTOM_BUILD
	if (controls.SWITCHMOD || virtualPad.buttonM.justPressed) {
		openSubState(new ModSwitchMenu());
		persistentUpdate = !(persistentDraw = true);
	}
	#end

	if (selectedSomthin) return;

	if(isInProgPrompt){
		if (controls.BACK) {
			openProgressPrompt(false); 
			FlxG.sound.play(Paths.sound('menu/cancelMenu')); 
			if (cancelCallback == null) return;

			cancelCallback();
			cancelCallback == null;
		}
		if (controls.LEFT_P || controls.RIGHT_P) {FlxG.sound.play(Paths.sound("menu/scrollMenu")); onYes = !onYes;}
		if (controls.ACCEPT) {
			if(onYes){
				if(acceptedCallback != null)
					acceptedCallback();
			}
			else{
				if(finishedCallback != null)
					finishedCallback();
			}
			openProgressPrompt(false);
			FlxG.sound.play(Paths.sound("menu/confirmMenu"));
		}
		handleProgressPrompt();
		return;
	}

	if (controls.BACK) {
		var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound("menu/cancelMenu")); sound.volume = 1; sound.play();
		FlxG.switchState(new TitleState());
	}
	if (controls.DOWN_P) changeItem(1);
	if (controls.UP_P) changeItem(-1);
	if (controls.ACCEPT) {
		if(options[curSelected] == "story_mode"){
			checkWeekProgress();}
		else{goToItem();}
		
	}


	/*if(FlxG.keys.justPressed.SHIFT) {
		loadCheckpoint(FlxG.save.data.gorePoint);
	}*/
}

var bgTween:FlxTween;

override function closeSubState() {
		super.closeSubState();
		removeVirtualPad();
		addVirtualPad('UP_DOWN', 'A_B_M_E');
}

override function beatHit(curBeat:Int) {
	super.beatHit(curBeat);
	logoBl.animation.play('bump',true);

	if (curBeat % 2 == 0)
		gorefield.animation.play('beat',true);
}

override function destroy() {
  super.destroy();
	FlxG.camera.bgColor = FlxColor.fromRGB(0,0,0);curMainMenuSelected = curSelected;

}
}
typedef WeekSong1 = {
	var name:String;
	var hide:Bool;
}
