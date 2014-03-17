//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.display;

import flambe.display.Sprite;
import flambe.math.Point;
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
        _segments = null;
    }

    /**
     * Adds a line segment to this shape. The coordinates specified are local to the Shape's origin.
     * @returns This instance, for chaining.
     */
    public function addLineSegmentF(startX :Float, startY :Float, endX :Float, endY :Float, width :Float, ?roundedCap :Bool = false) :Shape
    {
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
        var prev :Segment = _segments;
        _segments = new Segment(ptStart.x, ptStart.y, ptEnd.x, ptEnd.y, width, roundedCap);
        _segments.next = prev;

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

    override public function draw (g :Graphics)
    {
        var c :Int = color._;
        var seg :Segment = _segments;
        while (seg != null) {
            g.drawLine(c, seg.startX, seg.startY, seg.endX, seg.endY, seg.width, seg.roundedCap);
            seg = seg.next;
        }
    }

    /** The linked list of line segments */
    private var _segments :Segment;
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