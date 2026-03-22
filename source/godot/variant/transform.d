/**
    Binding to Godot's Transform Variants

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.transform;
import godot.variant.variant;
import godot.variant.vector;
import godot.variant.basis;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;

/**
    A 2D transformation.
*/
struct Transform2D {
public:
@nogc:
    union {

        /**
            The transform's 2x3 matrix.
        */
        gd_float[2][3] matrix = 0;

        struct {

            /**
                First row of the transform
            */
            Vector2 x;
            
            /**
                Second row of the transform
            */
            Vector2 y;

            /**
                Final row of the transform
            */
            Vector2 origin;
        }
    }

    /**
        Identity matrix
    */
    enum Transform2D IDENTITY = Transform2D([[1.0, 0.0], [0.0, 1.0], [0.0, 0.0]]);

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_TRANSFORM2D;

    /**
        Constructs a Transform2D from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        transform2d_from_variant(&this, &variant);
    }

    /**
        Constructs a new transform.
    */
    this(gd_float[2][3] data) {
        this.matrix = data;
    }
}

/**
    A 3D transformation.
*/
struct Transform3D {
public:
@nogc:

    /**
        Basis of the transform.
    */
    Basis basis;

    /**
        Origin of the transform.
    */
    Vector3 origin;

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_TRANSFORM3D;

    /**
        Constructs a Transform3D from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        transform3d_from_variant(&this, &variant);
    }

    /**
        Constructs a Transform3D from a basis and origin.

        Params:
            basis =     The basis of the transform.
            origin =    The origin of the transform.
    */
    this(Basis basis, Vector3 origin) {
        this.basis = basis;
        this.origin = origin;
    }
}