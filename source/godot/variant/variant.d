/**
    Binding to Godot's core variant type

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
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

    /// Destructor
    ~this() {
        variant_destroy(&this);
    }

    /**
        Makes a copy of the variant.
    */
    this(ref return scope Variant other) {
        variant_new_copy(&this, &other);
    }

    /**
        Constructs a variant from a compatible type.

        Params:
            value = The new value to give the variant.
    */
    this(T)(auto ref T value) {
        static if (is(T : GDEObject)) {

            // NOTE:    GDExtension assumes that the Object ptr is stored in a struct
            //          as such we just place it on the stack and take a reference to
            //          the stack location to emulate such an arrangement. 
            if (value && value.ptr) {
                variant_from_object(&this, &(value.ptr()));
            }
            
        } else static if (is(T == bool)) {

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