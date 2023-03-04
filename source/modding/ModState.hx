package modding;

import haxe.Json;
import modding.ModIcon;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class ModState extends MusicBeatState
{
    var selected_mods:Array<String> = [];
    var total_mods:Array<String> = [];

    var mod_metadata:Map<String, polymod.Polymod.ModMetadata> = [];

    var mod_alphabets:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();

    var selected:Int = 0;

    var funnyInfo:FlxText;
	var descBg:FlxSprite;

    override function create()
    {
        var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

        selected_mods = FlxG.save.data.mods;

        #if sys
        for(dir in sys.FileSystem.readDirectory(Sys.getCwd() + "mods"))
        {
            if(sys.FileSystem.exists(Sys.getCwd() + "mods/" + dir + "/mod.json"))
            {
                total_mods.push(dir);

                #if sys
                mod_metadata.set(dir, polymod.Polymod.ModMetadata.fromJsonStr(sys.io.File.getContent(Sys.getCwd() + "mods/" + dir + "/mod.json")));
                #end
            }
        }
        #end

        add(mod_alphabets);

        for(mod in total_mods)
        {
            var new_alpha = new Alphabet(0, 0, mod, true);
            new_alpha.isMenuItem = true;
            new_alpha.targetY = total_mods.indexOf(mod);

            if(!selected_mods.contains(mod))
                new_alpha.alpha = 0.6;

            mod_alphabets.add(new_alpha);
        }

        for(mod in selected_mods)
        {
            if(!total_mods.contains(mod))
            {
                var new_alpha = new Alphabet(0, 0, "(BROKEN)-" + mod, true);
                new_alpha.isMenuItem = true;
                new_alpha.targetY = total_mods.length + selected_mods.indexOf(mod);
                new_alpha.color = FlxColor.RED;
                mod_alphabets.add(new_alpha);
            }
        }

		descBg = new FlxSprite(0, FlxG.height - 90).makeGraphic(FlxG.width, 90, 0xFF000000);
		descBg.alpha = 0.6;
		add(descBg);

		funnyInfo = new FlxText(descBg.x, descBg.y + 4, FlxG.width, "Template Description", 18);
		funnyInfo.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		funnyInfo.borderColor = FlxColor.BLACK;
		funnyInfo.borderSize = 1;
		funnyInfo.borderStyle = OUTLINE;
		funnyInfo.scrollFactor.set();
		funnyInfo.screenCenter(X);
        add(funnyInfo);

		var leText:String = "Press ENTER to enable / disable the currently selected mod / Press SHIFT to open homepage.";

		var text:FlxText = new FlxText(-150, FlxG.height - 22, FlxG.width, leText, 16);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		text.borderColor = FlxColor.BLACK;
		text.borderSize = 1;
		text.borderStyle = OUTLINE;
		add(text);

        changeItem(0);

		super.create();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(controls.UP_P)
            changeItem(-1);
        if(controls.DOWN_P)
            changeItem(1);

        if(controls.BACK)
        {
            FlxG.switchState(new MainMenuState());

            #if sys
            FlxG.save.data.mods = selected_mods;
            FlxG.save.flush();

            TitleState.reloadMods();
            #end
        }

        if(controls.ACCEPT)
        {
            if(selected_mods.contains(total_mods[selected]))
                selected_mods.remove(total_mods[selected]);
            else
                selected_mods.push(total_mods[selected]);

            updateAlphabets();
        }

        if(controls.RESET)
        {
            selected_mods = [];
            updateAlphabets();

            FlxG.save.data.mods = selected_mods;
            FlxG.save.flush();

            for(alpha in mod_alphabets.members)
            {
                if(alpha.color == FlxColor.RED) // removes broken shit anyways, so u good :D
                    mod_alphabets.remove(alpha);
            }
        }

        if(FlxG.keys.justPressed.SHIFT)
        {
            if(mod_metadata.exists(total_mods[selected]))
                fancyOpenURL(mod_metadata.get(total_mods[selected]).homepage);
        }
    }

    function changeItem(amount:Int = 0)
    {
        selected += amount;

        if(selected < 0)
            selected = mod_alphabets.members.length - 1;
        if(selected > mod_alphabets.members.length - 1)
            selected = 0;

        updateAlphabets();

        FlxG.sound.play(Paths.sound("scrollMenu"));

        if(mod_metadata.exists(total_mods[selected]))
        {
            var data:polymod.Polymod.ModMetadata = mod_metadata.get(total_mods[selected]);

            var contribs = "";

            for(contributor in data.contributors)
            {
                if(data.contributors.indexOf(contributor) != data.contributors.length - 1)
                    contribs += contributor.name + " - " + contributor.role + " | ";
                else
                    contribs += contributor.name + " - " + contributor.role;
            }

			funnyInfo.screenCenter(X);

            funnyInfo.text = (
                data.title + " - " +
                data.description + "\nHomepage: " +
                data.homepage + "\nDevs: " + contribs + 
                "\nv" + data.modVersion + " using " + data.license + " as it's license."
            );
        }
    }

    function updateAlphabets()
    {
        for(i in 0...mod_alphabets.members.length)
        {
            var text = mod_alphabets.members[i];

            text.targetY = i - selected;

            if(selected_mods.contains(total_mods[i]))
                text.alpha = 1;
            else
                text.alpha = 0.6;
        }
    }
}