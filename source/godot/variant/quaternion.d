/**
    Binding to Godot's Quaternion Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.quaternion;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;

struct Quaternion {
public:
@nogc:

    /**
        X
    */
    gd_float x;

    /**
        Y
    */
    gd_float y;

    /**
        Z
    */
    gd_float z;

    /**
        W
    */
    gd_float w;

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_QUATERNION;
    
    /**
        Constructs a Quaternion from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        quaternion_from_variant(&this, &variant);
    }
}