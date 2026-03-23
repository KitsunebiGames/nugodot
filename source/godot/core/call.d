/**
    Functions for calling godot methods.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.call;
import godot.core.gdextension;
import godot.core.traits;
import godot.core.wrap;
import godot.core.arg;
import godot.variant;
import numem;



//
//              MAIN CALL HELPERS
//

/**
    Calls a method on the given object using ptrcall.

    Params:
        obj =       The object to call the method on.
        method =    The method bind instance to call.
        args =      The arguments to the function.

    Returns:
        The return value of the method bind
*/
RetT gde_ptrcall(RetT = void, Args...)(GDExtensionTypePtr obj, GDExtensionMethodBindPtr method, auto ref Args p_args) @nogc @system {

    // Fill out arguments
    PStackVar!(Args)[Args.length] s_params = void;
    GDExtensionTypePtr[Args.length] p_params;
    static foreach(i; 0..Args.length) {
        p_params[i] = cast(GDExtensionTypePtr)&s_params[i];
        gde_to_ptr(p_args[i], p_params[i]);
    }
    
    // Call
    static if (!is(RetT == void)) {

        storageOf!RetT r_return;
        object_method_bind_ptrcall(method, obj, p_params.ptr, &r_return);

        RetT p_return;
        gde_from_ptr(cast(GDExtensionTypePtr)&r_return, p_return);
        return p_return;
    } else {

        object_method_bind_ptrcall(method, obj, p_params.ptr, null);
    }
}

/**
    Calls a method on the given object using varcall.

    Params:
        obj =       The object to call the method on.
        method =    The method bind instance to call.
        args =      The arguments to the function.

    Returns:
        The return value of the method bind
*/
RetT gde_varcall(RetT = void, Args...)(GDExtensionTypePtr obj, GDExtensionMethodBindPtr method, auto ref Args p_args) @nogc @system {

    // Fill out arguments
    Variant[Args.length] s_varargs;
    GDExtensionVariantPtr[Args.length] p_varargs;
    static foreach(i; 0..Args.length) {
        gde_to_varptr(p_args[i], s_varargs[i]);
        p_varargs[i] = &s_varargs[i];
    }
    
    // Call
    GDExtensionCallError p_callerror;
    static if (!is(RetT == void)) {

        Variant r_return;
        object_method_bind_call(method, obj, p_varargs.ptr, Args.length, &r_return, &p_callerror);

        RetT p_return;
        gde_from_varptr(cast(GDExtensionVariantPtr)&r_return, p_return);
        return p_return;
    } else {

        Variant r_return;
        object_method_bind_call(method, obj, p_varargs.ptr, 0, &r_return, &p_callerror);
    }
}

/**
    Calls a ptrcall function pointer using godot const type pointer arguments.

    Params:
        p_object =  The object to call the method on.
        p_args =    The godot parameters to pass to the function.
        r_ret =     The place that the return value should be stored.
*/
void gde_dcall(ClassT, alias method)(ClassT p_object, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc {
    alias Params = parametersOf!method;
    alias RetT = returnTypeOf!method;

    Params p_params;
    static foreach(i; 0..Params.length) {
        gde_from_ptr(p_args[i], p_params[i]);
    }

    import core.stdc.stdio : printf;

    auto fn = gde_get_func_instance!(ClassT, method)();
    static if (!is(RetT == void)) {

        auto d_return = fn(p_object, p_params);
        gde_to_ptr(d_return, r_ret);
    } else {
        
        fn(p_object, p_params);
    }
}

/**
    Calls a constructor on a variant.

    Params:
        p_variant = The variant to initialize.
        p_ctor =    The constructor to invoke.
        p_args =    The arguments to pass to the constructor.
*/
void gde_ctorcall(Args...)(GDExtensionUninitializedTypePtr p_variant, GDExtensionPtrConstructor p_ctor, Args p_args) @nogc {
    static if (Args.length > 0) {

        // Fill out arguments
        GDExtensionTypePtr[Args.length] p_params;
        static foreach(i; 0..Args.length) {
            p_params[i] = p_args[i];
        }

        p_ctor(p_variant, p_params.ptr);
    } else {
        p_ctor(p_variant, null);
    }
}

/**
    Calls a builtin method on a variant.

    Params:
        p_variant = The variant to initialize.
        p_method =  The method to invoke.
        p_args =    The arguments to pass to the constructor.
    
    Returns:
        The return value of the builtin call, if any.
*/
RetT gde_builtincall(RetT, Args...)(GDExtensionTypePtr p_variant, GDExtensionPtrBuiltInMethod p_method, Args p_args) @nogc {

    // Fill out arguments
    PStackVar!(Args)[Args.length] s_params = void;
    GDExtensionTypePtr[Args.length] p_params;
    static foreach(i; 0..Args.length) {
        p_params[i] = cast(GDExtensionTypePtr)&s_params[i];
        gde_to_ptr(p_args[i], p_params[i]);
    }

    // Call
    static if (!is(RetT == void)) {

        storageOf!RetT r_return;
        p_method(p_variant, p_params.ptr, &r_return, Args.length);

        RetT p_return;
        gde_from_ptr(cast(GDExtensionVariantPtr)&r_return, p_return);
        return p_return;
    } else {

        p_method(p_variant, p_params.ptr, null, Args.length);
    }
}

/**
    Calls a godot operator between the 2 given Godot types.

    Params:
        p_op =  The operator to call.
        p_lhs = Left hand side value to compare.
        p_rhs = Right hand side value to compare.
    
    Returns:
        Refer to Godot's documentation on operators.
*/
GDExtensionInt gde_opcall(GDExtensionPtrOperatorEvaluator p_op, GDExtensionConstTypePtr p_lhs, GDExtensionConstTypePtr p_rhs) @nogc nothrow {
    GDExtensionInt p_return;
    p_op(p_lhs, p_rhs, &p_return);
    return p_return;
}



//
//              BIND-AND-CALL HELPERS
//

/**
    Calls a builtin method on the given variant type.

    This internally wraps and caches the method for you.

    Params:
        p_variant = The type to construct.
        args =      Arguments to pass to the method.
*/
pragma(inline, true)
RetT gde_bcall_builtin(GDExtensionVariantType type, string name, uint hash, RetT = void, Args...)(GDExtensionTypePtr p_variant, Args args) @nogc nothrow {
    return gde_builtincall!(RetT, Args)(p_variant, gde_get_builtin_method!(type, name, hash)(), args);
}

/***
    Calls a constructor on the given variant type.

    This internally wraps and caches the constructor for you.

    Params:
        p_variant = The type to construct.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
void gde_bcall_ctor(GDExtensionVariantType type, int ctor, Args...)(GDExtensionTypePtr p_variant, Args args) @nogc nothrow {
    gde_ctorcall!(Args)(p_variant, gde_get_ctor!(type, ctor)(), args);
}

/***
    Calls a godot operator between the 2 given Godot types.

    This internally wraps and caches the operator for you.

    Params:
        p_op =  The operator to call.
        p_lhs = Left hand side value to compare.
        p_rhs = Right hand side value to compare.
    
    Returns:
        Refer to godot's documentation.
*/
pragma(inline, true)
GDExtensionInt gde_bcall_op(GDExtensionVariantOperator op, GDExtensionVariantType lhs, GDExtensionVariantType rhs)(GDExtensionConstTypePtr p_lhs, GDExtensionConstTypePtr p_rhs) @nogc nothrow {
    return gde_opcall(gde_get_operator!(op, lhs, rhs)(), p_lhs, p_rhs);
}

/***
    Calls a class method with ptrcall.

    This internally wraps and caches the constructor for you.

    Params:
        p_object =  The object to call the method on.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
RetT gde_bptrcall_method(string classname, string funcname, GDExtensionInt hash, RetT = void, Args...)(GDExtensionObjectPtr p_object, Args args) @nogc nothrow {
    return gde_ptrcall!(RetT, Args)(p_object, gde_get_method_bind!(classname, funcname, hash)(), args);
}

/***
    Calls a class method with ptrcall.

    This internally wraps and caches the constructor for you.

    Params:
        p_object =  The object to call the method on.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
RetT gde_bptrcall_method(T, string funcname, GDExtensionInt hash, RetT = void, Args...)(GDExtensionObjectPtr p_object, Args args) @nogc nothrow {
    return gde_ptrcall!(RetT, Args)(p_object, gde_get_method_bind!(T, funcname, hash)(), args);
}

/***
    Calls a class method with varcall.

    This internally wraps and caches the constructor for you.

    Params:
        p_object =  The object to call the method on.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
RetT gde_bvarcall_method(string classname, string funcname, GDExtensionInt hash, RetT = void, Args...)(GDExtensionObjectPtr p_object, Args args) @nogc nothrow {
    return gde_varcall!(RetT, Args)(p_object, gde_get_method_bind!(classname, funcname, hash)(), args);
}

/***
    Calls a class method with varcall.

    This internally wraps and caches the constructor for you.

    Params:
        p_object =  The object to call the method on.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
RetT gde_bvarcall_method(T, string funcname, GDExtensionInt hash, RetT = void, Args...)(GDExtensionObjectPtr p_object, Args args) @nogc nothrow {
    return gde_varcall!(RetT, Args)(p_object, gde_get_method_bind!(T, funcname, hash)(), args);
}