/**
    Functions for binding functions and methods to classes.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.bind.method;
import godot.core.gdextension;
import godot.core.object;
import godot.core.traits;
import godot.core.wrap;
import godot.variant;

/**
    Registers a method in the class database for a given class name.

    Params:
        name =      Name of the function.
        func =      The native function to call, gets wrapped automatically.
*/
void gde_classdb_register_method(T, FuncT)(string name, FuncT func) @nogc
if (is(T : GDEObject)) {
    enum paramCount = parametersOf!(FuncT).length;
    alias FT = FunctionTypeOf!FuncT;

    StringName* p_classname = gde_make_string_name(classNameOf!T);
    StringName* p_methodname = gde_make_string_name(name);
    GDExtensionClassMethodArgumentMetadata[paramCount] p_param_metas;
    GDExtensionPropertyInfo[paramCount] p_params;
    GDExtensionClassMethodArgumentMetadata p_return_meta;
    GDExtensionPropertyInfo p_return;
    GDExtensionClassMethodFlags p_methodflags = 
        cast(GDExtensionClassMethodFlags)methodFlagsOf!(FuncT);

    // Fill out parameters.
    alias paramNames = parameterNamesOf!FuncT;
    static foreach(int i, param; parametersOf!FuncT) {
        p_params[i] = gde_make_property_info!(param)(toSnakeCase!(paramNames[i]));
    }
    p_return = gde_make_property_info!(returnTypeOf!FuncT)("");

    // Get the wrapped function pointers.
    auto varcallFn = &gde_d_varcall!(FT);
    auto ptrcallFn = &gde_d_ptrcall!(FT);

    // Final & static functions.
    GDExtensionClassMethodInfo p_methodinfo = GDExtensionClassMethodInfo(
        method_userdata: func.ptr,
        name: p_methodname,
        call_func: cast(GDExtensionClassMethodCall)varcallFn,
        ptrcall_func: cast(GDExtensionClassMethodPtrCall)ptrcallFn,
        method_flags: cast(uint)p_methodflags,
        has_return_value: !is(returnTypeOf!FuncT == void),
        return_value_info: &p_return,
        return_value_metadata: p_return_meta,
        argument_count: cast(int)paramCount,
        arguments_info: p_params.ptr,
        arguments_metadata: p_param_metas.ptr,
    );
    classdb_register_extension_class_method(__godot_class_library, p_classname, &p_methodinfo);

    // Clean up parameters.
    static foreach(i; 0..paramCount)
        gde_destroy_property_info(p_params[i]);
    gde_destroy_property_info(p_return);
    gde_free_string_name(p_methodname);
    gde_free_string_name(p_classname);
}

/**
    Registers a virtual method in the class database for a given class name.

    NOTE:
        The implementation of the virtual method is handled elsewhere due to
        Godot percularities.

    Params:
        name =      Name of the function.
*/
void gde_classdb_register_virtual_method(T, FuncT)(string name = null) @nogc {
    enum paramCount = parametersOf!(FuncT).length;

    StringName* p_classname = gde_make_string_name(classNameOf!T);
    StringName* p_methodname = gde_make_string_name(name);
    GDExtensionClassMethodArgumentMetadata[paramCount] p_param_metas;
    GDExtensionPropertyInfo[paramCount] p_params;
    GDExtensionClassMethodArgumentMetadata p_return_meta;
    GDExtensionPropertyInfo p_return;
    GDExtensionClassMethodFlags p_methodflags = 
        cast(GDExtensionClassMethodFlags)methodFlagsOf!(FuncT);

    // Fill out parameters.
    alias paramNames = parameterNamesOf!FuncT;
    static foreach(int i, param; parametersOf!FuncT) {
        p_params[i] = gde_make_property_info!(param)(toSnakeCase!(paramNames[i]));
    }
    p_return = gde_make_property_info!(returnTypeOf!FuncT)("");

    // Virtual functions.
    GDExtensionClassVirtualMethodInfo p_virtualinfo = GDExtensionClassVirtualMethodInfo(
        name: p_methodname,
        method_flags: cast(uint)p_methodflags,
        return_value: p_return,
        return_value_metadata: p_return_meta,
        argument_count: cast(int)paramCount,
        arguments: p_params.ptr,
        arguments_metadata: p_param_metas.ptr,
    );
    classdb_register_extension_class_virtual_method(__godot_class_library, p_classname, &p_virtualinfo);

    // Clean up parameters.
    static foreach(i; 0..paramCount)
        gde_destroy_property_info(p_params[i]);
    gde_destroy_property_info(p_return);
    gde_free_string_name(p_methodname);
    gde_free_string_name(p_classname);
}