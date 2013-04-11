
package flambe.script;

import flambe.sound.Playback;
import flambe.sound.Sound;
import flambe.script.Action;
import flambe.Entity;

/**
 * An action that plays back a sound.
 * @author Kipp Ashford
 */
class PlaySound
    implements Action
{
    public function new (sound :Sound, ?volume :Float = 1)
    {
        _sound = sound;
        _volume = volume;
    }
        
    public function update (dt :Float, actor :Entity) :Float
    {
        if (_playback == null) {
            _playback = _sound.play(_volume);
        }
        
        if (_playback.ended) {
            _playback = null;
            return 0;
        }
        
        return -1;
    }
    
    public function dispose () :Void {
        trace("Disposing sound");
        if (_playback != null) {
            _playback.dispose();
            _playback = null;
        }
    }
    
    /** The sound used for playback. */
    private var _sound:Sound;   
    /** The volume to play at. */
    private var _volume:Float;
    /** The playback instance held fo. */
    private var _playback:Playback;
}
