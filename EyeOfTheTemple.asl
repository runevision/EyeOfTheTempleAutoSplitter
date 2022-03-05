/*
Autosplitter for Eye of the Temple

Note, this autosplitter requires ULibrary.bin to be in the Livesplit Components folder. Get it here:
https://github.com/just-ero/AutoSplitHelp/blob/main/libraries/ULibrary.bin

// Here is the class in the game that autosplitting can detect and read from.
public class AutoSplitterData {
    // In-game timer.
    public static double inGameTime = 0d;

    // Set to 1 when an attempt is started (when the in-game time starts).
    // Set to 2 when the game ended (when the in-game time is finally stopped).
    // Set to 0 when the user quits the current game or run.
    public static int isRunning = 0;

    // This updates when the player enters an area.
    //  0 Shallow Waters
    //  1 Gateway Trials
    //  2 The Atrium
    //  3 Monument Square
    //  4 Eastern Lookout
    //  5 East Passage
    //  6 Creaking Gorge
    //  7 The Cauldron
    //  8 Fiery Pass
    //  9 Black Sanctum
    // 10 The Wall
    // 11 Creepstone Mine
    // 12 The Outpost
    // 13 Watergrave Arena
    // 14 Dark Ruins
    // 15 Forbidden Tower
    public static int currentAreaID = 0;

    // This updates when the player enters a new area not previously visited.
    // Revisiting an already visited area won't change the id.
    public static int latestNewAreaID = 0;
}
*/

state("EyeOfTheTemple") { }

startup
{
    vars.Log = (Action<object>)(output => print("[EyeOfTheTemple] " + output));
    vars.Unity = Activator.CreateInstance(Assembly.LoadFrom(@"Components\UnityASL.bin").GetType("UnityASL.Unity"));

    settings.Add("levelSplits", false, "Split when reaching a new area");

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "Eye of the Temple is timed based on game time, so it's recommended to switch to that.\nWould you like to switch to game time?",
            "Eye of the Temple Autosplitter",
            MessageBoxButtons.YesNo);

        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

init
{
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
    {
        var autoSplitterData = helper.GetClass("Assembly-CSharp", "AutoSplitterData");

        vars.Unity.Make<double>(autoSplitterData.Static, autoSplitterData["inGameTime"]).Name = "inGameTime";
        vars.Unity.Make<int>(autoSplitterData.Static, autoSplitterData["isRunning"]).Name = "isRunning";
        vars.Unity.Make<int>(autoSplitterData.Static, autoSplitterData["latestNewAreaID"]).Name = "latestNewAreaID";

        return true;
    });

    vars.Unity.Load(game);
}

update
{
    if (!vars.Unity.Loaded)
        return false;
    
    vars.Unity.Update();

    current.inGameTime = vars.Unity["inGameTime"].Current;
    current.isRunning = vars.Unity["isRunning"].Current;
    current.latestNewAreaID = vars.Unity["latestNewAreaID"].Current;
}

isLoading
{
    return true;
}

start
{
    return (old.isRunning != current.isRunning) && current.isRunning == 1;
}

split
{
    // Split when the run is over.
    if (old.isRunning == 1 && current.isRunning == 2)
        return true;
    
    // Split each time you reach a new area in the game.
    if (old.latestNewAreaID != current.latestNewAreaID)
        return settings["levelSplits"];
}

gameTime
{
    return TimeSpan.FromSeconds(current.inGameTime);
}

reset
{
    return old.isRunning == 1 && current.isRunning == 0;
}

exit
{
    vars.Unity.Reset();
}

shutdown
{
    vars.Unity.Reset();
}
