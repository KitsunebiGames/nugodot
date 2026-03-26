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
public import godot.core.arg;
public import godot.core.call;

/**
    Binds the given constructor for the given variant type.

    Returns:
        The bound constructor, cached automatically.
*/
GDExtensionPtrConstructor gde_get_ctor(GDExtensionVariantType type, int ctor)() @nogc nothrow {
    __gshared GDExtensionPtrConstructor p_bind;
    if (!p_bind)
        p_bind = cast(GDExtensionPtrConstructor)variant_get_ptr_constructor(type, ctor);
    
    return p_bind;
}

/**
    Binds the given method for the given variant type.

    Returns:
        The bound method, cached automatically.
*/
GDExtensionPtrBuiltInMethod gde_get_builtin_method(GDExtensionVariantType type, string name, uint hash)() @nogc nothrow {
    __gshared GDExtensionPtrBuiltInMethod p_bind;
    if (!p_bind) {
        auto p_methodname = gde_make_string_name(name);
        p_bind = variant_get_ptr_builtin_method(type, p_methodname, hash);
        gde_free_string_name(p_methodname);
    }
    
    return p_bind;
}

/**
    Binds the given method for the given classname, name and hash.

    Params:
        className = Name of the class to get the method bind for.
        name =      Name of the binding to get.
        hash =      Hash of the binding to get.
    
    Returns:
        A method bind for the given classname, name and hash on success,
        $(D null) otherwise.
*/
GDExtensionMethodBindPtr gde_get_method_bind(string classname, string name, uint hash)() @nogc nothrow {
    __gshared GDExtensionMethodBindPtr p_bind;
    if (!p_bind) {
        auto p_classname = gde_make_string_name(classname);
        auto p_methodname = gde_make_string_name(name);
        p_bind = classdb_get_method_bind(p_classname, p_methodname, hash);
        gde_free_string_name(p_classname);
        gde_free_string_name(p_methodname);
    }
    
    return p_bind;
}

/**
    Binds the given method for the given classname, name and hash.

    Params:
        T =     The class type to get the method for.
        name =  Name of the binding to get.
        hash =  Hash of the binding to get.
    
    Returns:
        A method bind for the given classname, name and hash on success,
        $(D null) otherwise.
*/
GDExtensionMethodBindPtr gde_get_method_bind(T, string name, uint hash)() @nogc nothrow {
    __gshared GDExtensionMethodBindPtr p_bind;
    if (!p_bind) {
        auto p_classname = gde_make_string_name(classNameOf!T);
        auto p_methodname = gde_make_string_name(name);
        p_bind = classdb_get_method_bind(p_classname, p_methodname, hash);
        // gde_free_string_name(p_classname);
        // gde_free_string_name(p_methodname);
    }
    
    return p_bind;
}

/**
    Binds the given operator for the given variant type.

    Returns:
        The bound operator, cached automatically.
*/
GDExtensionPtrOperatorEvaluator gde_get_operator(GDExtensionVariantOperator op, GDExtensionVariantType lhs, GDExtensionVariantType rhs)() @nogc nothrow {
    __gshared GDExtensionPtrOperatorEvaluator p_bind;
    if (!p_bind)
        p_bind = variant_get_ptr_operator_evaluator(op, lhs, rhs);
    
    return p_bind;
}

/**
    Registers an extension class by name, parent class name and creation info.

    Params:
        className =         Name of the class to register
        parentClassName =   Name of the parent class to register.
        info =              Information to register.
*/
void gde_class_register_extension(string className, string parentClassName, ref GDExtensionClassCreationInfo5 info) @nogc {
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
    } else static if(__traits(isStaticFunction, T)) {

        return &method;
    } else {

        return cast(rt)&method;
    }
}

/**
    Wraps a given method of a class with a godot ptrcall wrapper.

    Params:
        T =         The class to wrap a function for
        method =    Alias of the method to wrap.
*/
pragma(inline, true)
GDExtensionClassMethodPtrCall gde_wrap_ptrcall(T, alias method)() @nogc
if (is(T : GDEObject)) {
    extern(C) GDExtensionClassMethodPtrCall fn = cast(GDExtensionClassMethodPtrCall)(void* method_userdata, T p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc {
        alias ReturnType = returnTypeOf!method;
        alias Params = parametersOf!method;

        // Get parameters.
        Params p_params;
        static foreach(i; 0..Params.length) {
            gde_from_ptr(p_args[i], p_params[i]);
        }

        // Call.
        auto fn = gde_get_func_instance!(T, method);
        static if (!is(ReturnType == void)) {

            auto d_return = fn(p_instance, p_params);
            gde_to_ptr(d_return, r_ret);
        } else {

            fn(p_instance, p_params);
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
GDExtensionClassMethodCall gde_wrap_varcall(T, alias method)() @nogc {
    extern(C) GDExtensionClassMethodCall fn = cast(GDExtensionClassMethodCall)(void* methoduserdata, T p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) {
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

        if (!p_instance) {

            // Invalid instance.
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        // Unwrap the arguments into ones that the DLang side understands.
        Params p_params;
        static foreach(i; 0..Params.length) {
            gde_from_varptr!(Params[i])(p_args[i], p_params[i]);
        }

        // Wrap the return value to something that Godot understands, if needed.
        auto fn = gde_get_func_instance!(T, method);
        static if (!is(ReturnType == void)) {
            
            auto d_return = fn(p_instance, p_params);
            gde_to_varptr(d_return, r_return);
        } else {

            fn(p_instance, p_params);
        }
    };
    
    return fn;
}

/**
    Wraps a D function in a Godot callable.

    Params:
        p_callable =    The callable to set.
        p_func =        The D function or delegate to call.

    Note:
        This **breaks** D's type system by pretending all delegates
        are nogc compatible function pointers, be aware this may cause
        crashes for contexts that can't be allocated.
*/
void gde_wrap_d_function(T)(GDExtensionUninitializedTypePtr p_callable, T func) @nogc nothrow
if (is(T == return)) {
    static if (is(T == function)) {
        GDExtensionCallableCustomInfo2 p_info = GDExtensionCallableCustomInfo2(
            callable_userdata: cast(void*)func,
            token: __godot_class_library,
            call_func: cast(GDExtensionCallableCustomCall)(void* p_userdata, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argcount, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) {
                T func = cast(T)p_userdata;
                gde_dvarcall(func, p_args, p_argcount, r_return, r_error);
            }
        );

        callable_custom_create2(p_callable, p_info);
    } else static if (is(T == delegate)) {
        GDExtensionCallableCustomInfo2 p_info = GDExtensionCallableCustomInfo2(
            callable_userdata: cast(void*)func,
            token: __godot_class_library,
            call_func: cast(GDExtensionCallableCustomCall)(void* p_userdata, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argcount, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) {
                alias d_functype = typeof((cast(T)p_userdata).funcptr);
                alias t_functype = returnTypeOf!d_functype function(parametersOf!d_functype) @nogc nothrow;
                
                auto fn = cast(t_functype)((cast(T)p_userdata).funcptr);
                auto ctx = (cast(T)p_userdata).ptr;
                gde_dvarcall(fn, p_args, p_argcount, r_return, r_error, ctx);
            }
        );

        callable_custom_create2(p_callable, p_info);
    }
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
    gde_free_string_name(info.name);
    gde_free_string_name(info.class_name);
    gde_free_string(info.hint_string);
}

/**
    Gets a singleton by name.

    Params:
        name = The name of the singleton to get.
    
    Returns:
        The singleton if successful,
        $(D null) otherwise.
*/
T gde_get_singleton(T)(string name) @nogc
if (is(T : GDEObject)) {
    __gshared T __singleton_instance;
    if (!__singleton_instance) {
        StringName* p_name = gde_make_string_name(name);
        __singleton_instance = gde_class_bind_singleton!T(global_get_singleton(p_name));
        gde_free_string_name(p_name);
    }

    return __singleton_instance;
}

/**
    Wraps the given value in a variant.

    Params:
        value = The value to wrap.
*/
Variant gde_wrap(T)(T value) @nogc {
    return Variant(value);
}

/**
    Unwraps the given variant.

    Params:
        value = The value to unwrap.
*/
T gde_unwrap(T)(auto ref Variant value) @nogc {
    T result;
    gde_from_varptr(cast(GDExtensionVariantPtr)&value, result);
    return result;
}

/**
    Unwraps the given variant.

    Params:
        value = The value to unwrap.
*/
T gde_unwrap(T)(GDExtensionVariantPtr value) @nogc {
    T result;
    gde_from_varptr(value, result);
    return result;
}