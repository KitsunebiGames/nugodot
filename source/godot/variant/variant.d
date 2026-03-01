module godot.variant.variant;
import godot.core.gdextension.iface;
import godot.core.gdextension.utils;
import numem;

/**
    Variant type tags.
*/
enum GDVariantType {
    NIL = 0,
    BOOL = 1,
    INT = 2,
    FLOAT = 3,
    STRING = 4,
    VECTOR2 = 5,
    VECTOR2I = 6,
    RECT2 = 7,
    RECT2I = 8,
    VECTOR3 = 9,
    VECTOR3I = 10,
    TRANSFORM2D = 11,
    VECTOR4 = 12,
    VECTOR4I = 13,
    PLANE = 14,
    QUATERNION = 15,
    AABB = 16,
    BASIS = 17,
    TRANSFORM3D = 18,
    PROJECTION = 19,
    COLOR = 20,
    STRING_NAME = 21,
    NODE_PATH = 22,
    RID = 23,
    OBJECT = 24,
    CALLABLE = 25,
    SIGNAL = 26,
    DICTIONARY = 27,
    ARRAY = 28,
    PACKED_BYTE_ARRAY = 29,
    PACKED_INT32_ARRAY = 30,
    PACKED_INT64_ARRAY = 31,
    PACKED_FLOAT32_ARRAY = 32,
    PACKED_FLOAT64_ARRAY = 33,
    PACKED_STRING_ARRAY = 34,
    PACKED_VECTOR2_ARRAY = 35,
    PACKED_VECTOR3_ARRAY = 36,
    PACKED_COLOR_ARRAY = 37,
    PACKED_VECTOR4_ARRAY = 38,
}

/**
    A godot variant type.
*/
struct GDVariant {
private:
@nogc:
    void[32] data_;
    @property GDExtensionVariantPtr ptr() => cast(GDExtensionVariantPtr)data_.ptr;

public:

    /**
        The type of this variant.
    */
    @property GDVariantType type() => cast(GDVariantType)variant_get_type(ptr);

    /**
        Makes a new nil variant.
    */
    static GDVariant makeNil() {
        GDVariant v = void;
        variant_new_nil(cast(GDExtensionVariantPtr)&v);
        return v;
    }

    /// Destructor
    ~this() {
        variant_destroy(this.ptr);
    }

    /**
        Constructs a new variant from a pointer.
    */
    this(GDExtensionVariantPtr ptr) {
        variant_new_copy(this.ptr, ptr);
    }

    /**
        Makes a copy of the variant.
    */
    this(ref return scope GDVariant other) {
        variant_new_copy(this.ptr, other.ptr);
    }

    /**
        Constructs a variant from a double.

        Params:
            value = The new value to give the variant.
    */
    this(double value) {
        // variant_from_float(this.ptr, cast(GDExtensionTypePtr)&value);
    }

    /**
        Makes a copy of the variant.

        Params:
            deep = Whether to perform a deep copy.
        
        Returns:
            A new $(D GDVariant) with the contents copied from the source.
    */
    GDVariant duplicate(bool deep) {
        GDVariant result;
        // variant_duplicate(cast(GDExtensionConstVariantPtr)&result, cast(GDExtensionConstVariantPtr)&this, deep);
        return result;
    }
}