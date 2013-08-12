//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform;

import flambe.util.Assert;
import flambe.subsystem.VideoSystem;
import flambe.video.VideoView;

class DummyVideo
    implements VideoSystem
{

    public var supported (get_supported, null) :Bool;
    public var userActionRequired (get_userActionRequired, null) :Bool;

    public function new ()
    {
    }

    public function get_supported ()
    {
        return false;
    }

    public function get_userActionRequired () 
    {
        return true;
    }

    public function createView (x :Float, y :Float, width :Float, height :Float, ?backgroundColor :Null<Int>) :VideoView
    {
        Assert.fail("Video.createView is unsupported in this environment, check the `supported` flag.");
        return null;
    }
}
