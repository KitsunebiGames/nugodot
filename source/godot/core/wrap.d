/**
    Utilities for wrapping D types for Godot.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.wrap;
import godot.core.gdextension;
import godot.core.object;
import godot.core.traits;
import godot.core.lifetime;
import godot.variant;
import numem.core.hooks;

// UDAs
public import godot.core.attribs;

/**
    Gets a GDExtension MethodBindPtr for a given name and hash.

    Params:
        name =      Name of the binding to get.
        hash =      Hash of the binding to get.
    
    Returns:
        A method bind for the given name and hash on success,
        $(D null) otherwise.
*/
GDExtensionMethodBindPtr gde_get_method_bind(ClassT)(string name, long hash) @nogc nothrow {
    auto p_classname = gde_make_string_name(classNameOf!ClassT);
    auto p_methodname = gde_make_string_name(name);
    auto p_method = classdb_get_method_bind(p_classname, p_methodname, hash);
    gde_free_string_name(p_classname);
    gde_free_string_name(p_methodname);
    return p_method;
}

/**
    Gets a GDExtension MethodBindPtr for a given classname, name and hash.

    Params:
        className = Name of the class to get the method bind for.
        name =      Name of the binding to get.
        hash =      Hash of the binding to get.
    
    Returns:
        A method bind for the given classname, name and hash on success,
        $(D null) otherwise.
*/
GDExtensionMethodBindPtr gde_get_method_bind(string className, string name, long hash) @nogc nothrow {
    auto p_classname = gde_make_string_name(className);
    auto p_methodname = gde_make_string_name(name);
    auto p_method = classdb_get_method_bind(p_classname, p_methodname, hash);
    gde_free_string_name(p_classname);
    gde_free_string_name(p_methodname);
    return p_method;
}

/**
    Gets a GDExtension GDExtensionPtrBuiltInMethod for a given variant type, name and hash.

    Params:
        type =  Type of the variant to get the method for..
        name =  Name of the binding to get.
        hash =  Hash of the binding to get.
    
    Returns:
        A function pointer to the builtin method.
*/
GDExtensionPtrBuiltInMethod gde_get_builtin_method(GDExtensionVariantType type, string name, long hash) @nogc nothrow {
    auto p_methodname = gde_make_string_name(name);
    auto p_method = variant_get_ptr_builtin_method(type, p_methodname, hash);
    gde_free_string_name(p_methodname);
    return p_method;
}

/**
    Binds a native godot method by name and hash and calls it.

    Params:
        ptr =   Pointer to the type that the method should be called on.
        args =  Arguments to pass to the function.
    
    Returns:
        Return value depends on template, refer to Godot's
        documentation.
*/
RetT gde_bind_and_call(GDExtensionVariantType type, string name, uint hash, RetT = void, Args...)(GDExtensionTypePtr ptr, Args args) @nogc {
    __gshared GDExtensionPtrBuiltInMethod __bind;
    if (!__bind)
        __bind = gde_get_builtin_method(type, name, hash);
    
    void*[Args.length] __params;
    static foreach_reverse(i, arg; args) {
        static if (is(typeof(param) : GDEObject))
            __params[i] = arg.ptr;
        else
            __params[i] = &arg;
    }

    static if (!is(RetT == void)) {
        RetT rval = void;

        __bind(ptr, __params.ptr, &rval, cast(int)Args.length);
        return rval;
    } else {
        __bind(ptr, __params.ptr, null, cast(int)Args.length);
    }
}

/**
    Binds a variant operator and calls it.

    Params:
        a = The left hand side of the operator.
        b = The right hand side of the operator.
    
    Returns:
        Return value depends on template, refer to Godot's
        documentation.
*/
GDExtensionInt get_bind_op_and_call(GDExtensionVariantOperator poperator, GDExtensionVariantType vta, GDExtensionVariantType vtb)(GDExtensionConstTypePtr a, GDExtensionConstTypePtr b) @nogc nothrow {
    __gshared GDExtensionPtrOperatorEvaluator __bind;
    if (!__bind)
        __bind = variant_get_ptr_operator_evaluator(poperator, vta, vtb);
    
    GDExtensionInt ret;
    __bind(a, b, &ret);
    return ret;
}

/**
    Binds a native godot method by name and hash and calls it.

    Params:
        args = Arguments to pass to the function.
    
    Returns:
        Return value depends on template, refer to Godot's
        documentation.
*/
RetT gde_bind_and_call(string classname, string name, uint hash, RetT = void, Args...)(GDExtensionTypePtr ptr, Args args) @nogc {
    __gshared GDExtensionMethodBindPtr __bind;
    if (!__bind)
        __bind = gde_get_method_bind(classname, name, hash);
    
    return gde_ptrcall!(RetT)(ptr, __bind, args);
}

/**
    Binds and calls a godot type constructor.

    Params:
        args = Arguments to pass to the function.
    
    Returns:
        Return value depends on template, refer to Godot's
        documentation.
*/
void gde_bind_and_call_ctor(T, int ctor, Args...)(GDExtensionUninitializedTypePtr obj, Args args) @nogc {
    __gshared GDExtensionPtrConstructor __bindfn;
    if (!__bindfn)
        __bindfn = cast(GDExtensionPtrConstructor)variant_get_ptr_constructor(variantTypeOf!T, ctor);
    
    static if (Args.length > 0) {
        GDExtensionConstTypePtr[Args.length] __params;
        static foreach(i; 0..Args.length) {
            __params[i] = args[i];
        }
        __bindfn(obj, __params.ptr);
    } else {
        __bindfn(obj, null);
    }
}

/**
    Binds and calls a godot type constructor.

    Params:
        args = Arguments to pass to the function.
    
    Returns:
        Return value depends on template, refer to Godot's
        documentation.
*/
void gde_bind_and_call_ctor(GDExtensionVariantType VT, int ctor, Args...)(GDExtensionUninitializedTypePtr obj, Args args) @nogc {
    __gshared GDExtensionPtrConstructor __bindfn;
    if (!__bindfn)
        __bindfn = cast(GDExtensionPtrConstructor)variant_get_ptr_constructor(VT, ctor);
    
    static if (Args.length > 0) {
        GDExtensionConstTypePtr[Args.length] __params;
        static foreach(i; 0..Args.length) {
            __params[i] = args[i];
        }
        __bindfn(obj, __params.ptr);
    } else {
        __bindfn(obj, null);
    }
}

/**
    Registers an extension class by name, parent class name and creation info.

    Params:
        className =         Name of the class to register
        parentClassName =   Name of the parent class to register.
        info =              Information to register.
*/
void gde_register_extension_class(string className, string parentClassName, ref GDExtensionClassCreationInfo5 info) @nogc {
    StringName* p_classname = gde_make_string_name(className);
    StringName* p_parent_classname = gde_make_string_name(parentClassName);
    classdb_register_extension_class5(__godot_class_library, p_classname, p_parent_classname, &info);
    gde_free_string_name(p_classname);
    gde_free_string_name(p_parent_classname);
}

/**
    Unregisters an extension class.
    
    Params:
        className = The name of the extension class to unregister.
*/
void gde_unregister_extension_class(string className) @nogc {
    StringName* p_classname = gde_make_string_name(className);
    classdb_unregister_extension_class(__godot_class_library, p_classname);
    gde_free_string_name(p_classname);
}

/**
    Calls a function on a given object object.

    Params:
        obj =       The object to call the method on.
        method =    The method bind instance to call.
        args =      The arguments to the function.

    Returns:
        The return value of the method bind
*/
RetT gde_ptrcall(RetT = void, Args...)(GDExtensionTypePtr obj, GDExtensionMethodBindPtr method, auto ref Args args) @nogc @system {

    // Fill out arguments
    GDExtensionConstTypePtr[Args.length] args_;
    static foreach(int i; 0..Args.length) {
        {
            auto __tmp = gde_to_gd(args[i]);
            args_[i] = &__tmp;
        }
    }
    
    // Call
    static if (!is(RetT == void)) {
        wrapTypeOf!RetT ret_ = void;
        object_method_bind_ptrcall(method, obj, args_.ptr, &ret_);
        return gde_from_gd!RetT(&ret_);
    } else {
        object_method_bind_ptrcall(method, obj, args_.ptr, null);
    }
}

/**
    Calls a static function.

    Params:
        method =    The method bind instance to call.
        args =      The arguments to the function.

    Returns:
        The return value of the method bind
*/
RetT gde_ptrcall_static(RetT = void, Args...)(GDExtensionMethodBindPtr method, auto ref Args args) @nogc @system {

    // Fill out arguments
    GDExtensionConstTypePtr[Args.length] args_;
    static foreach(int i; 0..Args.length) {
        {
            auto __tmp = gde_to_gd(args[i]);
            args_[i] = &__tmp;
        }
    }

    // Call
    static if (!is(RetT == void)) {
        wrapTypeOf!RetT ret_;
        object_method_bind_ptrcall(method, null, args_.ptr, &ret_);
        return gde_from_gd!RetT(&ret_);
    } else {
        object_method_bind_ptrcall(method, null, args_.ptr, null);
    }
}

/**
    Gets an instance of the given function for the given type,
    while respecting virtual functions.

    Notes:
        The function returned is stripped of all of its normal attributes,
        this function is **UNSAFE** unless you know what you're doing.

    Params:
        instance =  The class instance.
        method =    The method to get.
*/
auto gde_get_func_instance(T, string method)() @system @nogc nothrow {
    alias methodT = __traits(getMember, T, method);
    alias rt = returnTypeOf!methodT function(T, parametersOf!methodT) @nogc nothrow;

    static if (__traits(isVirtualMethod, methodT)) {
        enum vtblOffset = __traits(getVirtualIndex, methodT);

        T p_instance = cast(T)__traits(initSymbol, T).ptr;
        return cast(rt)p_instance.__vptr[vtblOffset];
    } else {
        pragma(mangle, methodT.mangleof)
        static extern returnTypeOf!(methodT) __func (T, parametersOf!methodT) @nogc nothrow;

        return cast(rt)&__func;
    }
}

/**
    Gets an instance of the given function for the given type,
    while respecting virtual functions.

    Notes:
        The function returned is stripped of all of its normal attributes,
        this function is **UNSAFE** unless you know what you're doing.

    Params:
        instance =  The class instance.
        method =    The method to get.
*/
auto gde_get_func_instance(T, alias method)() @system @nogc nothrow {
    alias methodT = FunctionTypeOf!method;
    alias rt = returnTypeOf!methodT function(T, parametersOf!methodT) @nogc nothrow;

    static if (__traits(isVirtualMethod, method)) {
        enum vtblOffset = __traits(getVirtualIndex, method);

        T p_instance = cast(T)__traits(initSymbol, T).ptr;
        return cast(rt)p_instance.__vptr[vtblOffset];
    } else {
        pragma(mangle, method.mangleof)
        static extern returnTypeOf!(method) __func (T, parametersOf!method) @nogc nothrow;

        return cast(rt)&__func;
    }
}

/**
    Calls a native function from a godot virtual call.
*/
void gde_gdcall(FuncT, ClassT)(FuncT fn, ClassT p_instance, const(GDExtensionConstTypePtr)* pargs, GDExtensionTypePtr rret) @nogc
if (is(FuncT == return)) {
    alias pTypes = parametersOf!FuncT;
    alias rType = wrapTypeOf!(returnTypeOf!FuncT);
    
    pTypes __params;
    __params[0] = p_instance;
    static foreach(i; 1..pTypes.length) {
        __params[i] = gde_from_gd!(pTypes[i])(pargs[i-1]);
    }

    static if (!is(rType == void)) {
        *(cast(rType*)rret) = gde_to_gd(fn(__params));
    } else {
        fn(__params);
    }
}

/**
    Wraps a given method of a class with a godot ptrcall wrapper.

    Params:
        T =         The class to wrap a function for
        method =    Alias of the method to wrap.
*/
pragma(inline, true)
GDExtensionClassMethodPtrCall gde_wrap_method_ptrcall(T, alias method)() @nogc
if (is(T : GDEObject)) {
    extern(C) GDExtensionClassMethodPtrCall fn = cast(GDExtensionClassMethodPtrCall)(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc {
        alias ReturnType = returnTypeOf!method;
        alias Params = parametersOf!method;
        
        T obj_ = cast(T)p_instance;

        // Get parameters.
        Params __args = void;
        static foreach(i; 0..__args.length) {
            __args[i] = *(cast(typeof(__args[i])*)p_args[i]);
        }

        // Call.
        static if (!is(ReturnType == void)) {

            auto __ret = gde_to_gd(__traits(getMember, obj_, __traits(identifier, method))(__args));
            *(cast(typeof(__ret)*)r_ret) = __ret;
        }
        else {

            __traits(getMember, obj_, __traits(identifier, method))(__args);
        }
    };

    return fn;
}

/**
    Wraps a given method of a class with a godot variant call wrapper.

    Params:
        T =         The class to wrap a function for.
        method =    Alias of the method to wrap.
*/
pragma(inline, true)
GDExtensionClassMethodCall gde_wrap_method_call(T, alias method)() @nogc {
    extern(C) GDExtensionClassMethodCall fn = cast(GDExtensionClassMethodCall)(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) {
        alias ReturnType = returnTypeOf!method;
        alias Params = parametersOf!method;

        if (p_argument_count < Params.length) {

            // Too few args
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
            r_error.expected = Params.length;
            return;
        }

        if (p_argument_count > Params.length) {
            // Too many arguments.
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
            r_error.expected = Params.length;
            return;
        }

        T obj_ = cast(T)p_instance;
        if (!obj_) {

            // Invalid instance.
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        // Unwrap the arguments into ones that the DLang side understands.
        Params __args;
        static foreach(i; 0..Params.length) {
            static if (is(typeof(() => Params[i].init.move())))
                __args[i] = gde_unwrap!(Params[i])(*cast(Variant*)p_args[i]).move();
            else
                __args[i] = gde_unwrap!(Params[i])(*cast(Variant*)p_args[i]);
        }

        // Wrap the return value to something that Godot understands, if needed.
        auto fn = gde_get_func_instance!(T, method);
        static if (!is(ReturnType == void)) {
            *(cast(Variant*)r_return) = gde_wrap!ReturnType(fn(obj_, __args));
        } else {
            fn(obj_, __args);
        }
    };
    
    return fn;
}

/**
    Makes a property info for a given type.

    Params:
        name =          Name for the property.
        hint =          Hint for the property.
        hintString =    Hint string for the property.
        usageFlags =    Usage flags for the property.

    Returns:
        A property info that must be freed with $(D gde_destroy_property_info)
        after use.

    See_Also:
        $(D gde_destroy_property_info)
*/
pragma(inline, true)
GDExtensionPropertyInfo gde_make_property_info(T)(string name, uint hint = 0, string hintString = null, uint usageFlags = 6) @nogc {
    static if (is(T : GDEObject))
        string class_name = classNameOf!T;
    else
        string class_name;

    //  NOTE:   Godot cannot automatically detect more complex types like 
    //          typed arrays, so we need to build hint strings for it.
    //          The following block does so.
    String* p_hint_string = gde_make_string(hintString);
    StringName* p_name = gde_make_string_name(name);
    StringName* p_classname = gde_make_string_name(class_name);
    return GDExtensionPropertyInfo(
        type: variantTypeOf!T,
        name: p_name,
        class_name: p_classname,
        hint: hint,
        hint_string: p_hint_string,
        usage: usageFlags,
    );
}

/**
    Destroys a $(D GDExtensionPropertyInfo) created by $(D gde_make_property_info).

    Params:
        info = The property info to destroy.

    See_Also:
        $(D gde_make_property_info)
*/
pragma(inline, true)
void gde_destroy_property_info(ref GDExtensionPropertyInfo info) @nogc {
    gde_free_string_name(cast(StringName*)info.name);
    gde_free_string_name(cast(StringName*)info.class_name);
    gde_free_string(cast(String*)info.hint_string);
}

/**
    Gets a singleton by name.

    Params:
        name = The name of the singleton to get.
    
    Returns:
        The singleton if successful,
        $(D null) otherwise.
*/
T gde_get_singleton(T)(string name)
if (is(T : GDEObject)) {
    __gshared T __singleton_instance;
    if (!__singleton_instance) {
        StringName* p_name = gde_make_string_name(name);
        
        void* s_ptr = global_get_singleton(p_name);
        __singleton_instance = gde_alloc_singleton!T(s_ptr);
        gde_free_string_name(p_name);
    }

    return __singleton_instance;
}

/**
    Converts a given D value to its Godot equivalent.

    Params:
        value = the value to convert to a godot equivalent.
*/
pragma(inline, true)
auto gde_to_gd(T)(auto ref T value) @nogc {
    static if (is(T : GDEObject))
        return value.ptr;
    else static if (is(T == bool))
        return value;
    else static if (is(T == string))
        return String(value);
    else static if (is(T == U[], U) && is(PackedArray!U))
        return gde_to_packed_array(value);
    else static if (__traits(isIntegral, T))
        return cast(GDExtensionInt)value;
    else static if (__traits(isFloating, T))
        return cast(double)value;
    else 
        return value;
}

/**
    Converts a given Godot value to a given D equivalent.

    Params:
        value = the value to convert to a D equivalent.
*/
pragma(inline, true)
T gde_from_gd(T)(GDExtensionConstTypePtr value) @nogc {
    if (!value)
        return T.init;

    static if (is(T : GDEObject))
        return gde_get!T(cast(GDExtensionObjectPtr)value);
    else static if (is(T == string))
        return *(cast(String*)value).toString();
    else static if (is(T == U[], U) && is(PackedArray!U))
        return gde_from_packed_array(*(cast(PackedArray!(U)*)value));
    else static if (__traits(isIntegral, T))
        return cast(T)*(cast(GDExtensionInt*)value);
    else static if (__traits(isFloating, T))
        return cast(T)*(cast(double*)value);
    else
        return *(cast(T*)value);
}

/**
    Wraps the given D type in a variant.

    Params:
        value = The value to wrap.

    Returns:
        The wrapped value.
*/
Variant gde_wrap(T)(auto ref T value) @nogc {
    static if (is(T == Variant)) {
        return value;
    } else {
        return Variant(value);
    }
}

/**
    Unwraps the given variant to a D type.

    Params:
        from = The variant to unwrap.

    Returns:
        The unwrapped value.
*/
T gde_unwrap(T)(auto ref Variant from) @nogc
if (variantTypeOf!T != GDEXTENSION_VARIANT_TYPE_NIL) {
    import numem.core.traits : BaseElemOf;
    import godot.core.lifetime : gde_get;
        
    static if (is(T == bool)) {
        
        bool result;
        bool_from_variant(&result, &from);
    } else static if (__traits(isIntegral, T)) {

        static if (__traits(isUnsigned, T))
            ulong result;
        else
            long result;
        
        int_from_variant(&result, &from);
        return cast(T)result;
    } else static if (__traits(isFloating, T)) {

        double result;
        float_from_variant(&result, &from);
        return cast(T)result;
    } else static if (is(T == string)) {
        
        return String(from).toString();
    } else static if (is(T : GDEObject)) {
        
        GDExtensionObjectPtr result;
        object_from_variant(&result, &from);
        return gde_get!T(result);
    } else {
        return T(from);
    }
}