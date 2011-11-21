//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.display;

import flambe.display.SpriteSheet;
import flambe.math.FMath;

class AnimatedSprite extends Sprite
{
    public var sheet (default, null) :SpriteSheet;
    public var animation (default, null) :Animation;
    public var frame (getFrame, setFrame) :Int;
    public var paused (default, null) :Bool;

    public function new (sheet :SpriteSheet)
    {
        super();
        this.sheet = sheet;
    }

    public function play (name :String)
    {
        animation = sheet.getAnimation(name);
        if (animation.loop) {
            _defaultAnim = animation;
        }
        _frame = 0;
        _elapsed = 0;
    }

    public function stop ()
    {
        animation = null;
        _defaultAnim = null;
    }

    inline public function pause ()
    {
        paused = true;
    }

    override public function onUpdate (dt :Int)
    {
        super.onUpdate(dt);

        if (animation != null && !paused) {
            _elapsed += dt;
            var framesElapsed = FMath.toInt(_elapsed / animation.delay);
            if (framesElapsed > 0) {
                _elapsed -= FMath.toInt(framesElapsed*animation.delay);
                _frame += framesElapsed;

                var frameCount = animation.frames.length;
                if (_frame >= frameCount) {
                    if (animation.loop) {
                        _frame %= frameCount;
                    } else {
                        animation = _defaultAnim;
                        _frame = 0;
                        _elapsed = 0;
                    }
                }
            }
        }
    }

    override public function draw (ctx :DrawingContext)
    {
        if (animation == null) {
            return;
        }
        var frameData = animation.frames[frame];
        ctx.drawSubImage(sheet.texture,
            -anchorX._ - animation.anchorX + frameData.offsetX,
            -anchorY._ - animation.anchorY + frameData.offsetY,
            frameData.x, frameData.y, frameData.width, frameData.height);
    }

    override public function getNaturalWidth () :Float
    {
        if (animation == null) {
            return 0;
        }
        return animation.frames[frame].width;
    }

    override public function getNaturalHeight () :Float
    {
        if (animation == null) {
            return 0;
        }
        return animation.frames[frame].height;
    }

    override public function containsLocal (localX :Float, localY :Float) :Bool
    {
        if (animation == null) {
            return false;
        }
        var frameData = animation.frames[frame];
        var left = -animation.anchorX + frameData.offsetX;
        var top = -animation.anchorY + frameData.offsetY;
        return localX >= left && localX < left + frameData.width
            && localY >= top && localY < top + frameData.height;
    }

    inline private function setFrame (frame :Int) :Int
    {
        _frame = frame;
        _elapsed = 0;
        return frame;
    }

    inline private function getFrame () :Int
    {
        return _frame;
    }

    private var _elapsed :Int;
    private var _frame :Int;
    private var _defaultAnim :Animation;
}