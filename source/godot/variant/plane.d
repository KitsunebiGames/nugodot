/**
    Binding to Godot's Plane Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.plane;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.variant;

/**
    A 3D plane defined by a normal and a distance.
*/
struct Plane {
public:
@nogc:

    /**
        Normal that the plane points towards.
    */
    Vector3 normal;

    /**
        The size of the plane's surface.
    */
    gd_float d;

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_PLANE;
    
    /**
        Constructs a Plane from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        plane_from_variant(&this, &variant);
    }

    /**
        Constructs a new Plane from a normal and distance.

        Params:
            normal =    The normal indicating the direction the plane faces.
            d =         Distance to the plane's edge from the center.
    */
    this(Vector3 normal, gd_float d) {
        this.normal = normal;
        this.d = d;
    }
}