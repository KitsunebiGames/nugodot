module godot.variant.array;
import godot.core.gdextension.variant_size;
import godot.core.gdextension.iface;
import godot.core.wrap;
import godot.core.traits;
import godot.core.object;
import godot.variant.string;
import godot.variant.vector;
import godot.variant.variant;
import godot.variant.color;
import numem.core.traits;
import numem.core.meta;

/**
    Untyped array.
*/
alias Array = TypedArray!(Variant);

/**
    A variant-based array, limited to a given type.
*/
struct TypedArray(T) {
private:
@nogc:
    void[VARIANT_SIZE_VARIANT] data_;

public:

    // Disable default construction
    @disable this();

    /**
        Makes a new instance of the given array type.
    */
    static typeof(this) makeNew() {
        typeof(this) p_arr = void;
        gde_bind_and_call_ctor!(typeof(this), 0)(p_arr);
        static if (!is(T == Variant)) {
            static if (is(T : GDEObject)) {
                auto p_classVARIANT_TYPE = StringName(classNameOf!T);
                array_set_typed(&p_arr, variantTypeOf!T, &p_classVARIANT_TYPE, null);
            } else {
                array_set_typed(&p_arr, variantTypeOf!T, null, null);
            }
        }
        return p_arr;
    }

    /**
        The size of the array.
    */
    @property size_t size() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "size", 3173160232, GDExtensionInt)(&this);

    /**
        Whether the array is empty.
    */
    @property bool isEmpty() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "is_empty", 3918633141, bool)(&this);

    /**
        The hash of this array.
    */
    @property ulong hash() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "hash", 3918633141, GDExtensionInt)(&this);

    /**
        Whether the array is read-only.
    */
    @property bool isReadonly() => cast(bool)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "is_read_only", 3918633141, GDExtensionBool)(&this);

    /**
        Whether this array is valid.
    */
    @property bool isValid() => this != typeof(this).init;

    /**
        The first element of the array.
    */
    @property T front() {
        static if (is(T == Variant)) {
            return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "front", 1460142086, Variant)(&this);
        } else {
            return gde_unwrap!T(gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "front", 1460142086, Variant)(&this));
        }
    }

    /**
        The last element of the array.
    */
    @property T back() {
        static if (is(T == Variant)) {
            return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "back", 1460142086, Variant)(&this);
        } else {
            return gde_unwrap!T(gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "back", 1460142086, Variant)(&this));
        }
    }

    /**
        Makes a duplicate of this array.

        Params:
            deep = Whether to make a deep copy of the array.
        
        Returns:
            A new array that is a duplicate of this array.
    */
    typeof(this) duplicate(bool deep = false) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "duplicate", 636440122, typeof(this))(&this, deep);
    }

    /**
        Clears the array.
    */
    void clear() {
        gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "clear", 3218959716)(&this);
    }

    /**
        Resizes the array.

        Params:
            size = The new size of the array.
    */
    void resize(size_t size) {
        gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "resize", 848867239)(&this, cast(GDExtensionInt)size);
    }

    /**
        Removes an element from the array at the given index.

        Params:
            index = The index to remove the element at.
    */
    void removeAt(size_t index) {
        gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "remove_at", 2823966027)(&this, cast(GDExtensionInt)index);
    }

    /**
        Fills the array with the given value.

        Params:
            value = The value to fill the array with.
    */
    void fill()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "fill", 3316032543)(&this, value);
        } else {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "fill", 3316032543)(&this, gde_wrap!T(value));
        }
    }

    /**
        Pushes a value to the front of the array.

        Params:
            value = The value to push.
    */
    void pushFront()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_front", 3316032543)(&this, value);
        } else {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_front", 3316032543)(&this, gde_wrap!T(value));
        }
    }

    /**
        Pushes a value to the back of the array.

        Params:
            value = The value to push.
    */
    void pushFront()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_back", 3316032543)(&this, value);
        } else {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_back", 3316032543)(&this, gde_wrap!T(value));
        }
    }

    /**
        Inserts a value at a given position.

        Params:
            value = The value to insert.
            at =    The position to insert it.
    */
    void insert()(auto ref T value, ptrdiff_t at) {
        static if (is(T == Variant)) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "insert", 3176316662)(&this, cast(GDExtensionInt)at, value);
        } else {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "insert", 3176316662)(&this, cast(GDExtensionInt)at, gde_wrap!T(value));
        }
    }

    static if (is(T == Variant)) {

        /**
            Allows slice-indexing the untyped Array.

            Params:
                slice = The slice passed in.
        */
        Variant[] opIndex(size_t[2] slice) {
            return (cast(Variant*)array_operator_index_const(&this, 0))[slice[0]..slice[1]];
        }

        /**
            Implements slicing operator.

            Params:
                start = Start of slicing operation.
                end = End of slicing
        */
        size_t[2] opSlice(size_t start, size_t end) {
            return [start, end];
        }
    }

    /**
        Indexes into the array.

        Params:
            index = The index to fetch the element from.
        
        Returns:
            The value at the given index.
    */
    auto ref T opIndex()(size_t index) {
        static if (is(T == Variant)) {
            return *cast(Variant*)array_operator_index_const(&this, index);
        } else {
            if (auto p_variant = cast(Variant*)array_operator_index_const(&this, index)) {
                return gde_unwrap!T(*p_variant);
            }
            return T.init;
        }
    }

    /**
        Indexes into the array.

        Params:
            value = The value to set at the given index.
            index = The index to fetch the element from.
    */
    void opIndexAssign()(auto ref T value, size_t index) {
        static if (is(T == Variant)) {
            if (auto p_variant = cast(Variant*)array_operator_index(&this, index)) {
                *p_variant = value;
            }
        } else {
            if (auto p_variant = cast(Variant*)array_operator_index(&this, index)) {
                *p_variant = gde_wrap!T(value);
            }
        }
    }

    /**
        Appends a value to the array.

        Params:
            value = The value to append, can be another array of compatible type.
    */
    void opOpAssign(string op="~", T)(auto ref T value) {
        static if (is(T == typeof(this)) || (is(typeof(this) == TypedArray!Variant) && is(T == TypedArray!U, U))) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append_array", 2307260970)(&this, value);
        } else static if (is(T == Variant)) {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append", 3316032543)(&this, value);
        } else {
            gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append", 3316032543)(&this, gde_wrap!T(value));
        }
    }
}

/**
    A packed array.
*/
struct PackedArray(T, string VARIANT_TYPE, uint t_size) {
private:
@nogc:
    void[t_size] data_;

public:
    /// The type of this variant.
    enum VARIANT_TYPE = variantTypeOf!(typeof(this));

    // Disable default construction
    @disable this();

    /**
        The size of the array.
    */
    @property size_t size() => cast(size_t)gde_bind_and_call!(VARIANT_TYPE, "size", 3173160232, GDExtensionInt)(&this);

    /**
        Whether the array is empty.
    */
    @property bool isEmpty() => gde_bind_and_call!(VARIANT_TYPE, "is_empty", 3918633141, bool)(&this);

    /**
        Whether this array is valid.
    */
    @property bool isValid() => this != typeof(this).init;

    /**
        Makes a new instance of the given array type.
    */
    static typeof(this) makeNew() {
        typeof(this) p_arr = void;
        gde_bind_and_call_ctor!(typeof(this), 0)(p_arr);
        return p_arr;
    }

    /**
        Clears the array.
    */
    void clear() {
        gde_bind_and_call!(VARIANT_TYPE, "clear", 3218959716)(&this);
    }

    /**
        Resizes the array.

        Params:
            size = The new size of the array.
    */
    void resize(size_t size) {
        cast(void)gde_bind_and_call!(VARIANT_TYPE, "resize", 848867239, GDExtensionInt)(&this, cast(GDExtensionInt)size);
    }

    /**
        Removes an element from the array at the given index.

        Params:
            index = The index to remove the element at.
    */
    void removeAt(size_t index) {
        gde_bind_and_call!(VARIANT_TYPE, "remove_at", 2823966027)(&this, cast(GDExtensionInt)index);
    }

    /**
        Indexes into the array.

        Params:
            index = The index to fetch the element from.
        
        Returns:
            The value at the given index.
    */
    auto ref T opIndex()(size_t index) {
        static if (__traits(isIntegral, T)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 4103005248, GDExtensionInt)(&this, cast(GDExtensionInt)index);
        } else static if (__traits(isFloating, T)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 1401583798, double)(&this, cast(GDExtensionInt)index);
        } else static if (is(T == Vector2)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 2609058838, Vector2)(&this, cast(GDExtensionInt)index);
        } else static if (is(T == Vector3)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 1394941017, Vector3)(&this, cast(GDExtensionInt)index);
        } else static if (is(T == Vector4)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 1227817084, Vector4)(&this, cast(GDExtensionInt)index);
        } else static if (is(T == Color)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 2972831132, Color)(&this, cast(GDExtensionInt)index);
        } else static if (is(T == String)) {
            return cast(T)gde_bind_and_call!(VARIANT_TYPE, "get", 2162347432, String)(&this, cast(GDExtensionInt)index);
        } else {
            static assert(0, "Invalid PackedArray type "~T.stringof);
        }
    }

    /**
        Indexes into the array.

        Params:
            value = The value to set at the given index.
            index = The index to fetch the element from.
    */
    void opIndexAssign()(auto ref T value, size_t index) {
        static if (__traits(isIntegral, T)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 3638975848)(&this, cast(GDExtensionInt)index, cast(GDExtensionInt)value);
        } else static if (__traits(isFloating, T)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 1113000516)(&this, cast(GDExtensionInt)index, cast(double)value);
        } else static if (is(T == Vector2)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 635767250)(&this, cast(GDExtensionInt)index, value);
        } else static if (is(T == Vector3)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 3975343409)(&this, cast(GDExtensionInt)index, value);
        } else static if (is(T == Vector4)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 1350366223)(&this, cast(GDExtensionInt)index, value);
        } else static if (is(T == Color)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 1444096570)(&this, cast(GDExtensionInt)index, value);
        } else static if (is(T == String)) {
            gde_bind_and_call!(VARIANT_TYPE, "set", 725585539)(&this, cast(GDExtensionInt)index, value);
        } else {
            static assert(0, "Invalid PackedArray type "~T.stringof);
        }
    }

    /**
        Appends a value to the array.

        Params:
            value = The value to append.
    */
    void opOpAssign(string op="~", Y)(auto ref Y value) {
        static if (is(Y == typeof(this))) {
            
            // Append array.
            static if (is(Y == PackedByteArray)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 791097111)(&this, value);
            } else static if (is(Y == PackedInt32Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 1087733270)(&this, value);
            } else static if (is(Y == PackedInt64Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 2090311302)(&this, value);
            } else static if (is(Y == PackedFloat32Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 2981316639)(&this, value);
            } else static if (is(Y == PackedFloat64Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 792078629)(&this, value);
            } else static if (is(Y == PackedVector2Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 3887534835)(&this, value);
            } else static if (is(Y == PackedVector3Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 203538016)(&this, value);
            } else static if (is(Y == PackedVector4Array)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 537428395)(&this, value);
            } else static if (is(Y == PackedColorArray)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 798822497)(&this, value);
            } else static if (is(Y == PackedStringArray)) {
                gde_bind_and_call!(VARIANT_TYPE, "append_array", 1120103966)(&this, value);
            }
        } else static if (is(Y == T)) {

            // Insert single element
            static if (__traits(isIntegral, T)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 694024632, bool)(&this, cast(GDExtensionInt)value);
            } else static if (__traits(isFloating, T)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 4094791666, bool)(&this, cast(double)value);
            } else static if (is(T == Vector2)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 4188891560, bool)(&this, value);
            } else static if (is(T == Vector3)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 3295363524, bool)(&this, value);
            } else static if (is(T == Vector4)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 3289167688, bool)(&this, value);
            } else static if (is(T == Color)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 1007858200, bool)(&this, value);
            } else static if (is(T == String)) {
                gde_bind_and_call!(VARIANT_TYPE, "push_back", 816187996, bool)(&this, value);
            } else {
                static assert(0, "Invalid PackedArray type "~T.stringof);
            }
        } else {
            static assert(0, "Incompatible type "~Y.stringof~" for this array of type "~T.stringof~".");
        }
    }
}

/**
    A packed array of bytes.
*/
alias PackedByteArray = PackedArray!(ubyte, "PackedByteArray", VARIANT_SIZE_PACKEDBYTEARRAY);

/**
    A packed array of 32-bit integers.
*/
alias PackedInt32Array = PackedArray!(int, "PackedInt32Array", VARIANT_SIZE_PACKEDINT32ARRAY);

/**
    A packed array of 64-bit integers.
*/
alias PackedInt64Array = PackedArray!(long, "PackedInt64Array", VARIANT_SIZE_PACKEDINT64ARRAY);

/**
    A packed array of 32-bit floating point numbers.
*/
alias PackedFloat32Array = PackedArray!(float, "PackedFloat32Array", VARIANT_SIZE_PACKEDFLOAT32ARRAY);

/**
    A packed array of 64-bit floating point numbers.
*/
alias PackedFloat64Array = PackedArray!(double, "PackedFloat64Array", VARIANT_SIZE_PACKEDFLOAT64ARRAY);

/**
    A packed array of Godot Strings.
*/
alias PackedStringArray = PackedArray!(String, "PackedStringArray", VARIANT_SIZE_PACKEDSTRINGARRAY);

/**
    A packed array of 2D vectors.
*/
alias PackedVector2Array = PackedArray!(Vector2, "PackedVector2Array", VARIANT_SIZE_PACKEDVECTOR2ARRAY);

/**
    A packed array of 3D vectors.
*/
alias PackedVector3Array = PackedArray!(Vector3, "PackedVector3Array", VARIANT_SIZE_PACKEDVECTOR3ARRAY);

/**
    A packed array of 4D vectors.
*/
alias PackedVector4Array = PackedArray!(Vector4, "PackedVector4Array", VARIANT_SIZE_PACKEDVECTOR4ARRAY);

/**
    A packed array of colors.
*/
alias PackedColorArray = PackedArray!(Color, "PackedColorArray", VARIANT_SIZE_PACKEDCOLORARRAY);