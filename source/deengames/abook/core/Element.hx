package deengames.abook.core;

import deengames.abook.core.onClickCommands.ShowScreenCommand;
import deengames.abook.debug.DebugLogger;
import deengames.abook.io.SingletonAudioPlayer;
using deengames.extensions.StringExtensions;

import flixel.addons.display.FlxExtendedSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.system.FlxSound;
import flixel.util.FlxSort;

using StringTools;

/**
A basic interactive element, it displays a static image (or the first frame of
an animation). When you click on it, it starts an animation (optional), and plays
an audio file (optional).
**/
class Element extends FlxExtendedSprite
{

  public var animationFile(default, null) : String;
  public var imageFile(default, null) : String;
  public var scaleTo(default, null):Float = 1.0;
  public var z(default, null):Int = 0;
  
  private var clickAudioFile(default, null) : String;
  private var clickAudioSound:FlxSound;
    
  // TODO: a generic interface with .execute() works here too
  private var onClickCommand:ShowScreenCommand;

  public function new(json:Dynamic = null)
  {
    super();
    FlxMouseEventManager.add(this, clickHandler);
  }

  // e is normally an instance of Element. Unless you want to use a custom class.
  public static function populateFromData(data:Dynamic, e:Dynamic):Void
  {      
    if (data.scale != null)
    {
        e.scaleTo = data.scale;
    }
    
    if (data.image != null)
    {
      e.setImage('assets/images/${data.image}');
    }

    if (data.x != null && data.y != null) {
      var x:Int = data.x;
      var y:Int = data.y;

      if (data.placement != null) {
        var placement:String = data.placement;
        var normalized = placement.replace("-", "").replace(" ", "").toLowerCase();
        if (normalized != "topleft" && normalized != "topright" && normalized != "bottomleft" && normalized != "bottomright") {
          DebugLogger.log('Invalid placement value of ${placement}. Valid values are: top-left, top-right, bottom-left, bottom-right.');
        } else {
          if (placement.indexOf('bottom') > -1) {
            y = Main.gameHeight - Math.round(e.height) - y;
          }
          if (placement.indexOf('right') > -1) {
            x = Main.gameWidth - Math.round(e.width) - x;
          }
        }
      }

      e.x = x;
      e.y = y;
    } else if (data.placement != null) {
      DebugLogger.log("Element has placement but no x/y coordinates; please add them: " + data);
    }
    
    if (data.z != null)
    {
        e.z = data.z;
    }
    else
    {
        e.z = 0;
    }

    if (data.animation != null)
    {
      var a = data.animation;
      e.setAnimation('assets/images/${a.image}', a.width, a.height, a.frames, a.fps);
    }
    
    if (data.clickAudio != null)
    {
      e.setClickAudio('assets/audio/${data.clickAudio}');
    }

    if (data.onClick != null) {
      var onClick:String = data.onClick;
      // validation
      var normalized = onClick.toLowerCase();
      if (normalized.indexOf('show(') != 0 || normalized.indexOf(')') != normalized.length - 1)
      {
        throw 'Element ${data} has invalid on-click code: ${onClick}. Valid values are: show(screen name)';
      }
      else
      {
        var start = normalized.indexOf('(');
        var stop = normalized.indexOf(')');
        var screenName = onClick.substr(start + 1, stop - start - 1);

        var screenFound = null;
        for (screenData in Screen.screensData)
        {
          if (screenData.name.toLowerCase() == screenName.toLowerCase())
          {
            screenFound = screenData;
          }
        }
        if (screenFound == null)
        {
          throw 'Element ${data} has onClick handler pointing to non-existing screen ${screenName}';
        }
        else
        {
          if (data.animation != null)
          {
            DebugLogger.log('Warning: Element has an animation which will be overridden by the click handler. click=${onClick}, a=${data.animation}, e=${data}');
          }
          e.onClickCommand = new ShowScreenCommand(screenFound);
        }
      }
    }
  }


  public function setImage(imageFile:String) : Void
  {
    this.imageFile = imageFile.addExtension();
    this.loadGraphic(this.imageFile);
    this.scaleIfRequired();
  }

  /**
  Don't use this with withImage. It overrides the image from withImage. Note that
  the animation resets to the first frame after completion, and restarts on click.
  */
  public function setAnimation(spriteSheet:String, width:Int, height:Int, frames:Int, fps:Int, resetOnCompletion:Bool = true) : Void
  {
    spriteSheet = spriteSheet.addExtension();
    this.animationFile = spriteSheet;
    this.loadGraphic(spriteSheet, true, width, height);
    var range = [for (i in 0 ... frames) i];
    if (resetOnCompletion)
    {
        range.push(0); // reset to first image on completion
    }
    this.animation.add('main', range, fps, false); // false => no loop
    this.scaleIfRequired();
  }

  /**
  Play an animation on click. Note that the audio restarts on click.
  */
  public function setClickAudio(fileName:String) : Void
  {
    this.clickAudioFile = fileName;
    this.clickAudioSound = FlxG.sound.load(this.clickAudioFile + deengames.io.AudioManager.SOUND_EXT);
  }
  
  /**
  Centralizes logic that executes on click.
  */
  public function clickHandler(obj:FlxObject) : Void
  {
    if (this.clickAudioSound != null) {
      // Stop the current screen audio if it's going
      SingletonAudioPlayer.play(this.clickAudioSound);
    }

    if (this.onClickCommand != null) {
      this.onClickCommand.execute();
    } else {
      if (this.animation != null) {
        this.animation.pause();
        this.animation.play('main', true); // force restart
      }
    }
  }
  
  public function setAudioPitch(pitch:Float):Void
  {
      if (this.clickAudioSound == null)
      {
          throw "Element doesn't have audio!";
      }
      
      this.clickAudioSound.pitch = pitch;
  }
  
  /**
  Called after the object is initialized and fully created. Override it.
  */
  public function create():Void
  {
  }
  
  private function scaleIfRequired():Void
  {
      // Image/animation set; scale (proportionally)
      // Don't use FlxSprite.scale, because performance
      // sucks on Flash. (up to 10x slower!)
      if (this.scaleTo != 1.0)
      {
          this.setGraphicSize(Math.round(this.width * this.scaleTo), 0);
      }
  }
}
