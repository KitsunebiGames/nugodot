/**
    Binding to Godot's String Variants

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.string;
import godot.variant.variant;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.core.wrap;
import numem.core.memory;
import numem.core.hooks;

/**
    A godot string.
*/
struct String {
private:
@nogc nothrow:
    void[VARIANT_SIZE_STRING] data_;

public:

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_STRING;

    /**
        Writable pointer to the underlying string data.
    */
    @property dchar* ptrw() => string_operator_index(&this, 0);

    /**
        Pointer to the underlying string data.
    */
    @property const(dchar)* ptr() => string_operator_index_const(&this, 0);

    /**
        The length of the String.
    */
    @property size_t length() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "length", 3173160232, GDExtensionInt)(&this);

    /**
        Whether the string is empty.
    */
    @property bool isEmpty() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "is_empty", 3918633141, bool)(&this);

    /**
        Whether the string is a relative path.
    */
    @property bool isRelativePath() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "is_relative_path", 3918633141, bool)(&this);

    /**
        Whether the string is an absolute path.
    */
    @property bool isAbsolutePath() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "is_absolute_path", 3918633141, bool)(&this);

    /**
        File extension portion of the path string.
    */
    @property String extension() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "get_extension", 3942272618, String)(&this);

    /**
        Base name portion of the path string.
    */
    @property String baseName() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "get_basename", 3942272618, String)(&this);

    /**
        Base path portion of the path string.
    */
    @property String basePath() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "get_base_dir", 3942272618, String)(&this);

    /**
        File portion of the path string.
    */
    @property String file() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "get_file", 3942272618, String)(&this);

    /// Destructor
    ~this() {
        string_destroy(&this);
    }

    /**
        Copy-constructor
    */
    this(ref return scope String other) {
        gde_bind_and_call_ctor!(GDEXTENSION_VARIANT_TYPE_STRING, 1)(&this, &other);
    }

    /**
        Constructs a String from a StringName
    */
    this(ref return scope StringName other) {
        gde_bind_and_call_ctor!(GDEXTENSION_VARIANT_TYPE_STRING, 2)(&this, &other);
    }

    /**
        Constructs a String from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        string_from_variant(&this, &variant);
    }

    /**
        Constructs a new godot string from a D string.
    */
    this(string text) {
        string_new_with_utf8_chars_and_len2(&this, text.ptr, cast(int)text.length);
    }

    /**
        Constructs a new godot string from a D string.
    */
    this(wstring text) {
        string_new_with_utf16_chars_and_len2(&this, text.ptr, cast(int)text.length, false);
    }

    /**
        Constructs a new godot string from a D string.
    */
    this(dstring text) {
        string_new_with_utf32_chars_and_len(&this, text.ptr, cast(int)text.length);
    }

    /**
        Resizes the string to the given size.

        Params:
            size = The new size.
    */
    void resize(size_t size) {
        string_resize(&this, cast(int)size+1);
        *string_operator_index(&this, cast(int)size) = 0;
    }

    /**
        Gets whether the strig begins with another string.

        Params:
            text = The text to compare with.
        
        Returns:
            $(D true) if the string begins with the given text,
            $(D false) otherwise.
    */
    bool beginsWith(String text) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "begins_with", 2566493496, bool)(&this, text);
    }

    /// ditto
    bool beginsWith(string text) {
        return this.beginsWith(String(text));
    }

    /**
        Gets whether the strig ends with another string.

        Params:
            text = The text to compare with.
        
        Returns:
            $(D true) if the string ends with the given text,
            $(D false) otherwise.
    */
    bool endsWith(String text) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "ends_with", 2566493496, bool)(&this, text);
    }

    /// ditto
    bool endsWith(string text) {
        return this.beginsWith(String(text));
    }

    /**
        Gets whether the strig contains another string.

        Params:
            text = The text to compare with.
        
        Returns:
            $(D true) if the string contains the given text,
            $(D false) otherwise.
    */
    bool contains(String text) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "contains", 2566493496, bool)(&this, text);
    }

    /// ditto
    bool contains(string text) {
        return this.beginsWith(String(text));
    }

    /**
        Returns the result of joining this String with another
        as a file path.

        Params:
            path = The path to append to this String.
        
        Returns:
            The strings joined together as a file path string.
    */
    String pathJoin(String path) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING, "path_join", 3134094431, String)(&this, path);
    }

    /**
        Allows appending to the string.

        Params:
            value = The value to append.
    */
    auto opOpAssign(string op = "~", T)(auto ref T value) {
        import nulib.string : isSomeString;

        static if (is(T == char)) {
            import nulib.text.unicode.utf8 : decode;
            
            char[4] c = [value, 0, 0, 0];
            string_operator_plus_eq_char(&this, decode(c));
        } else static if (is(T == dchar)) {
            import nulib.text.unicode.utf16 : decode;

            size_t throwaway;
            wchar[2] c = [value, 0];
            string_operator_plus_eq_char(&this, decode(c, throwaway));
        } else static if (isSomeString!T) {
            import nulib.text.unicode : toUTF32;

            auto str = toUTF32(value, false);
            string_operator_plus_eq_c32str(&this, str.ptr);
        } else static if (is(T == String*)) {

            string_operator_plus_eq_string(&this, value);
        } else static if (is(T == String)) {

            string_operator_plus_eq_string(&this, &value);
        } else {
            static assert(0, "Can't append "~T.stringof~" to String.");
        }
        return this;
    }

    /**
        Gets a string representation of the godot string.

        Note:
            This string must be freed with $(D nu_freea)!
        
        Returns:
            A D string representation of this string.
    */
    string toString() const {
        char[] str_ = nu_malloca!char(string_to_utf8_chars(&this, null, 0));
        string_to_utf8_chars(&this, cast(char*)str_.ptr, cast(int)str_.length);
        return cast(string)str_;
    }
}

/**
    Constructs a new heap allocated $(D String).

    This string must be freed by your using $(D gde_free_string)!

    Params:
        value = The value to set the new string to.
    
    Returns:
        The newly constructed $(D String).
    
    See_Also:
        $(D gde_free_string)
*/
pragma(inline, true)
String* gde_make_string(string value) @nogc nothrow {
    String* result = cast(String*)nu_malloc(String.sizeof);
    string_new_with_utf8_chars_and_len2(result, value.ptr, cast(int)value.length);
    return result;
}

/**
    Frees a heap-allocated $(D String).

    Params:
        str = The string to free.

    See_Also:
        $(D gde_make_string)
*/
pragma(inline, true)
void gde_free_string(T)(ref T str) @nogc nothrow
if (is(T == String*) || is(T == GDExtensionStringPtr)) {
    if (str) {
        string_destroy(str);
        nu_free(str);
        str = null;
    }
}

/**
    A string name.
*/
struct StringName {
private:
@nogc nothrow:
    void[VARIANT_SIZE_STRINGNAME] data_;

public:

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_STRING_NAME;

    /**
        The length of the StringName.
    */
    @property size_t length() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING_NAME, "length", 3173160232, GDExtensionInt)(&this);

    /**
        Pointer to string name in heap.
    */
    @property void* ptr() inout => cast(void*)data_;

    /// Destructor
    ~this() {
        string_name_destroy(&this);
    }

    /**
        Copy-constructor
    */
    this(ref return scope StringName other) {
        gde_bind_and_call_ctor!(GDEXTENSION_VARIANT_TYPE_STRING_NAME, 1)(&this, &other);
    }

    /**
        Copy-constructor
    */
    this(ref String other) {
        gde_bind_and_call_ctor!(GDEXTENSION_VARIANT_TYPE_STRING_NAME, 2)(&this, &other);
    }

    /**
        Constructs a StringName from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this(ref Variant variant) {
        string_name_from_variant(&this, &variant);
    }

    /**
        Constructs a new StringName.
    */
    this(string name) {
        string_name_new_with_utf8_chars_and_len(&this, name.ptr, cast(int)name.length);
    }

    /**
        Compares equality between 2 StringName's
    */
    bool opEquals(ref StringName other) {
        return cast(bool)get_bind_op_and_call!(GDEXTENSION_VARIANT_OP_EQUAL, GDEXTENSION_VARIANT_TYPE_STRING_NAME, GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&this, &other);
    }

    /**
        Compares equality between a StringName and a D string
    */
    bool opEquals(string other) inout {
        StringName* p_other = gde_make_string_name(other);
        scope(exit) gde_free_string_name(p_other);
        return cast(bool)get_bind_op_and_call!(GDEXTENSION_VARIANT_OP_EQUAL, GDEXTENSION_VARIANT_TYPE_STRING_NAME, GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&this, p_other);
    }

    /**
        Gets a string representation of the godot StringName.

        Note:
            This string must be freed with $(D nu_freea)!
        
        Returns:
            A D string representation of this string.
    */
    string toString() const {
        String tmp = String(cast(StringName)this);
        return tmp.toString();
    }

    /**
        Gets the StringName's hash.

        Returns:
            The hash of the StringName.
    */
    size_t toHash() const @trusted nothrow {        
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_STRING_NAME, "hash", 3173160232, GDExtensionInt)(cast(StringName*)&this);
    }
}

/**
    Constructs a new heap allocated $(D StringName).

    This string must be freed by your using $(D gde_free_string_name)!

    Params:
        value = The value to set the new string to.
    
    Returns:
        The newly constructed $(D StringName).
    
    See_Also:
        $(D gde_free_string_name)
*/
pragma(inline, true)
StringName* gde_make_string_name(string value) @nogc nothrow {
    StringName* result = cast(StringName*)nu_malloc(StringName.sizeof);
    string_name_new_with_utf8_chars_and_len(result, value.ptr, cast(int)value.length);
    return result;
}

/**
    Frees a heap-allocated $(D StringName).

    Params:
        str = The string to free.

    See_Also:
        $(D gde_make_string_name)
*/
pragma(inline, true)
void gde_free_string_name(T)(ref T name) @nogc nothrow
if (is(T == StringName*) || is(T == GDExtensionStringNamePtr)) {
    if (name) {
        string_name_destroy(name);
        nu_free(name);

        name = null;
    }
}

/**
    A node path.
*/
struct NodePath {
private:
@nogc nothrow:
    void[VARIANT_SIZE_NODEPATH] data;

public:

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_NODE_PATH;

    /**
        Whether the NodePath is absolute.
    */
    @property bool isAbsolute() => cast(bool)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_NODE_PATH, "is_absolute", 3918633141, GDExtensionBool)(&this);

    /**
        Count of names in the path.
    */
    @property int nameCount() => cast(bool)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_NODE_PATH, "get_name_count", 3173160232, GDExtensionInt)(&this);

    /// Destructor
    ~this() {
        node_path_destroy(&this);
    }

    /**
        Constructs a NodePath from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this(ref Variant variant) {
        node_path_from_variant(&this, &variant);
    }

    /**
        Gets the NodePath's hash.

        Returns:
            The hash of the NodePath.
    */
    size_t toHash() const @trusted nothrow {        
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_NODE_PATH, "hash", 3173160232, GDExtensionInt)(cast(String*)&this);
    }
}