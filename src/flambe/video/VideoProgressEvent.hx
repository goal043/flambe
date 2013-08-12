//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.video;

import flambe.video.VideoView;

/**
 * Represents an event coming from a VideoView with information on the natural size of the encoded video
 * as well as the width and height.
 */
class VideoProgressEvent
{
    /**
     * The X position of the pointing device, in view (stage) coordinates.
     */
    public var buffered (default, null) :Array<VideoTimeRange>;

    public var currentTime (default, null) :Float;

    /**
     * The source that this event originated from. This can be used to determine if the event came
     * from a mouse or a touch.
     */
    public var source (default, null) :VideoView;

    /** @private */ public function new ()
    {
        _internal_init(null, 0, null);
    }

    /** @private */ public function _internal_init (
        buffered :Array<VideoTimeRange>, currentTime :Float, source :VideoView)
    {
        this.buffered = buffered;
        this.currentTime = currentTime;
        this.source = source;
    }
}
