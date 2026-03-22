/**
    Module which implements functions to create and delete
    Godot objects.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.lifetime;
import godot.core.gdextension;
import godot.core.object;
import godot.core.traits;
import godot.variant;

public import numem.core.math;
public import numem.core.lifetime;
public import numem.lifetime;

/**
    Constructs a new type using the godot allocator.

    Params:
        args = arguments to pass to the type's constructor.

    Returns:
        A new object of the given type.
*/
Ref!T gd_new(T, Args...)(Args args) @trusted @nogc {
    static if (is(T : GDEObject)) {
        
        return gde_alloc_class!T();
    } else {
        Ref!T mem = cast(Ref!T)nu_malloc(AllocSize!T, true);
        nogc_construct(mem, args);
        return mem;
    }
}

/**
    Frees a given godot object.

    Params:
        value = The given value to free.
*/
void gd_delete(T)(ref T value) @trusted @nogc {
    import numem.core.hooks : nu_free;
    static if (is(T : GDEObject)) {
        static if(is(typeof(value.__xdtor)))
            value.__xdtor();
        
        object_destroy(value.ptr);
    } else {
        static if (isPointer!T)
            T* p_value = value;
        else
            T* p_value = &value;

        static if (is(T == Variant))
            variant_destroy(p_value);
        else static if(is(T == StringName))
            string_name_destroy(p_value);
        else static if(is(T == NodePath))
            node_path_destroy(p_value);
        else static if(is(T == RID))
            rid_destroy(p_value);
        else static if(is(T == Callable))
            callable_destroy(p_value);
        else static if(is(T == Signal))
            signal_destroy(p_value);
        else static if(is(T == Dictionary!U, U...))
            signal_destroy(p_value);
        else static if(is(T == Array!U, U...))
            array_destroy(p_value);
        else static if(is(T == PackedByteArray))
            packed_byte_array_destroy(p_value);
        else static if(is(T == PackedInt32Array))
            packed_int32_array_destroy(p_value);
        else static if(is(T == PackedInt64Array))
            packed_int64_array_destroy(p_value);
        else static if(is(T == PackedFloat32Array))
            packed_float32_array_destroy(p_value);
        else static if(is(T == PackedFloat64Array))
            packed_float64_array_destroy(p_value);
        else static if(is(T == PackedVector2Array))
            packed_vector2_array_destroy(p_value);
        else static if(is(T == PackedVector3Array))
            packed_vector3_array_destroy(p_value);
        else static if(is(T == PackedVector4Array))
            packed_vector4_array_destroy(p_value);
        else static if(is(T == PackedColorArray))
            packed_color_array_destroy(p_value);
        else static if(is(T == PackedStringArray))
            packed_string_array_destroy(p_value);

        static if (isPointer!T)
            nu_free(value);
        
        value = T.init;
    }
}

/**
    Gets a GDE Object from its native pointer.

    Note:
        This does not call the class constructor.
        The class must be able to work with the
        class initializer.

        Abstract classes cannot be wrapped.

    Params:
        ptr =   The native Godot pointer.
    
    Returns:
        The wrapped object, either fetched directly from the object
        or wrapped on the spot if no bindings were found.
*/
T gde_get(T)(GDExtensionObjectPtr ptr) @trusted @nogc
if (is(T : GDEObject)) {
    
    // If object already has a binding, return it.
    if (auto obj = gde_class_get!T(ptr))
        return obj;
    
    // No object to bind.
    if (ptr is null)
        return null;

    // Object needs to be allocated.
    return gde_class_bind_instance!T(ptr);
}