package deengames.io;

using sys.io.FileOutput;

/**
Logs debug messages. Only if debug mode is enabled, though.
You can enable debug mode by passing "-D debug" to the Haxe compiler.
If you're using Lime, OpenFL, HaxeFlixel, etc. you can do it by editing your
project XML file and specifying <haxedef name="debug" />
*/
// Static class
class DebugLogger
{
  private static inline var LOG_FILE_NAME:String = "debug.log";

  private static var firstMessage:Bool = true;
  public static function log(message:String) : Void
  {
    message = '${Date.now()}|${message}';

    #if debug
      trace(message);
    #end

    #if neko
      if (firstMessage && sys.FileSystem.exists(LOG_FILE_NAME)) {
        firstMessage = false;
        sys.FileSystem.deleteFile(LOG_FILE_NAME);
      }

      // Append to log file
      var fileOut:FileOutput = sys.io.File.append(LOG_FILE_NAME, false);
      fileOut.writeString('${message}\n');
      fileOut.close();
    #end
  }
}
