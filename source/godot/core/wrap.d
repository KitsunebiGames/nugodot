/**
    Utilities for wrapping D types for Godot.
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
        void*[Args.length] __params;
        static foreach_reverse(i, arg; args) {
            static if (is(typeof(param) : GDEObject))
                __params[i] = arg.ptr;
            else
                __params[i] = arg;
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
        void*[Args.length] __params;
        static foreach_reverse(i, arg; args) {
            static if (is(typeof(param) : GDEObject))
                __params[i] = arg.ptr;
            else
                __params[i] = arg;
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
    StringName p_classname = className;
    StringName p_parent_classname = parentClassName;
    classdb_register_extension_class5(__godot_class_library, &p_classname, &p_parent_classname, &info);
}

/**
    Unregisters an extension class.
    
    Params:
        className = The name of the extension class to unregister.
*/
void gde_unregister_extension_class(string className) @nogc {
    StringName p_classname = className;
    classdb_unregister_extension_class(__godot_class_library, &p_classname);
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
        static if (is(typeof(args[i]) : GDEObject)) {
            args_[i] = args[i].ptr;
        } else static if (is(typeof(args[i]) == float)) {
            mixin("double __tmp", i.stringof, " = cast(double)args[i];");
            args_[i] = &mixin("__tmp", i.stringof);
        } else static if (__traits(isIntegral, typeof(args[i]))) {
            mixin("GDExtensionInt __tmp", i.stringof, " = cast(GDExtensionInt)args[i];");
            args_[i] = &mixin("__tmp", i.stringof);
        } else {
            args_[i] = &args[i];
        }
    }
    
    // Call
    static if (!is(RetT == void)) {
        static if (is(RetT : GDEObject)) {
            import godot.core.lifetime : gde_get;
            
            GDExtensionObjectPtr objptr_;
            object_method_bind_ptrcall(method, obj, args_.ptr, &objptr_);
            return gde_get!RetT(objptr_);
        } else {
            RetT ret_ = void;
            object_method_bind_ptrcall(method, obj, args_.ptr, &ret_);
            return ret_;
        }
    } else {
        object_method_bind_ptrcall(method, obj, args_.ptr, null);
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
    Calls a native function from a godot virtual call.
*/
void gde_gdcall(FuncT, Args...)(FuncT fn, const(GDExtensionConstTypePtr)* pargs, GDExtensionTypePtr rret, Args args) @nogc
if (is(FuncT == return)) {
    alias pTypes = parametersOf!FuncT;
    alias pTypesGD = pTypes[Args.length..$];

    pTypes __params;
    static foreach(i; 0..Args.length) {
        __params[i] = args[i];
    }
    static foreach(i; Args.length..__params.length) {
        __params[i] = (cast(typeof(__params[i])*)pargs)[i];
    }

    static if (!is(returnTypeOf!FuncT == void)) {
        *(cast(returnTypeOf!(FuncT)*)rret) = fn(__params);
    } else {
        fn(__params);
    }
}

/**
    Wraps a given method of a class with a godot virtual call wrapper.

    Params:
        T =         The class to wrap a function for
        method =    Alias of the method to wrap.
        procname =  Name of the procedure to be called.
*/
pragma(inline, true)
GDExtensionClassCallVirtual gde_wrap_method_virtual_call(T, alias method, string procname)() @nogc
if (is(T : GDEObject)) {
    extern(C) GDExtensionClassCallVirtual fn = cast(GDExtensionClassCallVirtual)(GDExtensionClassInstancePtr p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc {
        alias ReturnType = returnTypeOf!method;
        alias Params = parametersOf!method;
        
        T obj_ = cast(T)p_instance;
        StringName p_procname = StringName(procname);
        if (object_has_script_method(obj_.ptr, &p_procname)) {

            // Get parameters.
            Variant[Params.length] __args = void;
            Variant __ret;
            static foreach(i; 0..__args.length) {
                __args[i] = gde_wrap(*(cast(typeof(__args[i])*)p_args[i]));
            }

            GDExtensionCallError err;
            object_call_script_method(obj_.ptr, &p_procname, cast(const(GDExtensionConstTypePtr)*)__args.ptr, cast(GDExtensionInt)__args.length, &__ret, &err);

            static if (!is(ReturnType == void))
                *(cast(ReturnType*)r_ret) = gde_unwrap!ReturnType(__ret);
            return;
        }

        auto __method = gde_get_func_instance!(T, method)();

        // Get parameters.
        Params __args = void;
        static foreach(i; 0..__args.length) {
            __args[i] = *(cast(typeof(__args[i])*)p_args[i]);
        }

        // Call.
        static if (!is(ReturnType == void))
            *(cast(ReturnType*)r_ret) = __method(obj_, __args);
        else
            __method(obj_, __args);
    };

    return fn;
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
        static if (!is(ReturnType == void))
            *(cast(ReturnType*)r_ret) = __traits(getMember, obj_, __traits(identifier, method))(__args);
        else
            __traits(getMember, obj_, __traits(identifier, method))(__args);
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

        // Types
        Params __args = void;
        T obj_ = cast(T)p_instance;

        // Too few args
        if (p_argument_count < Params.length) {
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
            r_error.expected = Params.length;
            return;
        }

        // Too many arguments.
        if (p_argument_count > Params.length) {
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
            r_error.expected = Params.length;
            return;
        }

        // Invalid instance.
        if (!obj_) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        // Type cast variants.
        Variant*[] p_vargs = (cast(Variant**)p_args)[0..p_argument_count];

        // Unwrap the arguments into ones that the DLang side understands.
        static foreach(i; 0..__args.length) {
            __args[i] = gde_unwrap!(typeof(__args[i]))(*p_vargs[i]);
        }

        // Wrap the return value to something that Godot understands, if needed.
        static if (!is(ReturnType == void)) {
            *(cast(Variant*)r_return) = gde_wrap!ReturnType(__traits(getMember, obj_, __traits(identifier, method))(__args));
        } else {
            __traits(getMember, obj_, __traits(identifier, method))(__args);
        }

        static foreach(i; 0..__args.length) {
            variant_destroy(p_vargs[i]);
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
    StringName p_name = StringName(name);
    return gde_get!T(global_get_singleton(&p_name));
}

/**
    Wraps the given D type in a variant.

    Params:
        value = The value to wrap.

    Returns:
        The wrapped value.
*/
Variant gde_wrap(T)(auto ref T value) @nogc
if (variantTypeOf!T != GDEXTENSION_VARIANT_TYPE_NIL) {
    static if (is(T == Variant)) {
        pragma(msg, "Warning: Trying to wrap a variant to a variant, this adds unneeded overhead.");
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

    static if (is(T == Variant)) {
        pragma(msg, "Warning: Trying to unwrap a variant from a variant, this adds unneeded overhead.");
        return from;
    } else {
        import godot.core.lifetime : gde_get;
        
        T result = void;
        static if (is(T == bool)) {
            bool_from_variant(&result, &from);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T))
                ulong _tmp;
            else
                long _tmp;
            
            int_from_variant(&_tmp, &from);
            result = cast(T)_tmp;
        } else static if (__traits(isFloating, T)) {

            double _tmp;
            float_from_variant(&_tmp, &from);
            result = cast(T)_tmp;
        } else static if(is(T == Vector2)) {

            vector2_from_variant(&result, &from);
        } else static if(is(T == Vector2i)) {

            vector2i_from_variant(&result, &from);
        } else static if(is(T == Rect2)) {

            rect2_from_variant(&result, &from);
        } else static if(is(T == Rect2i)) {

            rect2i_from_variant(&result, &from);
        } else static if(is(T == Vector3)) {

            vector3_from_variant(&result, &from);
        } else static if(is(T == Vector3i)) {

            vector3i_from_variant(&result, &from);
        } else static if(is(T == Vector4)) {

            vector4_from_variant(&result, &from);
        } else static if(is(T == Vector4i)) {

            vector4i_from_variant(&result, &from);
        } else static if(is(T == Quaternion)) {

            quaternion_from_variant(&result, &from);
        } else static if(is(T == Plane)) {

            plane_from_variant(&result, &from);
        } else static if(is(T == Transform2D)) {

            transform2d_from_variant(&result, &from);
        } else static if(is(T == Transform3D)) {

            transform3d_from_variant(&result, &from);
        } else static if(is(T == Basis)) {

            basis_from_variant(&result, &from);
        } else static if (is(T == String)) {
            
            string_from_variant(&result, &from);
        } else static if (is(T == StringName)) {
            
            string_name_from_variant(&result, &from);
        } else static if (is(T == NodePath)) {
            
            node_path_from_variant(&result, &from);
        } else static if (is(T == string)) {
            
            result = String(from).toString();
        } else static if (is(T == RID)) {
            
            rid_from_variant(&result, &from);
        } else static if (is(T == TypedArray!U, U)) {

            array_from_variant(&result, &from);
        } else static if (is(T == TypedDictionary!U, U...)) {
            
            dictionary_from_variant(&result, &from);
        } else static if (is(T == U[], U) && is(PackedArray!U)) {
            
            result = PackedArray!U(from)[];
        } else static if (is(T == PackedArray!U, U)) {
            
            result = PackedArray!U(from);
        } else static if (is(T : GDEObject)) {

            GDExtensionObjectPtr _tmp;
            object_from_variant(&_tmp, &from);
            result = gde_get!T(_tmp);
        } else {
            static assert(0, "Unwrapping of type "~T.stringof~" is not currently supported!");
        }
        return result;
    }
}