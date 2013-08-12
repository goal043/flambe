//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.IOErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.ProgressEvent;
import flash.media.SoundTransform;
import flash.net.NetConnection;
import flash.net.NetConnection;
import flash.net.NetStream;

import flambe.animation.AnimatedFloat;
import flambe.asset.AssetEntry;
import flambe.asset.Manifest;
import flambe.util.Signal0;
import flambe.util.Signal1;
import flambe.util.Signal2;
import flambe.util.Value;
import flambe.subsystem.VideoSystem;
import flambe.video.VideoMetaEvent;
import flambe.video.VideoProgressEvent;
import flambe.video.VideoView;

using Lambda;

class FlashVideo
    implements VideoSystem
{
    public var supported (get_supported, null) :Bool;
    public var userActionRequired (get_userActionRequired, null) :Bool;

    public function new (stage :Stage)
    {
        _stage = stage;
    }

    public function get_supported () :Bool
    {
        return true;
    }

    public function get_userActionRequired () :Bool
    {
        return false;
    }

    public function createView (x :Float, y :Float, width :Float, height :Float) :VideoView
    {
        var view = new FlashVideoView(x, y, width, height);
        _stage.addChild(view.container);
        FlashPlatform.instance.mainLoop.addTickable(view);
        return view;
    }

    private var _stage :Stage;
}

class FlashVideoView
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
    public var currentTime (default, null) :Float;
    public var loop (default, null) :Value<Bool>;
    public var videoWidth (get_videoWidth, null) :Float;
    public var videoHeight (get_videoHeight, null) :Float;

    public var container (default, null) :Sprite;

    public function new (x :Float, y :Float, width :Float, height :Float)
    {
        var onBoundsChanged = function (_,_) updateBounds();
        this.x = new AnimatedFloat(x, onBoundsChanged);
        this.y = new AnimatedFloat(y, onBoundsChanged);
        this.width = new AnimatedFloat(width, onBoundsChanged);
        this.height = new AnimatedFloat(height, onBoundsChanged);
        this.volume = new AnimatedFloat(1);


        stateChanged = new Signal2();
        progress = new Signal1();
        completed = new Signal0();
        ready = new Signal0();
        error = new Signal1();

        loop = new Value<Bool>(false);

        container = new Sprite();
        _video = new flash.media.Video ();
        _nc = new NetConnection();
        _nc.connect(null);
        _ns = new NetStream(_nc);
        _ns.client = { onMetaData : onMetaData };
        _ns.addEventListener(NetStatusEvent.NET_STATUS, onEvent, false, 0, true);
        _video.attachNetStream(_ns);

        updateBounds();

        container.addChild(_video);
    }

    public function seek(time:Float) :VideoView {
        _seekTime = time;
        if (_loaded && _metaLoaded) {
            _ns.seek(time);
            // video.currentTime = _seekTime;
            // if (video.paused) {
            //     video.play();
            // }
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
                case "flv":
                format = AssetFormat.FLV;
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
            if (entry.format == AssetFormat.MP4 || entry.format == AssetFormat.FLV) {
                
                // Load the first format that is compatible.
                _ns.play(getFullURL(entry.url));
                setState(VideoState.loading);

                return this;
            }
        }

        return this;
    }

    /**
     * This is a horrible hack for Flash, since netStreams use relative paths to the 
     * swf that loads them, not of the index.html.
     * @param  url The URL going in.
     * @return     The URL going out.
     */
    public inline function getFullURL(url:String) :String 
    {
        var r :EReg = ~/^(http:|https:|\/)/gm;
        url = !r.match(url) ? "../" + url : url;
        return url;
    }

    public function play() :VideoView {
        _autoPlay = true;
        if (_paused) {
            if (_loaded) {
                _ns.resume();
            }
            _paused = false;
        }
        return this;
    }

    public function pause() :VideoView {
        _autoPlay = false;
        if (!_paused) {
            // video.autoplay = false;

            if (_loaded) {
                _ns.pause();
            }

            _paused = true;
        }
        return this;
    }

    private function get_videoWidth () :Float {
        return _video != null && _metaLoaded ? _video.videoWidth : 0;
    }

    private function get_videoHeight () :Float {
        return _video != null && _metaLoaded ? _video.videoHeight : 0;
    }

    public function dispose ()
    {
        if (_video == null) {
            return; // Already disposed
        }
        _ns.removeEventListener(NetStatusEvent.NET_STATUS, onEvent, false);
        try {
            _ns.close();
        } catch (e:Dynamic){}
        try {
            _nc.close();
        } catch (e:Dynamic){}


        container.removeChild(_video);
        container.parent.removeChild(container);

        container = null;
        _video = null;
        _nc = null;
        _ns = null;
    }

    public function update (dt :Float) :Bool
    {
        x.update(dt);
        y.update(dt);
        width.update(dt);
        height.update(dt);
        volume.update(dt);

        return (_video == null);
    }

    private function onMetaData(e:Dynamic) {
        _metaLoaded = true;

        duration = e.duration;
        _videoWidth = e.width;
        _videoHeight = e.height;

        setReady();
    }

    private function onEvent(e):Void  {
        trace(e.info.code);
        switch (e.info.code) {
            case "NetStream.Play.Start":
                if (!_loaded) {
                    _loaded = true;
                    setReady();
                }

            case "NetStream.Buffer.Full":
                if(!_bufferFull) {
                    _bufferFull = true;
                    setReady();
                }
                // setState(VideoState.playing);
                // _loaded = true;
                // setReady();
            // case "play":
            case "NetStream.Seek.InvalidTime":
                if (Reflect.hasField(e,"info")) {
                    _ns.seek(Reflect.getProperty(e.info,"details"));
                }
            // case "playing":
            //     _paused = false;
            //     setState(VideoState.playing);

            case "NetStream.Buffer.Empty":
                if (_state != VideoState.completed) {
                    _bufferFull = false;
                    setState(VideoState.buffering);
                }

            case "NetStream.Pause.Notify":
                if (_metaLoaded) {
                    _paused = true;
                    setState(VideoState.paused);
                }
            // case "pause":
            //     _paused = true;
            //     setState(VideoState.paused);

            case "NetStream.Play.Complete", "NetStream.Play.Stop":
                _seekTime = 0;
                if (!loop._) {                
                    setState(VideoState.completed);
                    completed.emit();
                } else {
                    _ns.seek(0);
                }

            case "NetStream.Play.StreamNotFound":
                error.emit("Stream not found");
        }
    }

    /**
     * Clears out listeners and resets player values.
     * @return [description]
     */
    private function clear():Void {
        _paused = true;
        _loaded = _metaLoaded = false;
        _videoWidth = _videoHeight = duration = 0;
    }

    private function updateBounds ()
    {
        if (_video == null) {
            return; // Already disposed
        }

        container.x = x._;
        container.y = y._;
        container.graphics.clear();
        container.graphics.beginFill(0,1);
        container.graphics.drawRect(0,0,width._,height._);
        
        _video.width = width._;
        _video.height = height._;

        if (_videoWidth > 0 && _videoHeight > 0) {
            var nScale :Float = Math.min(width._ / _videoWidth, height._ / _videoHeight);
            _video.width = Math.min(width._, _videoWidth * nScale);
            _video.height = Math.min(height._, _videoHeight * nScale);
            _video.y = (height._ * .5) - (_video.height * .5);
            _video.x = (width._ * .5) - (_video.width * .5);
        }
    }

    private function setReady () {

        if (_metaLoaded && _loaded && _bufferFull) {


            if (_seekTime > 0) {
                _ns.seek(_seekTime);
            } else {
                setState(VideoState.ready);
                ready.emit();
            }

        }

        if (_metaLoaded && _loaded && _bufferFull && !_autoPlay) {
            _ns.pause();
        }
    }

    private function setState(state:VideoState) {
        if(state != _state) {
            var old:VideoState = _state;
            _state = state;
            stateChanged.emit(_state, old);
        }
    }

    private var _container :Sprite;
    private var _video :flash.media.Video;
    private var _ns :NetStream;
    private var _nc :NetConnection;
    private var _paused :Bool = true;
    private var _pendingPause :Bool = true;
    private var _loaded :Bool = false;
    private var _bufferFull :Bool = false;
    private var _autoPlay :Bool = false;
    private var _seekTime :Float = 0;
    private var _metaLoaded :Bool = false;
    private var _state :VideoState;
    private var _videoWidth :Float = 0;
    private var _videoHeight :Float = 0;
}
