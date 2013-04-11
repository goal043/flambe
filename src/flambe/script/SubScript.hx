
package flambe.script;

import flambe.script.Script;
import flambe.script.Action;
import flambe.Entity;

/**
 * This allows us to use MoveBy, MoveTo, PlayMovie, etc. on multiple entities while still being stoppable from a single master script.
 * Useful for sequencing cut scenes and tutorials.
 * @author Kipp Ashford
 */
class SubScript
    implements Action
{
    public function new (actor :Entity, action :Action)
    {
    	_actor = actor;
    	_action = action;
    }
        
    public function update (dt :Float, actor :Entity) :Float
    {
        if (_script == null) {
            _script = _actor.get(Script);
            if (_script == null) {
            	_script = new Script();
            }
            _actor.add(_script);
            _script.run(_action);
            #if debug
            if (_actor.parent == null && _actor != System.root) {
            	Log.warn("Attempting to run a subscript on an entity which doesn't have a parent.");
            }
            #end
        }
        
        if (!_script.running) {
            _script = null;
            return 0;
        }
        
        return -1;
    }
    
    public function dispose () :Void
    {
    	if (_script != null) {
    		_script.stopAll();
    	}
    	_script = null;
    }
    
    /** The sound used for playback. */
    private var _script :Script;
    /** The action to play back. */
    private var _action :Action;
    /** The actor for the script */
    private var _actor :Entity;
}
