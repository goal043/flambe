//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.html;

import flambe.asset.AssetEntry;
import flambe.util.Signal0;
import js.Lib;

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
        var ua:String = Lib.window.navigator.userAgent.toLowerCase();
        _userActionRequired = (ua.indexOf("safari") > -1) && (ua.indexOf("mobile") > -1);
        
        var vid = Lib.document.createElement("video");
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

    public function createView (x :Float, y :Float, width :Float, height :Float) :VideoView
    {
        var video = Lib.document.createElement("video");
        video.style.position = "absolute";
        video.style.border = "0";
        (untyped video).preload = "auto";
        (untyped video).autoplay = _userActionRequired;
        (untyped video).controls = _userActionRequired;

        var view = new HtmlVideoView(video, x, y, width, height);
        _container.appendChild(video);

        HtmlPlatform.instance.mainLoop.addTickable(view);
        return view;
    }

    private var _container :Dynamic;
    private var _userActionRequired :Bool;
}

class HtmlVideoView
    implements VideoView,
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
    public var currentTime (default, null) :Float;
    public var loop (default, null) :Value<Bool>;
    public var videoWidth (get_videoWidth, null) :Float;
    public var videoHeight (get_videoHeight, null) :Float;

    // public var buffered (default, null) :Array<VideoTimeRange>;

    public var video (default, null) :Dynamic;

    public function new (video :Dynamic, x :Float, y :Float, width :Float, height :Float)
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

        // video.addEventListener("durationchange", onEvent);
        // video.addEventListener("play", onEvent);
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

        var i:Iterator<AssetEntry> = manifest.iterator();
        for (entry in i) {
            if (HtmlVideo.supportedTypes.indexOf(entry.format) > -1) {
                var source = Lib.document.createElement("source");
                (untyped source).src = entry.url;
                video.innerHtml = "";
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

    public function dispose ()
    {
        if (video == null) {
            return; // Already disposed
        }

        video.removeEventListener("loadedmetadata", onEvent);
        video.removeEventListener("playing", onEvent);
        video.removeEventListener("canplay", onEvent);
        video.removeEventListener("pause", onEvent);
        video.removeEventListener("waiting", onEvent);
        video.removeEventListener("ended", onEvent);

        _state = null;
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
            video.volume = volume._;
        }
        return (video == null);
    }

    private function onEvent(e):Void  {
        switch (e.type) {
            //case "durationchange":
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
        video.width = width._;
        video.height = height._;
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
        if(state != _state) {
            var old:VideoState = _state;
            _state = state;
            stateChanged.emit(_state, old);
        }
    }

    private var _paused :Bool = true;
    private var _loaded :Bool = false;
    private var _seekTime :Float = 0;
    private var _metaLoaded :Bool = false;
    private var _state :VideoState;

}
