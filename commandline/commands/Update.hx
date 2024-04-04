package commands;

import haxe.xml.Access;
import haxe.Json;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class Update {
	public static function main(args:Array<String>) {
		prettyPrint("Preparing installation...");

		// to prevent messing with currently installed libs
		if (!FileSystem.exists('.haxelib'))
			FileSystem.createDirectory('.haxelib');

		var libs:Array<Library> = [];
		var libsXML:Access = new Access(Xml.parse(File.getContent('./libs.xml')).firstElement());

		for (libNode in libsXML.elements) {
			var lib:Library = {
				name: libNode.att.name,
				type: libNode.name
			};
			if (libNode.has.global) lib.global = libNode.att.global;
			switch (lib.type) {
				case "lib":
					if (libNode.has.version) lib.version = libNode.att.version;
				case "git":
					if (libNode.has.url) lib.url = libNode.att.url;
					if (libNode.has.ref) lib.ref = libNode.att.ref;
			}
			libs.push(lib);
		}

		for(lib in libs) {
			var globalism:Null<String> = lib.global == "true" ? "--global" : null;
			switch(lib.type) {
				case "lib":
					prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}"...');
					Sys.command('haxelib install ${lib.name} ${lib.version != null ? " " + lib.version : " "}${globalism != null ? ' $globalism' : ''} --always');
				case "git":
					prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}" from git url "${lib.url}"');
					Sys.command('haxelib git ${lib.name} ${lib.url}${lib.ref != null ? ' ${lib.ref}' : ''}${globalism != null ? ' $globalism' : ''} --always');
				default:
					prettyPrint('Cannot resolve library of type "${lib.type}"');
			}
		}

		var proc = new Process('haxe --version');
		proc.exitCode(true);
		var haxeVer = proc.stdout.readLine();
		if (haxeVer != "4.2.5") {
			// check for outdated haxe
			var curHaxeVer = [for(v in haxeVer.split(".")) Std.parseInt(v)];
			var requiredHaxeVer = [4, 2, 5];
			for(i in 0...requiredHaxeVer.length) {
				if (curHaxeVer[i] < requiredHaxeVer[i]) {
					prettyPrint("!! WARNING !!");
					Sys.println("Your current Haxe version is outdated.");
					Sys.println('You\'re using ${haxeVer}, while the required version is 4.2.5.');
					Sys.println('The engine may not compile with your current version of Haxe.');
					Sys.println('We recommend upgrading to 4.2.5');
					break;
				} else if (curHaxeVer[i] > requiredHaxeVer[i]) {
					prettyPrint("!! WARNING !!"
					+ "\nUsing Haxe 4.3.0 and above is currently not recommended due to lack of testing.");
					Sys.println('');
					Sys.println('We recommend downgrading back to 4.2.5.');
					break;
				}
			}
		}
	}

	public static function prettyPrint(text:String) {
		var lines = text.split("\n");
		var length = -1;
		for(line in lines)
			if(line.length > length)
				length = line.length;
		var header = "══════";
		for(i in 0...length)
			header += "═";
		Sys.println("");
		Sys.println('╔$header╗');
		for(line in lines) {
			Sys.println('║   ${centerText(line, length)}   ║');
		}
		Sys.println('╚$header╝');
	}


	public static function centerText(text:String, width:Int):String {
		var centerOffset = (width - text.length) / 2;
		var left = repeat(' ', Math.floor(centerOffset));
		var right = repeat(' ', Math.ceil(centerOffset));
		return left + text + right;
	}

	public static inline function repeat(ch:String, amt:Int) {
		var str = "";
		for(i in 0...amt)
			str += ch;
		return str;
	}
}

typedef Library = {
	var name:String;
	var type:String;
	var ?global:String;
	var ?version:String;
	var ?ref:String;
	var ?url:String;
}