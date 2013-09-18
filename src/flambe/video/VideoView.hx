//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.video;

import flambe.animation.AnimatedFloat;
import flambe.asset.Manifest;
import flambe.util.Disposable;
import flambe.util.Signal1;
import flambe.util.Signal2;
import flambe.util.Signal0;
import flambe.util.Value;
import flambe.video.VideoMetaEvent;

enum VideoState {
    /** Defines all of the states the video can be in. */
    loading; ready; paused; playing; seeking; buffering; completed;
}

typedef VideoTimeRange = {
    var start : Float;
    var end : Float;
}

/**
 * Displays a video over the stage. 
 */
interface VideoView
    extends Disposable
{

    /**
     * An error message emitted if the video could not be loaded.
     */
    var error (default, null) :Signal1<String>;

    /**
     * The video state emitted as well as the previous state the video was in.
     */
    var stateChanged (default, null) :Signal2<VideoState, VideoState>;

    /**
     * The state the video is currently in.
     */
    var state (default, null) :VideoState;

    /**
     * emits the current position of the playhead as well as the prebuffered ranges.
     */
    var progress (default, null) :Signal1<VideoProgressEvent>;

    /**
     * Emitted when the video is ready to start playback.
     * nativeWidth() and nativeHeight() and duration of the video are also available at this time.
     */
    var ready (default, null) :Signal0;

    /**
     * Emitted when the video playback has finished playing successfully.s
     */
    var completed (default, null) :Signal0;

    /**
     * Viewport X position, in pixels.
     */
    var x (default, null) :AnimatedFloat;

    /**
     * Viewport Y position, in pixels.
     */
    var y (default, null) :AnimatedFloat;

    /**
     * Viewport width, in pixels.
     */
    var width (default, null) :AnimatedFloat;

    /**
     * Viewport height, in pixels.
     */
    var height (default, null) :AnimatedFloat;

    /**
     * The volume of the playback.
     */
    var volume (default, null) :AnimatedFloat;

    /**
     * The duration of the loaded video in seconds.
     */
    var duration (default, null) :Float;

    /**
     * The width of the loaded video. This will return 0 until the loaded video reaches the 'ready' state.
     */
    var videoWidth (get_videoWidth, null) :Float;
    /**
     * The width of the loaded video. This will return 0 until the loaded video reaches the 'ready' state.
     */
    var videoHeight (get_videoHeight, null) :Float;

    /**
     * The current time the playhead is at.
     * To seek to a different position, 
     */
    var currentTime (default, null) :Float;

    /**
     * The looping behavior of the video.
     */
    var loop (default, null) :Value<Bool>;

    /**
     * The array of VideoTimeRanges that have been buffered.
     */
     // var buffered (default, null) :Array<VideoTimeRange>;

    /**
     * Seeks to the given time and begins playing back the video.
     * @param  time The time in seconds to seek to.
     * @return      The instance of the VideoView.
     */
    function seek(time:Float) :VideoView;

    /**
     * Loads a new video from the given URL. 
     * 
     * @param   url The url to load from, omitting the file extension.
     * @param   extensions  An array of available extensions for this video.
     * Flambe will pick the best one based on platform support.
     *
     */
    function load (url :String, extensions :Array<String>) :VideoView;

    /**
     * Loads a single video from a manifest.
     * This is used if you need to specify multiple URLs with different file names, or 
     * if your file extensions don't match the standard convention (i.e. Something server generated)
     * 
     * @param  manifest     The object manifest to use.
     */
    function loadFromManifest (manifest :Manifest) :VideoView;

    /**
     * Begins playing the video. If the video has not yet buffered where the playhead is at,
     * the video will begin playback as soon as it is ready.
     * Connect to the stateChanged signal for VideoState.playing to find out
     * when the playback has actually started.
     * 
     * @return [description]
     */
    function play() :VideoView;

    /**
     * Pauses the video playback.
     */
    function pause() :VideoView;

}
