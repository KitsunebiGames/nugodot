/**
    Subsystem that binds classes in a D-agnostic way.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.bind;
import godot.core.gdextension;
import godot.core.lifetime;
import godot.core.traits;
import godot.core.wrap;
import godot.core;
import godot.variant;
import godot.globals;
import godot.resource;

import numem.core.hooks : nu_malloc, nu_free;
import numem : nogc_new, nogc_delete;
import godot.core.bind.method;
import godot.core.bind.property;

/**
    Binds a class and registers it with Godot.

    You generally do not need to call this yourself.
*/
void gde_bind_class(T)() @nogc 
if (is(T : GDEObject)) {

    // Get icon of the class
    static if (getClassIconPath!T !is null) {
        __gshared String __gde_icon_path;
        String* __gde_icon_path_ptr = &__gde_icon_path;
    } else {
        String* __gde_icon_path_ptr = null;
    }
    
    alias ctors = gdeClassCtors!T;

    enum hasGetOverride = __traits(isOverrideFunction, T.get);
    enum hasSetOverride = __traits(isOverrideFunction, T.set);
    enum hasCanRevertOverride = __traits(isOverrideFunction, T.canRevertProperty);
    enum hasGetPropertyRevertOverride = __traits(isOverrideFunction, T.getPropertyRevert);
    enum hasNotificationOverride = __traits(isOverrideFunction, __traits(getMember, T, "onNotification"));
    
    static if (is(T PT == super)) {
        GDExtensionClassCreationInfo5 classInfo = GDExtensionClassCreationInfo5(
            is_virtual: false,
            is_abstract: __traits(isAbstractClass, T),
            is_exposed: true,
            is_runtime: !hasUDA!(T, gd_editor),
            icon_path: __gde_icon_path_ptr,
            to_string_func: cast(typeof(GDExtensionClassCreationInfo5.to_string_func))&__gde_class_to_string_func,
            create_instance_func: cast(typeof(GDExtensionClassCreationInfo5.create_instance_func))&ctors.__gde_class_create,
            free_instance_func: cast(typeof(GDExtensionClassCreationInfo5.free_instance_func))&ctors.__gde_class_free,
            get_virtual_call_data_func: cast(typeof(GDExtensionClassCreationInfo5.get_virtual_call_data_func))&__gde_class_get_virtual_call_data!(T),
            call_virtual_with_data_func: cast(typeof(GDExtensionClassCreationInfo5.call_virtual_with_data_func))&__gde_class_call_virtual_with_data!(T),

            // Optional overrides.
            notification_func: 
                hasNotificationOverride ? cast(typeof(GDExtensionClassCreationInfo5.notification_func))&__gde_class_notification_func : null,
            set_func:
                hasGetOverride ? cast(typeof(GDExtensionClassCreationInfo5.set_func))&__gde_class_set_func : null,
            get_func:
                hasSetOverride ? cast(typeof(GDExtensionClassCreationInfo5.get_func))&__gde_class_get_func : null,
            property_can_revert_func:
                hasCanRevertOverride ? cast(typeof(GDExtensionClassCreationInfo5.property_can_revert_func))&__gde_class_property_can_revert_func : null,
            property_get_revert_func:
                hasGetPropertyRevertOverride ? cast(typeof(GDExtensionClassCreationInfo5.property_get_revert_func))&__gde_class_property_get_revert_func : null,
        );

        // Register class
        gde_class_register_extension(classNameOf!T, classNameOf!PT, classInfo);

        // Bind members
        static foreach(member; boundMembersOf!T) {
            gde_bind_member!(T, member)();
        }

        // Bind constructors
        static if (is(typeof(T.__ctor))) {
            gde_bind_ctors!T();
        }
    }
}

void gde_unbind_class(T)() @nogc {
    gde_unregister_extension_class(classNameOf!T);
}



//
//                  IMPLEMENTATION DETAILS
//
private:

template gdeClassCtors(T) 
if (is(T : GDEObject)) {
    static if (is(T PT == super)) {

        // Instance constructor forwarder.
        pragma(mangle, gdeMangleOf!(T, __gde_class_create))
        extern(C) __gshared GDExtensionObjectPtr __gde_class_create(void* p_userdata, GDExtensionBool p_postinit) @nogc {
            
            T p_object = gde_alloc_class!T();
            if (p_postinit) {
                gde_bptrcall_method!("Object", "notification", GDEXTENSION_NOTIFICATION_FUNC_HASH)(p_object.ptr, 0, false);
            }
            return p_object.ptr;
        }

        // Instance free forwarder.
        pragma(mangle, gdeMangleOf!(T, __gde_class_free))
        extern(C) __gshared void __gde_class_free(void* p_userdata, GDExtensionClassInstancePtr p_instance) @nogc {
            if (T object = cast(T)p_instance) {
                gde_free_class(object);
            }
        }
    }
}

void gde_bind_ctors(T)() @nogc {
    alias __dctors = __traits(getOverloads, T, "__ctor");
    static if (__dctors.length == 1) {
        gde_bind_method!(T, __dctors[0])("_init");
    }

    // TODO: bind ctors with more 
}

void gde_bind_member(T, alias member)() @nogc
if (is(T : GDEObject)) {
    static if (isSignal!(__traits(getMember, T, member))) {
        gde_bind_signal!(T, member);
    } else static if (isConstant!(__traits(getMember, T, member))) {
        gde_bind_const!(T, member);
    } else static if (isProperty!(__traits(getMember, T, member))) {
        gde_bind_property!(T, member);
    } else static if (isMethod!(__traits(getMember, T, member))) {
        gde_bind_method!(T, __traits(getMember, T, member))();
    } else {
        pragma(msg, "Could not bind "~member.stringof~"...");
    }
}

void gde_bind_signal(T, alias signal)() @nogc
if (is(T : GDEObject)) {
    enum paramCount = __traits(getMember, T, signal).ArgsT.length;
    enum signalName = signalNameOf!(__traits(getMember, T, signal));
    
    StringName* p_classname = gde_make_string_name(classNameOf!T);
    StringName* p_signalname = gde_make_string_name(signalName);

    // Fill out parameters.
    GDExtensionPropertyInfo[paramCount] p_params;
    static foreach(int i, param; parametersOf!(__traits(getMember, T, signal))) {
        p_params[i] = gde_make_property_info!(param)("param"~i.stringof);
    }

    // Register signal
    classdb_register_extension_class_signal(__godot_class_library, p_classname, p_signalname, p_params.ptr, cast(GDExtensionInt)p_params.length);

    // Clean up parameters.
    static foreach(i; 0..paramCount)
        gde_destroy_property_info(p_params[i]);
    
    gde_free_string_name(p_signalname);
    gde_free_string_name(p_classname);
}

void gde_bind_method(T, alias method)(string name = null) @nogc
if (is(T : GDEObject)) {
    string methodName = name ? name : methodNameOf!method;

    static if (__traits(isFinalFunction, method) || __traits(isStaticFunction, method)) {
        
        // Bind non-virtual function.
        auto fn = gde_get_func_instance!(T, method);
        gde_classdb_register_method!(T, FunctionTypeOf!fn)(methodName, fn);
    } else {

        // Bind virtual function.
        gde_classdb_register_virtual_method!(T, FunctionTypeOf!method)(methodName);
    }
}

void gde_bind_property(T, alias memberName)() @nogc {
    // enum gdMemberName = toSnakeCase!(memberName);
    // alias propType = getPropertyType!(T, memberName);
    // alias propFuncs = getPropertyFunctions!(T, memberName);

    // enum propHasGetter = !is(propFuncs[0] == void);
    // enum propHasSetter = !is(propFuncs[1] == void);

    // static if (propHasGetter || propHasSetter) {
    //     alias memberRef = __traits(getMember, T, memberName);
        
    //     static if (propHasGetter) {
    //         enum getterName = "_get_"~gdMemberName;
    //         gde_bind_method!(T, propFuncs[0])(getterName);
    //     } else {
    //         enum getterName = "";
    //     }

    //     static if (propHasSetter) {
    //         enum setterName = "_set_"~gdMemberName;
    //         gde_bind_method!(T, propFuncs[1])(setterName);
    //     } else {
    //         enum setterName = "";
    //     }

    //     StringName* p_classname = gde_make_string_name(classNameOf!T);
    //     StringName* p_getter_name = gde_make_string_name(getterName);
    //     StringName* p_setter_name = gde_make_string_name(setterName);
        
    //     // Get the property exports.
    //     static if (propHasGetter && hasPropertyExport!(propFuncs[0])) {
    //         enum propExport = getPropertyExport!(propFuncs[0]);
    //     } else static if (propHasSetter && hasPropertyExport!(propFuncs[1])) {
    //         enum propExport = getPropertyExport!(propFuncs[1]);
    //     } else {
    //         enum propExport = gd_export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR);
    //     }

    //     auto p_prop_info = gde_make_property_info!propType(gdMemberName, propExport.hint, propExport.hintString, propExport.flags);
    //     classdb_register_extension_class_property(__godot_class_library, p_classname, &p_prop_info, p_setter_name, p_getter_name);
    //     gde_destroy_property_info(p_prop_info);

    //     gde_free_string_name(p_getter_name);
    //     gde_free_string_name(p_setter_name);
    //     gde_free_string_name(p_classname);
    // } else {

    //     // Auto-generated getters and setters.
        
    // }
    gde_classdb_register_property!(T, memberName)();
}

void gde_bind_const(T, alias memberName)() @nogc {
    alias member = __traits(getMember, T, memberName);
    StringName* p_classname = gde_make_string_name(classNameOf!T);
    StringName* p_enumname;
    StringName* p_constname;
    GDExtensionInt p_value;
    
    static if (is(member == enum)) {
        
        // Enums
        p_enumname = gde_make_string_name(__traits(identifier, member));
        static foreach(enumMember; __traits(allMembers, member)) {
            p_constname = gde_make_string_name(toScreamingSnakeCase!(enumMember));
            p_value = cast(GDExtensionInt)__traits(getMember, member, enumMember);
            classdb_register_extension_class_integer_constant(__godot_class_library, p_classname, p_enumname, p_constname, p_value, false);
            gde_free_string_name(p_constname);
        }
        gde_free_string_name(p_enumname);
    } else {

        // Manifest constants and consts
        p_enumname = gde_make_string_name(null);
        p_constname = gde_make_string_name(toScreamingSnakeCase!(__traits(identifier, member)));
        p_value = cast(GDExtensionInt)__traits(getMember, T, memberName);
        classdb_register_extension_class_integer_constant(__godot_class_library, p_classname, p_enumname, p_constname, p_value, false);
        gde_free_string_name(p_constname);
        gde_free_string_name(p_enumname);
    }

    gde_free_string_name(p_classname);
}



// 
// These functions handle forwarding virtual functions that are overridden.
// 

template __gde_class_get_virtual_call_data(T) {

    pragma(mangle, gdeMangleOf!(T, __gde_class_get_virtual_call_data))
    extern(C) void* __gde_class_get_virtual_call_data(void* pclassuserdata, GDExtensionConstStringNamePtr pname, uint phash) {
        StringName* p_procname = cast(StringName*)pname;
        static foreach(method; boundMethodsOf!T) {

            // We only care about overridden methods.
            static if (__traits(isOverrideFunction, __traits(getMember, T, method))) {

                if (*p_procname == methodNameOf!(__traits(getMember, T, method))) {
                    return gde_get_func_instance!(T, __traits(getMember, T, method))();
                }
            }
        }

        return null;
    }
}

template __gde_class_call_virtual_with_data(T) {
    pragma(mangle, gdeMangleOf!(T, __gde_class_call_virtual_with_data))
    extern(C) void __gde_class_call_virtual_with_data(GDExtensionClassInstancePtr pinstance, GDExtensionConstStringNamePtr pname, void* pvirtualcalluserdata, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret) @nogc {

        T p_instance = cast(T)pinstance;
        static foreach(method; boundMethodsOf!T) {
            {
                alias mthd = __traits(getMember, T, method);

                // We only care about overridden methods.
                static if (__traits(isOverrideFunction, mthd)) {
                    if (pvirtualcalluserdata == cast(void*)gde_get_func_instance!(T, mthd)()) {
                        gde_dcall!(T, mthd)(p_instance, p_args, r_ret);
                    }
                }
            }
        }
    }
}

// 
// These functions implement forwarders for basic godot class functions  
// They just forward calls to the GDEObject class type.
// 

extern(C) GDExtensionBool __gde_class_get_func(void* p_instance, StringName* p_name, Variant* p_variant) @nogc {
    return (cast(GDEObject)p_instance).get(*p_name, *p_variant);
}

extern(C) GDExtensionBool __gde_class_set_func(void* p_instance, StringName* p_name, Variant* p_variant) @nogc {
    return (cast(GDEObject)p_instance).set(*p_name, *p_variant);
}

extern(C) GDExtensionBool __gde_class_property_can_revert_func(void* p_instance, StringName* p_name) @nogc {
    return (cast(GDEObject)p_instance).canRevertProperty(*p_name);
}

extern(C) GDExtensionBool __gde_class_property_get_revert_func(void* p_instance, StringName* p_name, Variant* p_variant) @nogc {
    return (cast(GDEObject)p_instance).getPropertyRevert(*p_name, *p_variant);
}

extern(C) void __gde_class_notification_func(void* p_instance, int p_what, GDExtensionBool p_reversed) @nogc {
    auto p_obj = cast(GDEObject)p_instance;
    gde_get_func_instance!(GDEObject, __traits(getMember, GDEObject, "onNotification"))()(p_obj, p_what, cast(bool)p_reversed);
}

extern(C) void __gde_class_to_string_func(void* p_instance, GDExtensionBool* r_is_valid, String* r_out) @nogc {
    if (p_instance) {
        *r_out = String((cast(GDEObject)p_instance).toString());
        *r_is_valid = true;
        return;
    }

    *r_is_valid = false;
}