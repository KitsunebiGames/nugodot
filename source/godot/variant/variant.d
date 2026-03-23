/**
    Binding to Godot's core variant type

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.variant;
import godot.core.gdextension;
import godot.core.object;
import godot.core.arg;
import godot.variant;
import godot.globals;
import numem;

/**
    A godot variant type.
*/
struct Variant {
private:
@nogc:
    void[VARIANT_SIZE_VARIANT] data_;

public:

    /**
        The type of this variant.
    */
    @property VariantType type() => cast(VariantType)variant_get_type(&this);

    /**
        The hash of this variant.
    */
    @property long hash() => variant_hash(&this);

    /**
        Instance ID of object stored in variant.
    */
    @property GDObjectInstanceID objectID() => variant_get_object_instance_id(&this);

    /**
        The name of the type stored in the variant.
    */
    @property String typeName() {
        String value;
        variant_get_type_name(cast(GDExtensionVariantType)type, &value);
        return value;
    }

    /**
        Constructs a variant from a compatible type.

        Params:
            value = The new value to give the variant.
    */
    this(T)(auto ref T value) {
        gde_to_varptr(value, cast(void*)&this);
    }

    /**
        Makes a copy of the variant.

        Params:
            deep = Whether to perform a deep copy.
        
        Returns:
            A new $(D GDVariant) with the contents copied from the source.
    */
    Variant duplicate(bool deep) {
        Variant result;
        variant_duplicate(&result, &this, deep);
        return result;
    }
}