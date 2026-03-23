/**
    Utilties for encoding and decoding Godot ptrcall and varcall arguments.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.arg;
import godot.core.gdextension.iface;
import godot.core.object;
import godot.variant;
import numem.core.traits;
import numem;

/**
    Encodes a type into a variant pointer.

    Params:
        source = The source data to encode to the variant.
        target = The target variant that should contain the source data.
*/
pragma(inline, true)
void gde_to_varptr(T)(ref T source, inout(GDExtensionVariantPtr) target) @nogc {
    static if (is(T == bool)) {

        // bool
        variant_from_bool(cast(GDExtensionVariantPtr)target, &source);
    } else static if (__traits(isIntegral, T)) {

        // Signed and unsigned integers.
        ulong _tmp = cast(ulong)source;
        variant_from_int(cast(GDExtensionVariantPtr)target, &_tmp);
    } else static if (__traits(isFloating, T)) {

        // Floats
        double _tmp = cast(double)source;
        variant_from_float(cast(GDExtensionVariantPtr)target, &_tmp);
    } else static if (is(T == String)) {

        // String
        variant_from_string(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == StringName)) {

        // StringName
        variant_from_string_name(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == NodePath)) {

        // NodePath
        variant_from_node_path(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == RID)) {

        // RID
        variant_from_rid(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == VectorImpl!U, U...)) {

        // Vectors
        T.variant_from_vector(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Quaternion)) {

        // Quaternion
        variant_from_quaternion(target, &source);
    } else static if (is(T == Color)) {

        // Color
        variant_from_color(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == RectImpl!U, U...)) {

        // Rectangles
        T.variant_from_rect(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == AABB)) {

        // AABB
        variant_from_aabb(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Plane)) {

        // Plane
        variant_from_plane(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Transform2D)) {

        // Transform2D
        variant_from_transform2d(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Transform3D)) {

        // Transform3D
        variant_from_transform3d(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Basis)) {

        // Basis
        variant_from_basis(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Projection)) {

        // Projection
        variant_from_projection(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == TypedArray!U, U)) {

        // Arrays
        variant_from_array(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == PackedArray!U, U)) {

        // Packed Arrays
        T.variant_from_packed_array(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == TypedDictionary!U, U...)) {

        // Dictionaries
        variant_from_dictionary(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Callable)) {

        // Callable
        variant_from_callable(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Signal!U, U...)) {

        // Signal
        variant_from_signal(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T == Variant)) {
        
        // Variant
        variant_new_copy(cast(GDExtensionVariantPtr)target, &source);
    } else static if (is(T : GDEObject)) {
        import godot.ref_counted : RefCounted;

        // Objects
        if (source) {
            auto _tmp = source.ptr;
            variant_from_object(cast(GDExtensionVariantPtr)target, &_tmp);
        }
    } else {

        // Unsupported.
        static assert(0, T.stringof~" can't be encoded to a variant, do you need to wrap it first?");
    }
}

/**
    Encodes a value into a ptrcall pointer.

    Params:
        source = The source data to write.
        target = The target to write to
*/
pragma(inline, true)
void gde_to_ptr(T)(ref T source, ref inout(GDExtensionTypePtr) target) @nogc {
    static if (is(T == bool)) {

        // bool
        gde_blit(target, source);
    } else static if (__traits(isIntegral, T)) {

        // Signed and unsigned integers.
        gde_blit(target, cast(GDExtensionInt)source);
    } else static if (__traits(isFloating, T)) {

        // Floats
        gde_blit(target, cast(double)source);
    } else static if (is(T == String)) {

        // String
        gde_blit(target, source);
    } else static if (is(T == StringName)) {

        // StringName
        gde_blit(target, source);
    } else static if (is(T == NodePath)) {

        // NodePath
        gde_blit(target, source);
    } else static if (is(T == RID)) {

        // RID
        gde_blit(target, source);
    } else static if (is(T == VectorImpl!U, U...)) {

        // Vectors
        gde_blit(target, source);
    } else static if (is(T == Quaternion)) {

        // Quaternion
        gde_blit(target, source);
    } else static if (is(T == Color)) {

        // Color
        gde_blit(target, source);
    } else static if (is(T == RectImpl!U, U...)) {

        // Rectangles
        gde_blit(target, source);
    } else static if (is(T == AABB)) {

        // AABB
        gde_blit(target, source);
    } else static if (is(T == Plane)) {

        // Plane
        gde_blit(target, source);
    } else static if (is(T == Transform2D)) {

        // Transform2D
        gde_blit(target, source);
    } else static if (is(T == Transform3D)) {

        // Transform3D
        gde_blit(target, source);
    } else static if (is(T == Basis)) {

        // Basis
        gde_blit(target, source);
    } else static if (is(T == Projection)) {

        // Projection
        gde_blit(target, source);
    } else static if (is(T == TypedArray!U, U)) {

        // Arrays
        gde_blit(target, source);
    } else static if (is(T == PackedArray!U, U)) {

        // Packed Arrays
        gde_blit(target, source);
    } else static if (is(T == TypedDictionary!U, U...)) {

        // Dictionaries
        gde_blit(target, source);
    } else static if (is(T == Callable)) {

        // Callable
        gde_blit(target, source);
    } else static if (is(T == Signal!U, U...)) {

        // Signal
        gde_blit(target, source);
    } else static if (is(T == Variant)) {
        
        // Variant
        gde_blit(target, source);
    } else static if (is(T : GDEObject)) {

        // Objects
        if (source) {
            gde_blit(target, source.ptr);
        }
    } else {

        gde_blit(target, source);
    }
}

/**
    Decodes a variant into a target

    Params:
        source = The source variant to get data from.
        target = The target to store the data in.
*/
void gde_from_varptr(T)(inout(GDExtensionVariantPtr) source, ref T target) @nogc {
    static if (is(T == bool)) {

        // bool
        bool_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (__traits(isIntegral, T)) {

        // Signed and unsigned integers.
        ulong _tmp;
        int_from_variant(&_tmp, cast(GDExtensionVariantPtr)source);
        target = cast(T)_tmp;
    } else static if (__traits(isFloating, T)) {

        // Floats
        double _tmp;
        float_from_variant(&_tmp, cast(GDExtensionVariantPtr)source);
        target = cast(T)_tmp;
    } else static if (is(T == String)) {

        // String
        string_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == StringName)) {

        // StringName
        string_name_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == NodePath)) {

        // NodePath
        node_path_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == RID)) {

        // RID
        rid_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == VectorImpl!U, U...)) {

        // Vectors
        T.vector_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Quaternion)) {

        // Quaternion
        quaternion_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Color)) {

        // Color
        color_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == RectImpl!U, U...)) {

        // Rectangles
        T.rect_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == AABB)) {

        // AABB
        aabb_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Plane)) {

        // Plane
        plane_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Transform2D)) {

        // Transform2D
        transform2d_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Transform3D)) {

        // Transform3D
        transform3d_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Basis)) {

        // Basis
        basis_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Projection)) {

        // Projection
        projection_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == TypedArray!U, U)) {

        // Arrays
        array_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == PackedArray!U, U)) {

        // Packed Arrays
        T.packed_array_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == TypedDictionary!U, U...)) {

        // Dictionaries
        dictionary_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Callable)) {

        // Callable
        callable_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Signal!U, U...)) {

        // Signal
        signal_from_variant(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T == Variant)) {
        
        // Variant (Copy)
        variant_new_copy(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T : GDEObject)) {

        // Objects
        GDExtensionObjectPtr _tmp;
        object_from_variant(&_tmp, cast(GDExtensionVariantPtr)source);
        target = gde_class_get_or_bind!T(_tmp);
    } else {

        // Unsupported.
        static assert(0, T.stringof~" can't be decoded from a variant, try unwrapping it?");
    }
}

/**
    Decodes a value from a ptrcall pointer.

    Params:
        source = The source data to write.
        target = The target to write to
*/
pragma(inline, true)
void gde_from_ptr(T)(inout(GDExtensionTypePtr) source, ref T target) @nogc {
    static if (is(T == bool)) {

        // bool
        gde_blit(target, source);
    } else static if (__traits(isIntegral, T)) {

        // Signed and unsigned integers.
        GDExtensionInt _tmp;
        gde_blit(_tmp, source);
        target = cast(T)_tmp;
    } else static if (__traits(isFloating, T)) {

        // Floats
        double _tmp;
        gde_blit(_tmp, source);
        target = cast(T)_tmp;
    } else static if (is(T == String)) {

        // String
        gde_blit(target, source);
    } else static if (is(T == StringName)) {

        // StringName
        gde_blit(target, source);
    } else static if (is(T == NodePath)) {

        // NodePath
        gde_blit(target, source);
    } else static if (is(T == RID)) {

        // RID
        gde_blit(target, source);
    } else static if (is(T == VectorImpl!U, U...)) {

        // Vectors
        gde_blit(target, source);
    } else static if (is(T == Quaternion)) {

        // Quaternion
        gde_blit(target, source);
    } else static if (is(T == Color)) {

        // Color
        gde_blit(target, source);
    } else static if (is(T == RectImpl!U, U...)) {

        // Rectangles
        gde_blit(target, source);
    } else static if (is(T == AABB)) {

        // AABB
        gde_blit(target, source);
    } else static if (is(T == Plane)) {

        // Plane
        gde_blit(target, source);
    } else static if (is(T == Transform2D)) {

        // Transform2D
        gde_blit(target, source);
    } else static if (is(T == Transform3D)) {

        // Transform3D
        gde_blit(target, source);
    } else static if (is(T == Basis)) {

        // Basis
        gde_blit(target, source);
    } else static if (is(T == Projection)) {

        // Projection
        gde_blit(target, source);
    } else static if (is(T == TypedArray!U, U)) {

        // Arrays
        gde_blit(target, source);
    } else static if (is(T == PackedArray!U, U)) {

        // Packed Arrays
        gde_blit(target, source);
    } else static if (is(T == TypedDictionary!U, U...)) {

        // Dictionaries
        gde_blit(target, source);
    } else static if (is(T == Callable)) {

        // Callable
        gde_blit(target, source);
    } else static if (is(T == Signal!U, U...)) {

        // Signal
        gde_blit(target, source);
    } else static if (is(T == Variant)) {
        
        // Variant
        variant_new_copy(&target, cast(GDExtensionVariantPtr)source);
    } else static if (is(T : GDEObject)) {

        // Objects
        if (source) {
            target = gde_class_get_or_bind!T(source);
        }
    } else {

        // Others
        gde_blit(source, target);
    }
}

/**
    Gets a Godot compatible pointer for a given value.

    Params:
        value = Value to get the pointer of.

    Returns:
        A pointer to the given value that is compatible with godot.
*/
pragma(inline, true)
GDExtensionTypePtr gde_ptrof(T)(ref return scope T value) @nogc {
    static if (is(T : GDEObject)) {

        return value ? value.ptr : null;
    } else {

        return &value;
    }
}

/**
    The storage type for a given type.
*/
template storageOf(T) {
    static if (is(T == GDEObject))
        alias storageOf = GDExtensionObjectPtr;
    else
        alias storageOf = T;
}

/**
    Returns a stack allocated type, with the size of the largest parameter.
*/
template PStackVar(Args...) {
    template PSize(Args...) {
        template Select(bool cond, T...)
        if (T.length == 2) {
            alias Select = T[!cond];
        }

        template Largest(TArgs...) {
            alias Largest = TArgs[0];
            static foreach(U; TArgs[1..$])
                Largest = Select!(U.sizeof > Largest.sizeof, U, Largest);
        }

        enum PSize = Largest!(Args).sizeof;
    }

    static if (Args.length > 0)
        alias PStackVar = void[PSize!(Args)];
    else
        alias PStackVar = void;
}

/**
    Internally used function to blit data without calling copy-constructors, etc.

    Params:
        to =    The value to blit to
        from =  The value to blit from

    Note:
        No postblits, copy constructors or move constructors will be called by this function!
*/
void gde_blit(T)(inout(void*) to, auto ref T from) @nogc @system nothrow {
    if (to)
        nu_memcpy(cast(void*)to, const_cast!(Unqual!T*)(&from), T.sizeof);
}

/**
    Internally used function to blit data without calling copy-constructors, etc.

    Params:
        to =    The value to blit to
        from =  The value to blit from

    Note:
        No postblits, copy constructors or move constructors will be called by this function!
*/
void gde_blit(T)(auto ref T to, inout(void*) from) @nogc @system nothrow {
    if (from)
        nu_memcpy(const_cast!(Unqual!T*)(&to), cast(void*)from, T.sizeof);
}