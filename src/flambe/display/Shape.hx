//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.display;

import flambe.display.Sprite;
import flambe.display.Texture;
import flambe.math.FMath;
import flambe.math.Point;
import flambe.System;
import flambe.util.Assert;
import flambe.util.Value;

/**
 * A user defined shape (line, rectangle, polygon) that is assembled by adding
 * various primitives together. Can be transformed like any Sprite object.
 */
class Shape extends Sprite
{
    /** The color of the shape */
    public var color(default, null) :Value<Int>;

    public function new(?color :Int = 0x000000)
    {
        super();
        this.color = new Value<Int>(color);
    }

    /**
     * Clears out all the line segments.
     */
    public function clear()
    {
        if (_texture != null) {
            _texture.dispose();
        }
        _texture = null;
        _segments = null;
    }

    /**
     * Adds a line segment to this shape. The coordinates specified are local to the Shape's origin.
     * @returns This instance, for chaining.
     */
    public function addLineSegmentF(startX :Float, startY :Float, endX :Float, endY :Float, width :Float, ?roundedCap :Bool = false) :Shape
    {
        _recalculateWidth = true;
        var prev :Segment = _segments;
        _segments = new Segment(startX, startY, endX, endY, width, roundedCap);
        _segments.next = prev;
        return this;
    }

    /**
     * Adds a line segment to this shape. The coordinates specified are local to the Shape's origin.
     * @returns This instance, for chaining.
     */
    public function addLineSegment(ptStart :Point, ptEnd :Point, width :Float, ?roundedCap :Bool = false) :Shape
    {
        addLineSegmentF(ptStart.x, ptStart.y, ptEnd.x, ptEnd.y, width, roundedCap);
        return this;
    }

    /**
     * Adds a contiguous line strip to this shape. The coordinates specified are local to the Shape's origin.
     * @returns This instance, for chaining.
     */
    public function addLineStrip(points :Array<Point>, width :Float, ?roundedCap :Bool = false)
    {
        Assert.that(points.length >= 2, "addLineStrip() must have at least '2' Points");

        for(i in 1...points.length) {
            addLineSegment(points[i - 1], points[i], width, roundedCap);
        }

        return this;
    }

    /**
     * Flattens the line segments into a single texture.
     * @return This instance, for chaining.
     */
    public function flatten() :Shape
    {
        if (_recalculateWidth) {
            recalculate();
        }

        var flattened :Texture = System.renderer.createTexture( Math.ceil(_width), Math.ceil(_height) );
        draw(flattened.graphics);

        if (_texture != null) {
            _texture.dispose();
        }

        _texture = flattened;
        _segments = null;
        return this;
    }

    override public function draw (g :Graphics)
    {
        if (_texture != null) {
            g.drawTexture(_texture, 0, 0);
        }

        var c :Int = color._;
        var seg :Segment = _segments;
        while (seg != null) {
            g.drawLine(c, seg.startX, seg.startY, seg.endX, seg.endY, seg.width, seg.roundedCap);
            seg = seg.next;
        }
    }

    override public function getNaturalWidth() :Float
    {
        if (_recalculateWidth) {
            recalculate();
        }
        return _height;
    }

    override public function getNaturalHeight() :Float
    {
        if (_recalculateWidth) {
            recalculate();
        }
        return _width;
    }

    private function recalculate()
    {
        var minX :Float = 0;
        var minY :Float = 0;
        var maxX :Float = 0;
        var maxY :Float = 0;

        var seg :Segment = _segments;
        while (seg != null) {
            minX = FMath.min( FMath.min(seg.endX, seg.startX) - seg.width, minX);
            minY = FMath.min( FMath.min(seg.endY, seg.startY) - seg.width, minY);
            maxX = FMath.max( FMath.max(seg.endX, seg.startX) + seg.width, maxX);
            maxY = FMath.max( FMath.max(seg.endY, seg.startY) + seg.width, maxY);
            seg = seg.next;
        }

        if (_texture != null) {
            maxX = FMath.max(maxX, _texture.width);
            maxY = FMath.max(maxY, _texture.height);            
        }

        _width = maxX - minX;
        _height = maxY - minY;
        trace("(" + _width + " x " + _height + ")");
        _recalculateWidth = false;
    }

    /** The linked list of line segments */
    private var _segments :Segment;
    /** Texture used for flattened shapes. */
    private var _texture :Texture;
    /** comment */
    private var _width :Float = 0;
    /** comment */
    private var _height :Float = 0;
    /** comment */
    private var _recalculateWidth :Bool;
}

private class Segment
{
    /** The starting x position for the line segment. */
    public var startX :Float;
    /** The ending x position for the line segment. */
    public var endX :Float;
    /** The ending y position for the line segment. */
    public var endY :Float;
    /** The starting y position of the line segment. */
    public var startY :Float;
    /** The length of the segment. */
    public var width :Float;
    /** If the cap should be round or not. */
    public var roundedCap :Bool;
    /** The next line segment in the list. */
    public var next :Segment;

    public function new(startX :Float, startY :Float, endX :Float, endY :Float, width :Float, roundedCap :Bool)
    {
        this.startX = startX;
        this.startY = startY;
        this.endX = endX;
        this.endY = endY;
        this.width = width;
        this.roundedCap = roundedCap;
    }
}