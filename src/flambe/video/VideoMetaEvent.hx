//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.video;

import flambe.video.VideoView;

/**
 * Represents an event coming from a VideoView with information on the natural size of the encoded video
 * as well as the width and height.
 */
class VideoMetaEvent
{
    /**
     * The X position of the pointing device, in view (stage) coordinates.
     */
    public var duration (default, null) :Float;

    /**
     * The Y position of the pointing device, in view (stage) coordinates.
     */
    public var naturalWidth (default, null) :Float;

    /**
     * The Y position of the pointing device, in view (stage) coordinates.
     */
    public var naturalHeight (default, null) :Float;

    /**
     * The source that this event originated from. This can be used to determine if the event came
     * from a mouse or a touch.
     */
    public var source (default, null) :VideoView;

    /** @private */ public function new ()
    {
        _internal_init(0, 0, 0, null);
    }

    /** @private */ public function _internal_init (
        duration :Float, naturalWidth :Float, naturalHeight :Float, source :VideoView)
    {
        this.duration = duration;
        this.naturalWidth = naturalWidth;
        this.naturalHeight = naturalHeight;
        this.source = source;
    }
}
