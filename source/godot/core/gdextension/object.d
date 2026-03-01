/**
    Module which implements the needed infrastructure to wrap
    Godot objects with D objects.
*/
module godot.core.gdextension.object;
import godot.core.gdextension.iface;
import godot.variant.variant;
import godot.variant.string;
import numem;

/**
    Base class for all wrapped Godot objects.
*/
class GDEObject : NuObject {
private:
@nogc:
    debug GDExtensionObjectPtr recreateOwner_;
    GDExtensionObjectPtr object_;

protected:

    /**
        Gets the underlying godot object pointer.
    */
    @property GDExtensionObjectPtr native_ptr() @system => object_;

    /**
        Constructs the object from a Godot Object pointer.
    */
    this(GDExtensionObjectPtr object) {
        this.object_ = object;
    }

public:
    // GDString
}

