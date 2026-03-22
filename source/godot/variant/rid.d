/**
    Binding to Godot's RID Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.rid;
import godot.core.gdextension.iface;
import godot.variant;

/**
    Godot Rendering ID.
*/
struct RID {
    ulong value;
    alias value this;

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_RID;

    /**
        Constructs a new RID.

        Params:
            value = The value of the RID.
    */
    this(ulong value) {
        this.value = value;
    }

    /**
        Constructs an RID from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        rid_from_variant(&this, &variant);
    }
}