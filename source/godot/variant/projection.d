/**
    Binding to Godot's Projection Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.projection;
import godot.variant.vector;
import godot.variant.variant;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;

/**
    A 4x4 projection matrix.
*/
struct Projection {
public:
@nogc:
    union {

        /**
            The elements of the projection matrix.
        */
        gd_float[4][4] matrix = 0;

        struct {

            /**
                First row of the matrix.
            */
            Vector4 x;
            
            /**
                Second row of the matrix.
            */
            Vector4 y;
            
            /**
                Third row of the matrix.
            */
            Vector4 z;
            
            /**
                Fourth row of the matrix.
            */
            Vector4 w;
        }
    }

    /**
        Identity projection matrix.
    */
    enum Projection IDENTITY = Projection([
        [1.0, 0.0, 0.0, 0.0], 
        [0.0, 1.0, 0.0, 0.0], 
        [0.0, 0.0, 1.0, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]);

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_PROJECTION;
    
    /**
        Constructs a Quaternion from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        quaternion_from_variant(&this, &variant);
    }

    /**
        Constructs a new Projection matrix from data.

        Params:
            matrix = The data of the matrix.
    */
    this(gd_float[4][4] matrix) {
        this.matrix = matrix;
    }
}