AIRFileSave
===========

Ever wanted to dynamically write local files from a Flash game/app at runtime (without server-side scripts)? This handy AIR app can serve as a 3rd-arm for your Flash projects that needs to dynamically update JSON, TXT, or even ByteArray files. Also useful for launching NativeProcess (batch, commands, etc.)

----------------------

It's true, there already exists a way of saving files from a Flash app by prompting a FileReference dialog, letting the user pick a path / filename and saving the bytearray to the user's system.

But what if you're working on a personal project? What if you're adjusting certain values in an XML or JSON file to tweak your game's flow? What if you're calibrating the scroll speed of your UI menus? Are you going to constantly go back and forth between editing and compiling your project until you get it right?


A Different Approach
----------------------
Since you probably know the path to the configuration/levels files of your game and/or app, why not integrate some kind of **auto-save** in your project?

The way this works - AIRFileSave is an AIR app that uses a LocalConnection approach to "listen" to the client (your game/app) to initiate any file writing / reading / directory-listing commands.

![How it works](https://raw.githubusercontent.com/bigp/AIRFileSave/master/images/afs_how_it_works.png)

You ask: "**If this is using LocalConnections, do I need to setup the client LocalConnection to communicate with the AIR app?**" - No worries! You don't have to setup a bunch of cumbersome LocalConnection details yourself in your project! This is handled for you in the client SWC, which you can create from the AIR app directly:

![How it works](https://raw.githubusercontent.com/bigp/AIRFileSave/master/images/afs_how_it_looks.png)

------------------------------

Usage of Client SWC
=============

    //Instantiating a new Client automatically connects to the AIR app.
    var theClient:AIRFileSaveClient = new AIRFileSaveClient();
    
    //Save a plain text file:
    theClient.saveText("myFileName.txt", "Hello World.");
    
    //Save a byte-array file:
    theClient.saveBytes("myDataFile.bin", theByteArray);
    
    //List a Directory:
    theClient.listDirectory("C:/Temp/", function( pFileNames:Array ):void {
        trace(pFileNames);
    }
    
    //Create / Remove:
    theClient.createDirectory("theDirName", onDirCreated);
    theClient.deleteDirectory("theDirName", onDirDeleted);
    theClient.deleteFile("theFile.txt", onFileDeleted);
    
    //Last but not least, here's a way to call a command (Batch) file: (not fully implemented yet)
    theClient.startCommand( "theCommand.bat", ["Hello", "World"], onCommandCompleted);
