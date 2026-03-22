/**
    Binding to Godot's Basis Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.basis;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.variant;

/**
    A 3x3 basis matrix.
*/
struct Basis {
public:
@nogc:
    union {
        /**
            The 3x3 matrix data.
        */
        gd_float[3][3] matrix;

        struct {

            /**
                First row of the matrix.
            */
            Vector3 x;
            
            /**
                Second row of the matrix.
            */
            Vector3 y;
            
            /**
                Third row of the matrix.
            */
            Vector3 z;
        }
    }

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_BASIS;

    /**
        Identity basis matrix.
    */
    enum Basis IDENTITY = Basis([
        [1.0, 0.0, 0.0], 
        [0.0, 1.0, 0.0], 
        [0.0, 0.0, 1.0], 
    ]);
    
    /**
        Constructs a Plane from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        basis_from_variant(&this, &variant);
    }

    /**
        Constructs a new Basis matrix from data.

        Params:
            matrix = The data of the matrix.
    */
    this(gd_float[3][3] matrix) {
        this.matrix = matrix;
    }
}