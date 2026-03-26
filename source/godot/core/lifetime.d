/**
    Module which implements functions to create and delete
    Godot objects.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.lifetime;
import godot.core.gdextension;
import godot.core.attribs;
import godot.core.object;
import godot.core.traits;
import godot.variant;

public import numem.core.math;
public import numem.core.lifetime;
public import numem.lifetime;
import godot.ref_counted;

/**
    Constructs a new type using the godot allocator.

    Params:
        args = arguments to pass to the type's constructor.

    Returns:
        A new object of the given type.
*/
Ref!T gd_new(T, Args...)(Args args) @trusted @nogc {
    static if (is(T : GDEObject)) {
        static assert(!hasUDA!(T, gd_non_instantiable), T.stringof~" is not instantiable!");
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
        if (value) {
            static if(is(typeof(T.__xdtor)))
                value.__xdtor();

            object_destroy(value.ptr);
        }
    } else {
        static if (isPointer!T)
            T* p_value = value;
        else
            T* p_value = &value;

        static if (is(T == Variant))
            variant_destroy(p_value);
        else static if(is(T == String))
            string_destroy(p_value);
        else static if(is(T == StringName))
            string_name_destroy(p_value);
        else static if(is(T == NodePath))
            node_path_destroy(p_value);
        else static if(is(T == RID))
            rid_destroy(p_value);
        else static if(is(T == Callable))
            callable_destroy(p_value);
        else static if(is(T == Signal!U, U...))
            signal_destroy(p_value);
        else static if(is(T == Dictionary!U, U...))
            dictionary_destroy(p_value);
        else static if(is(T == Array!U, U...))
            array_destroy(p_value);
        else static if(is(T == PackedArray!ubyte) || is(T == PackedArray!byte))
            packed_byte_array_destroy(p_value);
        else static if(is(T == PackedArray!uint) || is(T == PackedArray!int))
            packed_int32_array_destroy(p_value);
        else static if(is(T == PackedArray!ulong) || is(T == PackedArray!long))
            packed_int64_array_destroy(p_value);
        else static if(is(T == PackedArray!float))
            packed_float32_array_destroy(p_value);
        else static if(is(T == PackedArray!double))
            packed_float64_array_destroy(p_value);
        else static if(is(T == PackedArray!Vector2))
            packed_vector2_array_destroy(p_value);
        else static if(is(T == PackedArray!Vector3))
            packed_vector3_array_destroy(p_value);
        else static if(is(T == PackedArray!Vector4))
            packed_vector4_array_destroy(p_value);
        else static if(is(T == PackedArray!Color))
            packed_color_array_destroy(p_value);
        else static if(is(T == PackedArray!String))
            packed_string_array_destroy(p_value);

        static if (isPointer!T)
            nu_free(value);
        
        value = T.init;
    }
}

/**
    Adds a reference to a refcounted godot object.

    Params:
        p_rcobject = The object to add a refernece on.

    Returns:
        The referenced object, may be null if godot freed
        the object.
*/
ref T gde_ref(T)(ref return scope T p_rcobject) @nogc
if (is(T : RefCounted)) {
    if (!p_rcobject)
        return p_rcobject;
    
    // Object was freed by godot.
    if (object_get_instance_id(p_rcobject.ptr) == 0) {
        p_rcobject = null;
        return p_rcobject;
    }
    
    p_rcobject.reference();
    return p_rcobject;
}

/**
    Subtracts a reference to a refcounted godot object.

    Params:
        p_rcobject = The object to remove a refernece from.

    Returns:
        The referenced object, may be null if godot freed
        the object.
*/
ref T gde_unref(T)(ref return scope T p_rcobject) @nogc
if (is(T : RefCounted)) {
    if (!p_rcobject)
        return p_rcobject;

    p_rcobject.unreference();
    
    // Object was freed by godot.
    if (object_get_instance_id(p_rcobject.ptr) == 0)
        p_rcobject = null;
    
    return p_rcobject;
}

/**
    Swaps the reference between 2 refcounted classes.

    Params:
        p_old = The old type that will have its refcount lowered.
        p_new = The new type that will have its refcount increased.
    
    Returns:
        The new value, that can be assigned to a D variable.
*/
T gde_refswap(T)(T p_old, T p_new) @nogc
if (is(T : RefCounted)) {
    gde_unref(p_old);
    return gde_ref(p_new);
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