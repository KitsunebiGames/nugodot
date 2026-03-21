module godot.variant.variant;
import godot.core.gdextension;
import godot.core.object;
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
    @property GDExtensionVariantPtr ptr() => cast(GDExtensionVariantPtr)data_.ptr;

public:

    /**
        The type of this variant.
    */
    @property VariantType type() => cast(VariantType)variant_get_type(ptr);

    /**
        The hash of this variant.
    */
    @property long hash() => variant_hash(&this);

    /**
        The name of the type stored in the variant.
    */
    @property String typeName() {
        String value;
        variant_get_type_name(cast(GDExtensionVariantType)type, &value);
        return value;
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
    this(ref return scope Variant other) {
        variant_new_copy(this.ptr, other.ptr);
    }

    /**
        Constructs a variant from a compatible type.

        Params:
            value = The new value to give the variant.
    */
    this(T)(auto ref T value) {
        static if (is(T == bool)) {

            variant_from_bool(&this, &value);
        } else static if (__traits(isIntegral, T)) {

            static if (__traits(isUnsigned, T))
                ulong _tmp = cast(ulong)value;
            else
                long _tmp = cast(long)value;
            
            variant_from_int(&this, &_tmp);
        } else static if (__traits(isFloating, T)) {
            
            double _tmp = cast(double)value;
            variant_from_float(&this, &_tmp);
        } else static if(is(T == Vector2)) {

            variant_from_vector2(&this, &value);
        } else static if(is(T == Vector2i)) {

            variant_from_vector2i(&this, &value);
        } else static if(is(T == Vector3)) {

            variant_from_vector3(&this, &value);
        } else static if(is(T == Vector3i)) {

            variant_from_vector3i(&this, &value);
        } else static if(is(T == Vector4)) {

            variant_from_vector4(&this, &value);
        } else static if(is(T == Vector4i)) {

            variant_from_vector4i(&this, &value);
        } else static if (is(T == String)) {
            
            variant_from_string(&this, &value);
        } else static if (is(T == string)) {

            variant_from_string(&this, gde_make_string(value));
        } else static if (is(T == StringName)) {
            
            variant_from_string_name(&this, &value);
        } else static if (is(T == RID)) {
            
            variant_from_rid(&this, &value);
        } else static if (is(T == TypedArray!U, U)) {
            
            variant_from_array(&this, &value);
        } else static if (is(T == TypedDictionary!U, U...)) {
            
            variant_from_dictionary(&this, &value);
        } else static if (is(T == PackedArray!U, U)) {
            
            T.toVariantFunc(&this, &value);
        } else static if (is(T == U[], U) && is(PackedArray!U)) {
            
            this(gde_to_packed_array(value));
        } else static if (is(T : GDEObject)) {
            if (value)
                variant_from_object(&this, value.ptr);
            
        } else {
            static assert(0, T.stringof~" cannot be put into a Variant!");
        }
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