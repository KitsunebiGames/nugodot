/**
    Binding to Godot's Array Variants

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.array;
import godot.core.gdextension.variant_size;
import godot.core.gdextension.iface;
import godot.core.wrap;
import godot.core.traits;
import godot.core.object;
import godot.variant;

import numem.core.traits;
import numem.core.meta;
import numem;

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

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_ARRAY;

    /**
        Makes a new instance of the given array type.
    */
    static typeof(this) makeNew() {
        typeof(this) p_arr;
        gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 0)(&p_arr);
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
    @property size_t size() => cast(size_t)gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "size", 3173160232, GDExtensionInt)(&this);

    /**
        Whether the array is empty.
    */
    @property bool isEmpty() => gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "is_empty", 3918633141, bool)(&this);

    /**
        The hash of this array.
    */
    @property ulong hash() => gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "hash", 3918633141, GDExtensionInt)(&this);

    /**
        Whether the array is read-only.
    */
    @property bool isReadonly() => cast(bool)gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "is_read_only", 3918633141, GDExtensionBool)(&this);

    /**
        Whether this array is valid.
    */
    @property bool isValid() => this != typeof(this).init;

    /**
        The first element of the array.
    */
    @property T front() {
        static if (is(T == Variant)) {
            return gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "front", 1460142086, Variant)(&this);
        } else {
            return gde_unwrap!T(gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "front", 1460142086, Variant)(&this));
        }
    }

    /**
        The last element of the array.
    */
    @property T back() {
        static if (is(T == Variant)) {
            return gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "back", 1460142086, Variant)(&this);
        } else {
            return gde_unwrap!T(gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "back", 1460142086, Variant)(&this));
        }
    }

    /**
        Constructs an array from a variant.

        Params:
            variant = The variant.
    */
    this()(auto ref Variant variant) {
        array_from_variant(&this, &variant);
    }

    /**
        Makes a duplicate of this array.

        Params:
            deep = Whether to make a deep copy of the array.
        
        Returns:
            A new array that is a duplicate of this array.
    */
    typeof(this) duplicate(bool deep = false) {
        return gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "duplicate", 636440122, typeof(this))(&this, deep);
    }

    /**
        Clears the array.
    */
    void clear() {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "clear", 3218959716)(&this);
    }

    /**
        Resizes the array.

        Params:
            size = The new size of the array.
    */
    void resize(size_t size) {
        cast(void)gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "resize", 848867239, GDExtensionInt)(&this, cast(GDExtensionInt)size);
    }

    /**
        Removes an element from the array at the given index.

        Params:
            index = The index to remove the element at.
    */
    void removeAt(size_t index) {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "remove_at", 2823966027)(&this, cast(GDExtensionInt)index);
    }

    /**
        Fills the array with the given value.

        Params:
            value = The value to fill the array with.
    */
    void fill()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "fill", 3316032543)(&this, value);
        } else {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "fill", 3316032543)(&this, gde_wrap!T(value));
        }
    }

    /**
        Pushes a value to the front of the array.

        Params:
            value = The value to push.
    */
    void pushFront()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_front", 3316032543)(&this, value);
        } else {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_front", 3316032543)(&this, gde_wrap!T(value));
        }
    }

    /**
        Pushes a value to the back of the array.

        Params:
            value = The value to push.
    */
    void pushFront()(auto ref T value) {
        static if (is(T == Variant)) {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_back", 3316032543)(&this, value);
        } else {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "push_back", 3316032543)(&this, gde_wrap!T(value));
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
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "insert", 3176316662)(&this, cast(GDExtensionInt)at, value);
        } else {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "insert", 3176316662)(&this, cast(GDExtensionInt)at, gde_wrap!T(value));
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
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append_array", 2307260970)(&this, value);
        } else static if (is(T == Variant)) {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append", 3316032543)(&this, value);
        } else {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append", 3316032543)(&this, gde_wrap!T(value));
        }
    }
}

/**
    Gets a D slice from a packed Godot Array.

    Params:
        array = The packed array to "transform" to a D array.

    Returns:
        A D slice over the packed godot array.
*/
T[] gde_from_packed_array(T)(auto ref PackedArray!T array) @nogc {
    return array.ptrw[0..array.size];
}

/**
    Wraps a D array with a packed array.

    Params:
        array = The D slice to create a new packed array from.

    Returns:
        A packed array.
*/
PackedArray!T gde_to_packed_array(T)(T[] array) @nogc {
    return PackedArray!T(array);
}

/**
    A godot packed array.
*/
struct PackedArray(T) {
private:
@nogc:
    void[VARIANT_SIZE_PACKEDBYTEARRAY] __data;

    static if (is(ArrayT == ubyte) || is(ArrayT == byte)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY;
        alias ptr_idx_func = packed_byte_array_operator_index;
        alias ptrw_idx_func = packed_byte_array_operator_index_const;
        alias from_variant_func = packed_byte_array_from_variant;
        alias to_variant_func = variant_from_packed_byte_array;
    } else static if (is(ArrayT == int) || is(ArrayT == uint)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY;
        alias ptr_idx_func = packed_int32_array_operator_index;
        alias ptrw_idx_func = packed_int32_array_operator_index_const;
        alias from_variant_func = packed_int32_array_from_variant;
        alias to_variant_func = variant_from_packed_int32_array;
    } else static if (is(ArrayT == long) || is(ArrayT == ulong)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY;
        alias ptr_idx_func = packed_int64_array_operator_index;
        alias ptrw_idx_func = packed_int64_array_operator_index_const;
        alias from_variant_func = packed_int64_array_from_variant;
        alias to_variant_func = variant_from_packed_int64_array;
    } else static if (is(ArrayT == float)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY;
        alias ptr_idx_func = packed_float32_array_operator_index;
        alias ptrw_idx_func = packed_float32_array_operator_index_const;
        alias from_variant_func = packed_float32_array_from_variant;
        alias to_variant_func = variant_from_packed_float32_array;
    } else static if (is(ArrayT == double)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY;
        alias ptr_idx_func = packed_float64_array_operator_index;
        alias ptrw_idx_func = packed_float64_array_operator_index_const;
        alias from_variant_func = packed_float64_array_from_variant;
        alias to_variant_func = variant_from_packed_float64_array;
    } else static if (is(ArrayT == String)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY;
        alias ptr_idx_func = packed_string_array_operator_index;
        alias ptrw_idx_func = packed_string_array_operator_index_const;
        alias from_variant_func = packed_string_array_from_variant;
        alias to_variant_func = variant_from_packed_string_array;
    } else static if (is(ArrayT == Vector2)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY;
        alias ptr_idx_func = packed_vector2_array_operator_index;
        alias ptrw_idx_func = packed_vector2_array_operator_index_const;
        alias from_variant_func = packed_vector2_array_from_variant;
        alias to_variant_func = variant_from_packed_vector2_array;
    } else static if (is(ArrayT == Vector3)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY;
        alias ptr_idx_func = packed_vector3_array_operator_index;
        alias ptrw_idx_func = packed_vector3_array_operator_index_const;
        alias from_variant_func = packed_vector3_array_from_variant;
        alias to_variant_func = variant_from_packed_vector3_array;
    } else static if (is(ArrayT == Vector4)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR4_ARRAY;
        alias ptr_idx_func = packed_vector4_array_operator_index;
        alias ptrw_idx_func = packed_vector4_array_operator_index_const;
        alias from_variant_func = packed_vector4_array_from_variant;
        alias to_variant_func = variant_from_packed_vector4_array;
    } else static if (is(ArrayT == Color)) {
        enum VARIANT_TYPE = GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY;
        alias ptr_idx_func = packed_color_array_operator_index;
        alias ptrw_idx_func = packed_color_array_operator_index_const;
        alias from_variant_func = packed_color_array_from_variant;
        alias to_variant_func = variant_from_packed_color_array;
    } else {
        static assert(0, "No PackedArray type for type "~T.stringof);
    }

public:

    /**
        The unqualified type of the packed array's contents.
    */
    alias ArrayT = Unqual!T;

    /**
        The type of the variant.
    */
    enum Type = VARIANT_TYPE;

    /**
        Function used to convert a packed array to a variant.
    */
    alias variant_from_packed_array = to_variant_func;

    /**
        Function used to convert a variant to a packed array.
    */
    alias packed_array_from_variant = from_variant_func;
    
    /**
        Size of the packed array.
    */
    @property GDExtensionInt size() => gde_bcall_builtin!(VARIANT_TYPE, "size", 3173160232, GDExtensionInt)(&this);

    /**
        Pointer to the data stored in the packed array.
    */
    @property T* ptrw() => cast(T*)ptrw_idx_func(&this, 0);

    /**
        Writable pointer to the data stored in the packed array.
    */
    @property const(T)* ptr() => cast(const(T)*)ptr_idx_func(&this, 0);

    /**
        Constructs a new packed array from a D slice.

        Params:
            data =  The slice of data to construct this packed array with.
                    The slice will be freed on completion.
    */
    this(T[] data) {
        gde_bcall_ctor!(VARIANT_TYPE, 0)(&this);
        
        if (data) {
            this.resize(data.length);
            nu_memcpy(this.ptrw, data.ptr, data.length*T.sizeof);
            nu_free(data.ptr);
        }
    }

    /**
        Constructs a packed array from a variant.

        Params:
            variant = The variant to get the array from.
    */
    this()(auto ref Variant variant) {
        from_variant_func(&this, &variant);
    }

    /**
        Constructs a copy of this packed array.

        Params:
            other = The other array to construct this array from.
    */
    this(ref return scope typeof(this) other) {
        gde_bcall_ctor!(VARIANT_TYPE, 1)(&this, &other);
    }

    /**
        Resizes the array.

        Params:
            size = The new size of the array.
    */
    void resize(size_t size) {
        cast(void)gde_bcall_builtin!(VARIANT_TYPE, "resize", 848867239, GDExtensionInt)(&this, cast(GDExtensionInt)size);
    }

    /**
        Indexes the array

        Params:
            index = The index to get from the array.
    */
    T opIndex(size_t index) {
        if (T* element = cast(T*)ptr_idx_func(&this, index))
            return *element;
        return T.init;
    }

    /**
        Slice operator overloading.
    */
    T[] opIndex() {
        return ptrw[0..size];
    }

    /**
        Dollar operator overloading.
    */
    size_t opDollar() {
        return size;
    }
}