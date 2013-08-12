//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.subsystem;

import flambe.video.VideoView;

/**
 * Functions related to the environment's web browser.
 */
interface VideoSystem
{
    /**
     * True if the environment supports VideoViews.
     */
    var supported (get_supported, null) :Bool;

    /**
     * Indicates if video can only be initiated by clicking on the VideoView (i.e. Mobile Safari)
     */
    var userActionRequired (get_userActionRequired, null) :Bool;

    /**
     * Creates a blank VideoView with the given viewport bounds, in pixels. Fails with an assertion if
     * this environment doesn't support WebViews.
     */
    function createView (x :Float, y :Float, width :Float, height :Float, ?backgroundColor :Null<Int>) :VideoView;

}
