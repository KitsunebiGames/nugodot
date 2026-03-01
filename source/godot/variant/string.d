module godot.variant.string;
import godot.core.gdextension.iface;

/**
    A godot string.
*/
struct GDString {
private:
@nogc:
    void[32] data_;

public:

    /**
        Point to this instance, for use with raw GDExtension interface functions.
    */
    @property GDExtensionStringPtr self() => cast(GDExtensionStringPtr)&this;

    // @property size_t length() {
        
    // }

    /// Destructor
    ~this() {
        // string_destroy(cast(GDExtensionVariantPtr)&this);
    }

    /**
        Constructs a new variant from a pointer.
    */
    this(ref return scope GDString other) {

    }

    /**
        Constructs a new godot string from a D string.
    */
    this(string text) {
        string_new_with_utf8_chars_and_len2(this.self, text.ptr, cast(int)text.length);
    }

    /**
        Constructs a new godot string from a D string.
    */
    this(wstring text) {
        string_new_with_utf16_chars_and_len2(this.self, text.ptr, cast(int)text.length, false);
    }

    /**
        Constructs a new godot string from a D string.
    */
    this(dstring text) {
        string_new_with_utf32_chars_and_len(this.self, text.ptr, cast(int)text.length);
    }

    /**
        Resizes the string to the given size.

        Params:
            size = The new size.
    */
    void resize(size_t size) {
        string_resize(this.self, cast(int)size+1);
        *string_operator_index(this.self, cast(int)size) = 0;
    }
}

/**
    A string name.
*/
struct GDStringName {
private:
@nogc:
    void[size_t.sizeof] data_;

public:

    /// Destructor.
    ~this() {
        // string_name_destroy(cast(GDExtensionVariantPtr)&this);
    }

    /**
        Constructs a new StringName.
    */
    this(string name) {
        string_name_new_with_utf8_chars_and_len(cast(GDExtensionStringNamePtr)&this, name.ptr, cast(int)name.length);
    }
}