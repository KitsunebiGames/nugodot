/**
    Functions for binding properties to classes.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.bind.property;
import godot.core.bind.method;
import godot.core.gdextension;
import godot.core.object;
import godot.core.traits;
import godot.core.wrap;
import godot.variant;

/**
    Registers the given property with the object.

    Params:
        T =         The class to register the property for.
        propName =  Name of the property to register.
*/
void gde_classdb_register_property(T, string propertyName)() @nogc
if (is(T : GDEObject) && is(typeof(__traits(getMember, T, propertyName)))) {
    alias PropT = typeof(__traits(getMember, T, propertyName));
    enum propExport = getPropertyExport!(__traits(getMember, T, propertyName));
    enum propName = godotNameOf!(__traits(getMember, T, propertyName), true);

    // Create getter.
    static if (is(typeof(() { T tmp; return __traits(getMember, tmp, propertyName); }))) {
        enum propGetterName = "_get_"~toSnakeCase!(propName);
        gde_classdb_register_method!(T)(propGetterName, toMethodDelegate((T self) {
            return __traits(getMember, self, propertyName);
        }));
    } else {
        enum propGetterName = "";
    }

    // Create setter.
    static if (is(typeof(() { T tmp; __traits(getMember, tmp, propertyName) = PropT.init; }))) {
        enum propSetterName = "_set_"~toSnakeCase!(propName);
        gde_classdb_register_method!(T)(propSetterName, toMethodDelegate((T self, PropT value) {
            __traits(getMember, self, propertyName) = value;
        }));
    } else {
        enum propSetterName = "";
    }

    // Only generate if there's either a getter, setter or both.
    static if (propGetterName != "" || propSetterName != "") {

        StringName* p_classname = gde_make_string_name(classNameOf!T);
        StringName* p_getter_name = gde_make_string_name(propGetterName);
        StringName* p_setter_name = gde_make_string_name(propSetterName);

        auto p_prop_info = gde_make_property_info!PropT(propName, propExport.hint, propExport.hintString, propExport.flags);
        classdb_register_extension_class_property(__godot_class_library, p_classname, &p_prop_info, p_setter_name, p_getter_name);
        gde_destroy_property_info(p_prop_info);

        gde_free_string_name(p_getter_name);
        gde_free_string_name(p_setter_name);
        gde_free_string_name(p_classname);
    }
}