module godot.core.gdextension.utils;
import godot.core.gdextension.iface;

/**
    Loads all of the godot extension interface functions.
*/
void loadGodot(GDExtensionInterfaceGetProcAddress getProcAddr) @nogc nothrow {
    static foreach(member; __traits(allMembers, godot.core.gdextension.iface)) {
        static if (is(typeof(mixin(member)))) {
            static if (is(typeof(mixin(member)) == return)) {
                mixin(member) = cast(typeof(mixin(member)))getProcAddr(member);
            }
        }
    }
}