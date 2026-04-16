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
void gde_dcall(T, alias method)(T p_object, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc
if (is(T == class)) {
    auto fn = gde_get_func_instance!(T, method)();
    gde_dcall!(typeof(fn), T)(fn, p_args, r_ret, p_object);
}

/**
    Calls a D function using ptrcall arguments.

    Params:
        p_func =    The function to call.
        p_args =    The godot parameters to pass to the function.
        r_ret =     The place that the return value should be stored.
        p_dargs =   D arguments to pass along.
*/
pragma(inline, true)
void gde_dcall(T, Args...)(T p_func, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret, Args p_dargs) @nogc
if (is(T == return)) {
    alias Params = parametersOf!(p_func)[Args.length..$];
    alias RetT = returnTypeOf!p_func;

    Params p_params;
    static foreach(i; 0..Params.length) {
        gde_from_ptr(p_args[i], p_params[i]);
    }

    static if (!is(RetT == void)) {

        auto d_return = p_func(p_dargs, p_params);
        gde_to_ptr(d_return, r_ret);
    } else {
        
        p_func(p_dargs, p_params);
    }
}

/**
    Calls a D function using varcall arguments.

    Params:
        p_func =        The function to call.
        p_args =        The godot parameters to pass to the function.
        p_argcount =    The amount of parameters passed from godot.
        r_ret =         The place that the return value should be stored.
        r_error =       The place to store error information.
        p_dargs =       D arguments to pass along.
*/
pragma(inline, true)
void gde_dvarcall(T, Args...)(T p_func, const(GDExtensionVariantPtr)* p_args, GDExtensionInt p_argcount, GDExtensionVariantPtr r_ret, GDExtensionCallError* r_error, Args p_dargs) @nogc
if (is(T == function)) {
    alias Params = parametersOf!(p_func)[Args.length..$];
    alias RetT = returnTypeOf!p_func;

    // Too few arguments.
    if (p_argcount < Params.length) {
        r_error.error = GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
        r_error.expected = Params.length;
        return;
    }

    // Too many arguments.
    if (p_argcount > Params.length) {
        r_error.error = GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
        r_error.expected = Params.length;
        return;
    }

    Params p_params;
    static foreach(i; 0..Params.length) {
        gde_from_varptr(p_args[i], p_params[i]);
    }

    static if (!is(RetT == void)) {

        auto d_return = p_func(p_dargs, p_params);
        gde_to_varptr(d_return, r_ret);
    } else {
        
        fn(p_dargs, p_params);
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
//              D-TO-GODOT CALL HELPERS
//

/**
    Wraps the given function in a godot varcall wrapper.

    Note:
        Delegates passed **must** be class method members.
        The context pointer will be replaced by the instance pointer
        from Godot.

    Params:
        p_func =            The function to call.
        p_instance =        Class instance.
        p_args =            Arguments to pass to the function
        p_argument_count =  Amount of arguments.
        r_return =          Return value.
        r_error =           Error value.
*/
extern(C) void gde_d_varcall(FuncT)(void* p_func, void* p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) @nogc {
    static if (is(FuncT == delegate)) {

        //
        //                  DELEGATE IMPL
        //
        alias ReturnType = returnTypeOf!FuncT;
        alias Params = parametersOf!(typeof(FuncT.funcptr));
        alias FnT = ReturnType function(Params) @nogc nothrow;

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

        // Unwrap the arguments into ones that the DLang side understands.
        Params p_params;
        p_params[0] = cast(typeof(Params[0]))p_instance;
        static foreach(i; 1..Params.length) {
            gde_from_varptr!(Params[i])(p_args[i-1], p_params[i]);
        }
        
        // Invalid instance.
        if (!p_instance) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        // Wrap the return value to something that Godot understands, if needed.
        static if (!is(ReturnType == void)) {
            
            auto d_return = (cast(FnT)p_func)(p_params);
            gde_to_varptr(d_return, r_return);
        } else {

            (cast(FnT)p_func)(p_params);
        }

    } else static if (is(FuncT == function)) {

        //
        //                  FUNCTION IMPL
        //
        alias ReturnType = returnTypeOf!FuncT;
        alias Params = parametersOf!FuncT;
        alias FnT = ReturnType function(Params) @nogc nothrow;

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

        // Unwrap the arguments into ones that the DLang side understands.
        Params p_params;
        static foreach(i; 0..Params.length) {
            gde_from_varptr!(Params[i])(p_args[i], p_params[i]);
        }
        
        // Invalid instance.
        if (!p_instance) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        // Wrap the return value to something that Godot understands, if needed.
        static if (!is(ReturnType == void)) {
            
            auto d_return = (cast(FnT)p_func)(p_params);
            gde_to_varptr(d_return, r_return);
        } else {

            (cast(FnT)p_func)(p_params);
        }
    } else {
        static assert(0, "p_func is not a function.");
    }
}

/**
    Wraps a given method of a class with a godot ptrcall wrapper.

    Note:
        Delegates passed **must** be class method members.
        The context pointer will be replaced by the instance pointer
        from Godot.

    Params:
        p_func =            The function to call.
        p_instance =        Class instance.
        p_args =            Arguments to pass to the function
        r_return =          Return value.
*/
extern(C) void gde_d_ptrcall(FuncT)(void* p_func, void* p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_return) @nogc
if(isSomeFunction!FuncT) {
    static if (is(FuncT == delegate)) {

        //
        //                  DELEGATE IMPL
        //
        alias ReturnType = returnTypeOf!FuncT;
        alias Params = parametersOf!(typeof(FuncT.funcptr));
        alias FnT = ReturnType function(Params) @nogc nothrow;

        // Get parameters.
        Params p_params;
        p_params[0] = cast(typeof(Params[0]))p_instance;
        static foreach(i; 1..Params.length) {
            gde_from_ptr(p_args[i-1], p_params[i]);
        }

        // Call.
        static if (!is(ReturnType == void)) {

            auto d_return = (cast(FnT)p_func)(p_params);
            gde_to_ptr(d_return, r_return);
        } else {

            (cast(FnT)p_func)(p_params);
        }


    } else static if (is(FuncT == function)) {

        //
        //                  FUNCTION IMPL
        //
        alias ReturnType = returnTypeOf!FuncT;
        alias Params = parametersOf!FuncT;
        alias FnT = ReturnType function(Params) @nogc nothrow;

        // Get parameters.
        Params p_params;
        static foreach(i; 0..Params.length) {
            gde_from_ptr(p_args[i], p_params[i]);
        }

        // Call.
        static if (!is(ReturnType == void)) {

            auto d_return = (cast(FnT)p_func)(p_params);
            gde_to_ptr(d_return, r_return);
        } else {

            (cast(FnT)p_func)(p_params);
        }
    } else {
        static assert(0, "p_func is not a function.");
    }
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
    Calls a constructor on the given variant type.

    This internally wraps and caches the constructor for you.

    Params:
        p_variant = The type to construct.
        args =      Arguments to pass to the type's constructor.
*/
pragma(inline, true)
void gde_bcall_ctor(T, int ctor, Args...)(GDExtensionTypePtr p_variant, Args args) @nogc nothrow {
    gde_ctorcall!(Args)(p_variant, gde_get_ctor!(variantTypeOf!T, ctor)(), args);
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