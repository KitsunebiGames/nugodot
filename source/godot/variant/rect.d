module godot.variant.rect;
import godot.core.gdextension.iface;
import godot.variant.vector;
import numem.core.math;

/**
    A godot rectangle.
*/
struct RectImpl(T) {
public:
@nogc:
    union {
        T[4] rect = 0;

        struct {
            VectorImpl!(T, 2) position;
            VectorImpl!(T, 2) size;
        }
        struct {
            T x;
            T y;
            T width;
            T height;
        }
    }

    /**
        The area of the rectangle.
    */
    @property T area() => width * height;

    /**
        Whether the rectangle has an area.
    */
    @property bool hasArea() => width+height > 0;

    /**
        The center of the rectangle.
    */
    @property VectorImpl!(T, 2) center() => VectorImpl!(T, 2)(x + (width / 2), y + (height / 2));

    /**
        Constructs a new rectangle.
    */
    this(T x, T y, T width, T height) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    /**
        Constructs a new rectangle.
    */
    this(T x, T y, VectorImpl!(T, 2) size) {
        this.x = x;
        this.y = y;
        this.size = size;
    }

    /**
        Constructs a new rectangle.
    */
    this(VectorImpl!(T, 2) position, T width, T height) {
        this.position = position;
        this.width = width;
        this.height = height;
    }

    /**
        Constructs a new rectangle.
    */
    this(VectorImpl!(T, 2) position, VectorImpl!(T, 2) size) {
        this.position = position;
        this.size = size;
    }

    /**
        Gets whether the other type intersects this rectangle.

        Params:
            other = The type to check for intersection.
    */
    pragma(inline, true)
    bool intersects(T)(ref T other, bool includeBorders = false) const
    if (is(T == RectImpl!U, U...) || is(T == VectorImpl!U, U...)) {
        static if (is(T == RectImpl!U, U...)) {
            if (includeBorders) {
                if (x > (other.x + other.width))
                    return false;
                if ((x + width) < other.x)
                    return false;
                if (y > (other.y + other.height))
                    return false;
                if ((y + height) < other.y)
                    return false;
            } else {
                if (x >= (other.x + other.width))
                    return false;
                if ((x + width) <= other.x)
                    return false;
                if (y >= (other.y + other.height))
                    return false;
                if ((y + height) <= other.y)
                    return false;
            }
            return true;
        } else static if (is(T == VectorImpl!U, U...)) {
            if (other.x < x) {
                return false;
            }
            if (other.y < y) {
                return false;
            }

            if (other.x >= (x + width)) {
                return false;
            }
            if (other.y >= (y + height)) {
                return false;
            }
            return true;
        }
    }

    /**
        Gets the distance to the given point

        Params:
            point = The point to get the distance to.
        
        Returns:
            The distance to the point; any dimensions above 2
            are not taken into account.
    */
    pragma(inline, true)
    gd_float distanceTo(T)(ref T point) const
    if (is(T == VectorImpl!U, U...)) {
        gd_float dist = 0.0;
        bool inside = true;

        if (point.x < x) {
            gd_float d = cast(gd_float)x - cast(gd_float)point.x;
            dist = d;
            inside = false;
        }
        if (point.y < y) {
            gd_float d = cast(gd_float)y - cast(gd_float)point.y;
            dist = d;
            inside = false;
        }
        if (point.x >= (x + width)) {
            gd_float d = cast(gd_float)point.x - cast(gd_float)(x + width);
            dist = inside ? d : nu_min(dist, d);
            inside = false;
        }
        if (point.y >= (y + height)) {
            gd_float d = cast(gd_float)point.x - cast(gd_float)(y + height);
            dist = inside ? d : nu_min(dist, d);
            inside = false;
        }

        return inside ? 0.0 : dist;
    }

    /**
        Gets whether this rectangle encloses another.

        Params:
            other = The rectangle to compare against.
        
        Returns:
            $(D true) if this rectangle encloses the other,
            $(D false) otherwise.
    */
    pragma(inline, true)
    bool encloses(T)(ref T other) const
    if (is(T == RectImpl!U, U...)) {
        return 
            (other.x >= x) && 
            (other.y >= y) &&
            ((other.x + other.width) <= (x + width)) &&
            ((other.y + other.height) <= (y + height));
    }
}

alias Rect2 = RectImpl!gd_float;
alias Rect2i = RectImpl!int;
