//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.html;

import flambe.asset.AssetEntry;
import flambe.util.Signal0;
import js.html.SourceElement;
import js.html.VideoElement;
import js.Lib;
import js.Browser;

import flambe.animation.AnimatedFloat;
import flambe.asset.Manifest;
import flambe.platform.html.HtmlUtil;
import flambe.util.Signal1;
import flambe.util.Signal2;
import flambe.util.Value;
import flambe.subsystem.VideoSystem;
import flambe.video.VideoMetaEvent;
import flambe.video.VideoProgressEvent;
import flambe.video.VideoView;

using Lambda;

class HtmlVideo
    implements VideoSystem
{
    public var supported (get_supported, null) :Bool;
    public var userActionRequired (get_userActionRequired, null) :Bool;

    /** The supported mime types for the browser */
    public static var supportedTypes :Array<AssetFormat>;

    public function new (container :Dynamic)
    {
        _container = container;

        // User action required on mobile safari only.
        var ua:String = Browser.navigator.userAgent.toLowerCase();
        _userActionRequired = (ua.indexOf("safari") > -1) && (ua.indexOf("mobile") > -1);
        
        var vid = Browser.document.createElement("video");
        var types = [
            { format: WEBM, mimeType: 'video/webm; codecs="vp8, vorbis"' },
            { format: MP4, mimeType: 'video/mp4; codecs="avc1.42E01E, mp4a.40.2"' },
            { format: OGV, mimeType: 'video/ogg; codecs="theora"' },
        ];

        var result = [];
        for (type in types) {
            // IE9's canPlayType() will throw an error in some rare cases:
            // https://github.com/Modernizr/Modernizr/issues/224
            var canPlayType = "";
            try canPlayType = (untyped vid).canPlayType(type.mimeType)
            catch (_ :Dynamic) {}

            if (canPlayType != "") {
                result.push(type.format);
            }
        }
        supportedTypes = result;

    }

    public function get_supported () :Bool
    {
        return true;
    }

    public function get_userActionRequired () :Bool
    {
        return _userActionRequired;
    }

    public function createView (x :Float, y :Float, width :Float, height :Float, ?backgroundColor :Null<Int> = null) :VideoView
    {
        var video :VideoElement = Browser.document.createVideoElement();
        video.style.position = "absolute";
        video.style.border = "0";
        if (backgroundColor != null) {
            video.style.backgroundColor = "#" + StringTools.hex(backgroundColor, 6);
        }

        video.preload = "auto";
        video.autoplay = _userActionRequired;
        video.controls = _userActionRequired;

        var view = new HtmlVideoView(video, x, y, width, height);
        _container.appendChild(video);

        HtmlPlatform.instance.mainLoop.addTickable(view);
        return view;
    }

    private var _container :Dynamic;
    private var _userActionRequired :Bool;
}

class HtmlVideoView
    implements VideoView
    implements Tickable
{
    public var error (default, null) :Signal1<String>;
    public var stateChanged (default, null) :Signal2<VideoState, VideoState>;
    public var state (default, null) :VideoState;
    public var progress (default, null) :Signal1<VideoProgressEvent>;
    public var ready (default, null) :Signal0;
    public var completed (default, null) :Signal0;
    public var x (default, null) :AnimatedFloat;
    public var y (default, null) :AnimatedFloat;
    public var width (default, null) :AnimatedFloat;
    public var height (default, null) :AnimatedFloat;
    public var volume (default, null) :AnimatedFloat;
    public var duration (default, null) :Float;
    public var currentTime (get, null) :Float;
    public var loop (default, null) :Value<Bool>;
    public var videoWidth (get_videoWidth, null) :Float;
    public var videoHeight (get_videoHeight, null) :Float;

    // public var buffered (default, null) :Array<VideoTimeRange>;

    public var video (default, null) :VideoElement;

    public function new (video :VideoElement, x :Float, y :Float, width :Float, height :Float)
    {
        this.video = video;

        var onBoundsChanged = function (_,_) updateBounds();
        this.x = new AnimatedFloat(x, onBoundsChanged);
        this.y = new AnimatedFloat(y, onBoundsChanged);
        this.width = new AnimatedFloat(width, onBoundsChanged);
        this.height = new AnimatedFloat(height, onBoundsChanged);
        this.volume = new AnimatedFloat(1);

        updateBounds();

        stateChanged = new Signal2();
        progress = new Signal1();
        completed = new Signal0();
        ready = new Signal0();

        loop = new Value<Bool>(false, function(v,_){
            if (this.video != null) {
                this.video.loop = v;
            }
        });
        error = new Signal1();

        video.addEventListener("durationchange", onEvent);
        video.addEventListener("progress", onEvent);

        // video.addEventListener("play", onEvent);
        video.addEventListener("timeupdate", onEvent);
        video.addEventListener("loadedmetadata", onEvent);
        video.addEventListener("playing", onEvent);
        video.addEventListener("canplay", onEvent);
        video.addEventListener("pause", onEvent);
        video.addEventListener("waiting", onEvent);
        video.addEventListener("ended", onEvent);
    }

    public function seek(time:Float) :VideoView {
        _seekTime = time;
        if (_loaded && _metaLoaded) {
            video.currentTime = _seekTime;
            if (video.paused) {
                video.play();
            }
        }
        return this;
    }

    public function load (url :String, extensions :Array<String>) :VideoView {

        var m:Manifest = new Manifest();
        for (i in 0...extensions.length) {
            var format:AssetFormat = null;
            switch (extensions[i].toLowerCase()) {
                case "mp4", "m4v", "f4v":
                format = AssetFormat.MP4;
                case "ogv", "ogg":
                format = AssetFormat.OGV;
                case "webm":
                format = AssetFormat.WEBM;
            }
            if (format != null) {
                m.add("", url + "." + extensions[i], format);
            }
        }

        return loadFromManifest(m);
    }

    public function loadFromManifest (manifest :Manifest) :VideoView {
        clear();

        for (node in video.childNodes) {
            video.removeChild(node);
        }

        var i:Iterator<AssetEntry> = manifest.iterator();
        for (entry in i) {
            if (HtmlVideo.supportedTypes.indexOf(entry.format) > -1) {
                var source :SourceElement = Browser.document.createSourceElement();
                source.src = entry.url;
                video.appendChild(source);
            }
        }
        video.load();
        setState(VideoState.loading);

        return this;
    }

    public function play() :VideoView {
        if (_paused) {
            video.autoplay = true;
            if (_loaded) {
                video.play();
            }
            _paused = false;
        }
        return this;
    }

    public function pause() :VideoView {
        if (!_paused) {
            video.autoplay = false;

            if (_loaded) {
                video.pause();
            }

            _paused = true;
        }
        return this;
    }

    private function get_videoWidth () :Float {
        return video != null && _metaLoaded ? video.videoWidth : 0;
    }

    private function get_videoHeight () :Float {
        return video != null && _metaLoaded ? video.videoHeight : 0;
    }

    private function get_currentTime() :Float 
    {
        return _metaLoaded ? video.currentTime : 0;
    }

    public function dispose ()
    {
        if (video == null) {
            return; // Already disposed
        }

        video.removeEventListener("progress", onEvent);
        video.removeEventListener("timeupdate", onEvent);
        video.removeEventListener("loadedmetadata", onEvent);
        video.removeEventListener("playing", onEvent);
        video.removeEventListener("canplay", onEvent);
        video.removeEventListener("pause", onEvent);
        video.removeEventListener("waiting", onEvent);
        video.removeEventListener("ended", onEvent);

        state = null;
        video.parentNode.removeChild(video);
        video = null;
    }

    public function update (dt :Float) :Bool
    {
        x.update(dt);
        y.update(dt);
        width.update(dt);
        height.update(dt);
        volume.update(dt);
        if (video != null) {
            video.volume = System.volume._ * volume._;
        }
        return (video == null);
    }

    private function onEvent(e):Void  {
        
        switch (e.type) {
            case "timeupdate":
                sendProgress();

            case "progress":
                sendProgress();

            case "loadedmetadata":
                _metaLoaded = true;
                duration = video.duration;
                setReady();
            case "canplay":
                _loaded = true;
                setReady();
            // case "play":

            case "playing":
                _paused = false;
                setState(VideoState.playing);

            case "waiting":
                setState(VideoState.buffering);

            case "pause":
                _paused = true;
                setState(VideoState.paused);

            case "ended":
                _seekTime = 0;
                setState(VideoState.completed);
                completed.emit();
        }
    }

    /**
     * Sends the progress and prebuffer events.
     * @return [description]
     */
    private function sendProgress()
    {
        var progressEvent :VideoProgressEvent = new VideoProgressEvent();
        var timeRanges :Array<VideoTimeRange> = [];
        for (i in 0...video.buffered.length) {
            timeRanges.push({ start:video.buffered.start(i), end:video.buffered.end(i) });
        }

        progressEvent.init(timeRanges, video.currentTime, this);
        progress.emit(progressEvent);
    }

    /**
     * Clears out listeners and resets player values.
     * @return [description]
     */
    private function clear():Void {
        _paused = true;
        _loaded = _metaLoaded = false;
        duration = 0;
    }

    private function updateBounds ()
    {
        if (video == null) {
            return; // Already disposed
        }
        video.style.left = x._ + "px";
        video.style.top = y._ + "px";
        video.width = Math.round(width._);
        video.height = Math.round(height._);
    }

    private function setReady () {
        
        if (_metaLoaded && _loaded) {

            if (_seekTime > 0) {
                video.currentTime = _seekTime;
                _seekTime = 0;
                play();
            }

            setState(VideoState.ready);
            ready.emit();
        }
    }

    private function setState(state:VideoState) {
        if(this.state != state) {
            var old:VideoState = this.state;
            this.state = state;
            stateChanged.emit(this.state, old);
        }
    }

    private var _paused :Bool = true;
    private var _loaded :Bool = false;
    private var _seekTime :Float = 0;
    private var _metaLoaded :Bool = false;

}