/**
    Module which implements the needed infrastructure to wrap
    Godot objects with D objects.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.object;
import godot.core.gdextension;
import godot.core.lifetime;
import godot.core.attribs;
import godot.core.traits;
import godot.core.wrap;
import godot.core;
import godot.variant.variant;
import godot.variant.string;
import numem;

public import godot.core.registration : GodotClass;

/**
    Base class for all wrapped Godot objects.

    Godot Objects *must* be constructed with `gde_new`!
*/
abstract
class GDEObject : NuObject {
private:
@nogc:
    GDExtensionObjectPtr ptr_;

protected:

    /**
        Called when the object gets a notification.

        Params:
            what =      What notification was recieved.
            reversed =  Whether the order of operations is reversed.
    */
    void onNotification(int what, bool reversed) { }

public:

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_OBJECT;

    /**
        Gets the underlying godot object pointer.
    */
    final @property ref GDExtensionObjectPtr ptr() @system nothrow pure => ptr_;

    /**
        Instance ID of the object.
    */
    final @property GDObjectInstanceID id() @system nothrow => object_get_instance_id(ptr_);

    /**
        Sets the given property to the given value.

        Params:
            name =  The name of the property.
            value = The value to set.
        
        Returns:
            Whether the operation succeeded.
    */
    bool set(in StringName name, in Variant value) { return false; }

    /**
        Sets the given property to the given value.

        Params:
            name =  The name of the property.
            dest =  The destination value to store the value in. 
        
        Returns:
            Whether the operation succeeded.
    */
    bool get(in StringName name, ref Variant dest) { return false; }

    /**
        Gets whether a property with the given name can be
        reverted.

        Params:
            name = The name of the property.
        
        Returns:
            $(D true) if the property can be reverted,
            $(D false) otherwise.
    */
    bool canRevertProperty(in StringName name) { return false; }

    /**
        Gets the value the given named property will be reverted to.

        Params:
            name = The name of the property.
            dest =  The destination value to store the value in. 
        
        Returns:
            $(D true) if the operation succeded,
            $(D false) otherwise.
    */
    bool getPropertyRevert(in StringName name, ref Variant dest) { return false; }

    /**
        Gets a string representation of this type.
    */
    override string toString() { return typeid(this).name; }

    /**
        Performs casts
    */
    T opCast(T)() const {
        static if (is(T == GDEObject)) {
            return reinterpret_cast!GDEObject(this);
        } else static if (is(T : GDEObject)) {
            return gde_class_cast!T(cast(Unqual!(typeof(this)))this);
        } else static if (is(T == Object)) {
            return reinterpret_cast!(Object)(this);
        } else static if (is(T == Variant)) {
            return gde_wrap(this);
        } else static if (is(T == void*)) {
            return reinterpret_cast!(void*)(this);
        } else {
            static assert(0, "Cannot cast GDEObject to type "~T.stringof);
        }
    }
}

/**
    Calls a function by name and hash on this object instance.

    This function is provided as an escape hatch if you need
    to call a function not exposed by the API, it is *not*
    optimal.

    Params:
        name = The name of the method to call.
        hash = Hash of the method's signature.
        args = Arguments to pass to the method.
    
    Returns:
        The return value of the method called.
*/
RetT call(RetT = void, ClassT, Args...)(ClassT klass, string name, long hash, auto ref Args args) {
    return gde_ptrcall!(RetT, Args)(klass.ptr, gde_get_method_bind!(ClassT)(name, hash), args);
}

/**
    Allocates a class for the given type and object pointer.
    
    Returns:
        A newly allocated wrapper class.
*/
T gde_alloc_class(T)() @system @nogc
if (is(T : GDEObject)) {
    import numem.core.hooks : nu_malloc, nu_memcpy;
    import godot.variant : Signal;

    static if (is(T PT == super)) {
        static if (!__traits(isAbstractClass, T)) {

            // Construct the native class
            void* p_object = gde_class_construct(classNameOf!(godotBaseOf!T));

            // Construct the class instance.
            T p_instance = gde_class_alloc_empty!T();
            gde_class_assign(p_object, p_instance);
            gde_class_bind_signals(p_instance);
            return p_instance;
        } else {

            assert(0, "Tried to instantiate an abstract class!");
            return null;
        }
    }
}

/**
    Frees a class instance.

    Params:
        object = The object instance to free.
*/
void gde_free_class(T)(ref T object) @system @nogc
if (is(T : GDEObject)) {
    void* objptr = reinterpret_cast!(void*)(object);
    if (objptr) {
        static if (is(typeof(T.__xdtor)))
            object.__xdtor();
        else static if (is(typeof(T.__dtor)))
            object.__dtor();
        
        nu_free(objptr);
        object = null;
    }
}

/**
    Constructs a non-bound Godot class with the given name.

    Params:
        classname = The name of the class to construct.
    
    Returns:
        The constructed object.
*/
GDExtensionObjectPtr gde_class_construct(string classname) @nogc nothrow {

    // Construct a godot object
    StringName* p_classname = gde_make_string_name(classname);
    void* p_object = classdb_construct_object2(p_classname);
    gde_free_string_name(p_classname);
    return p_object;
}

/**
    Allocates an uninitialized instance of the given class.
*/
T gde_class_alloc_empty(T)() @system @nogc {
    T obj = cast(T)nu_malloc(AllocSize!T);
    nu_memcpy(reinterpret_cast!(void*)(obj), __traits(initSymbol, T).ptr, __traits(initSymbol, T).length);
    return obj;
}

/**
    Binds a class for a non-instantiable singleton.

    Params:
        ptr = The object pointer to associate with the class.
    
    Returns:
        A newly allocated wrapper class.
*/
T gde_class_bind_singleton(T)(GDExtensionObjectPtr ptr) @system @nogc
if (is(T : GDEObject)) {
    import godot.variant : Signal;
    
    T p_instance = gde_class_alloc_empty!T();
    gde_class_assign!T(ptr, p_instance);
    gde_class_bind_signals(p_instance);
    return p_instance;
}

/**
    Binds a D class instance to a Godot object. 

    Params:
        p_object = The object to attach a binding to.
    
    Returns:
        A newly allocated wrapper class.
*/
T gde_class_bind_instance(T)(inout(GDExtensionObjectPtr) p_object) @system @nogc {

    // NOTE:    Allocate and base-initialize the class.
    //          This will NOT call any constructors.
    T p_instance = gde_class_alloc_empty!T();
    gde_class_assign(p_object, p_instance);
    gde_class_bind_signals(p_instance);
    return p_instance;
}

/**
    Gets a bound D class for a godot class.

    Params:
        p_object = The object to fetch.
*/
T gde_class_get(T)(inout(GDExtensionObjectPtr) p_object) @system @nogc {

    // 1. No object to have bindings.
    if (p_object is null)
        return null;

    // 2. Try to get binding without callbacks.
    if (auto p_binding = object_get_instance_binding(cast(GDExtensionObjectPtr)p_object, __godot_class_library, null))
        return cast(T)p_binding;

    // 3. Try with native godot callbacks
    if (auto p_binding = object_get_instance_binding(cast(GDExtensionObjectPtr)p_object, __godot_class_library, &__nu_gde_instance_callbacks!T))
        return cast(T)p_binding;
    
    // 4. No bindings.
    return null;
}

/**
    Gets or creates a DLang binding for a given object.

    Params:
        p_object = The object to fetch.
*/
T gde_class_get_or_bind(T)(inout(GDExtensionObjectPtr) p_object) @system @nogc {
    if (p_object is null)
        return null;

    if (auto p_binding = gde_class_get!T(p_object))
        return p_binding;

    // No bindings, create one.
    return gde_class_bind_instance!T(p_object);
}

/**
    Assigns a D class to a Godot class instance.

    Params:
        p_object =      The object instance
        p_instance =    The instance to assign to the class.
*/
void gde_class_assign(T)(inout(GDExtensionObjectPtr) p_object, T p_instance) @system @nogc {
    // Refer to our D object in the Godot instance.
    StringName* p_classname = gde_make_string_name(classNameOf!T);
    static if (!isGodotNativeClass!T) {
        object_set_instance(cast(GDExtensionObjectPtr)p_object, p_classname, cast(void*)p_instance);
        if (object_get_instance_binding(cast(GDExtensionObjectPtr)p_object, __godot_class_library, null) is null)
    object_set_instance_binding(cast(GDExtensionObjectPtr)p_object, __godot_class_library, cast(void*)p_instance, &__nu_gde_instance_callbacks!T);
    }
    gde_free_string_name(p_classname);

    // Refer back to our object in our bound instance.
    (cast(GDEObject)p_instance).ptr_ = cast(GDExtensionObjectPtr)p_object;
    
    // Call type base constructor while we're at it.
    static if (is(typeof(() => T.init.__ctor())))
        p_instance.__ctor();
}

/**
    Binds signals for the given class instance.

    Params:
        p_instance = the instance to bind.
*/
void gde_class_bind_signals(T)(T p_instance) @nogc {
    StringName* p_signalname;
    static foreach(signal; boundSignalsOf!T) {
        p_signalname = gde_make_string_name(signalNameOf!(__traits(getMember, T, signal)));
        __traits(getMember, p_instance, signal) = typeof(__traits(getMember, T, signal))(p_instance, p_signalname);
        gde_free_string_name(p_signalname);
    }
}

/**
    Performs an upcast on a class, reallocating it if need be.

    Params:
        from = The class to cast from.
    
    Returns:
        The reallocated, casted class,
        or $(D null) if casting was not possible.
*/
TTo gde_class_cast(TTo, TFrom)(TFrom from) @system @nogc
if (is(TFrom : GDEObject) && is(TTo : GDEObject)) {
    static if (is(TTo : TFrom)) {

        // Downcast
        return reinterpret_cast!(TTo)(from);
    } else {
        
        // Already compatible upcast.
        if (from.classinfo is typeid(TTo))
            return reinterpret_cast!(TTo)(from);
        
        void* p_gdobject = from.nativePtr_;
        void* p_dobject = cast(void*)from;

        // Information needed to retain local variables.
        size_t p_dobject_offset = from.classinfo.initializer.length;
        size_t p_gdeobject_size = __traits(classInstanceSize, GDEObject);

        // In-place upcast.
        StringName p_classname;
        if (object_get_class_name(p_gdobject, __godot_class_library, &p_classname)) {
            if (auto nptr = object_cast_to(p_gdobject, classdb_get_class_tag(&p_classname))) {

                // 1.   Reallocate the object's memory, if need be.
                static if (__traits(classInstanceSize, TFrom) < __traits(classInstanceSize, TTo))
                    p_dobject = nu_realloc(p_dobject, __traits(initSymbol, TTo).sizeof);

                // 2.   Re-initialize the GDEObject sub-object to its base state,
                //      writing our new VTable in the process.
                auto p_dobject_init = __traits(initSymbol, TTo);
                nu_memcpy(p_dobject, p_dobject_init.ptr, p_gdeobject_size);
                
                // 3.   Fill out new initializer information at the end.
                if (p_dobject_offset < p_dobject_init.length)
                    nu_memcpy(p_dobject+p_dobject_offset, p_dobject_init+p_dobject_offset, p_dobject_init.length-p_dobject_offset);

                // 4.   Re-write our object pointer to it.
                (cast(GDEObject)p_dobject).nativePtr_ = nptr;

                // 4.   Update the godot instance binding.
                object_set_instance(nptr, &p_classname, p_dobject);
                return reinterpret_cast!(TTo)(p_dobject);
            }
        }

        // Invalid upcast.
        return null;
    }
}

//
//              IMPLEMENTATION DETAILS
//
private:

template __nu_gde_instance_callbacks(T) {
    static if (isGodotNativeClass!T) {
        pragma(mangle, "__nu_gde_create_callback_"~__traits(identifier, T))
        extern(C) void* __nu_gde_create_callback(void *p_token, void *p_instance) @nogc {
            return gde_class_bind_instance!T(p_instance).ptr;
        }

        pragma(mangle, "__nu_gde_free_callback_"~__traits(identifier, T))
        extern(C) void __nu_gde_free_callback(void *p_token, void *p_instance, void *p_binding) @nogc {
            if (T object = cast(T)p_binding) {
                gde_free_class(object);
            }
        }

        pragma(mangle, "__nu_gde_reference_callback_"~__traits(identifier, T))
        extern(C) ubyte __nu_gde_reference_callback(void *p_token, void *p_instance, GDExtensionBool p_reference) @nogc {
            return true;
        }

        extern(C) __gshared const GDExtensionInstanceBindingCallbacks __nu_gde_instance_callbacks = GDExtensionInstanceBindingCallbacks(
            create_callback: cast(typeof(GDExtensionInstanceBindingCallbacks.create_callback))&__nu_gde_create_callback,
            free_callback: cast(typeof(GDExtensionInstanceBindingCallbacks.free_callback))&__nu_gde_free_callback,
            reference_callback: cast(typeof(GDExtensionInstanceBindingCallbacks.reference_callback))&__nu_gde_reference_callback
        );
    } else {
        extern(C) __gshared const GDExtensionInstanceBindingCallbacks __nu_gde_instance_callbacks = GDExtensionInstanceBindingCallbacks(
            create_callback: null,
            free_callback: null,
            reference_callback: null
        );
    }
}