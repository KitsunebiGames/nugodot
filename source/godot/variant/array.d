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

    // Helper that sets the type of the array.
    void setTyped() {
        static if (is(T : GDEObject)) {
            StringName p_classname = StringName(classNameOf!T);
        } else {
            StringName p_classname;
        }
        
        Variant p_script;
        array_set_typed(&this, variantTypeOf!T, &p_classname, &p_script);
    }

public:

    /**
        The type of the variant.
    */
    enum Type = GDEXTENSION_VARIANT_TYPE_ARRAY;

    /**
        Gets whether this TypedArray is compatible with a given PackedArray
    */
    template isCompatibleWithPacked(U) {
        enum isCompatibleWithPacked = isPackedArray!U && ((PackedArrayType!T == U.Type) || is(T == Variant));
    }

    /**
        Gets whether 2 TypedArrays are compatible.
    */
    template isCompatibleWithArray(U) {
        enum isCompatibleWithArray = is(Y == TypedArray!Y, Y...) && (is(U == typeof(this)) || is(T == Variant));
    }

    /**
        Gets whether the given type is compatible with this array.
    */
    template isCompatibleWithType(U) {
        enum isCompatibleWithType = is(T == Variant) || is(T == U);
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
        Makes a new instance of the given array type.
    */
    static typeof(this) makeNew() {
        return typeof(this)(0);
    }

    /**
        Creates a new array with elements pre-reserved.

        Params:
            reserved = The amoutn of elements to reserve.
    */
    this(size_t reserved) {
        gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 0)(&this);
        this.setTyped();
        if (reserved > 0)
            this.resize(reserved);
    }

    /**
        Constructs a new array from a packed array.

        Params:
            from = The packed byte array to create the array from.
    */
    this(U)(auto ref U from) 
    if (!isPackedArray!T && isCompatibleWithPacked!U) {
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 3)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 4)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 5)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 6)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 7)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 8)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 9)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 10)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR4_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 12)(&this, &from);
        static if(U.Type == GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY)
            gde_bcall_ctor!(GDEXTENSION_VARIANT_TYPE_ARRAY, 11)(&this, &from);
        else
            static assert(0, "Invalid packed array type?!");

        this.setTyped();
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
        Assigns the data of this array to the data of another.

        Params:
            other = The array to assign from.
    */
    void assign(U)(auto ref Y other)
    if (isCompatibleWithArray!Y) {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "assign", 2307260970)(&this, other);
    }

    /**
        Reverses the array.
    */
    void reverse() {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "reverse", 3218959716)(&this);
    }

    /**
        Shuffles the array.
    */
    void shuffle() {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "shuffle", 3218959716)(&this);
    }

    /**
        Sorts the array.
    */
    void sort() {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "sort", 3218959716)(&this);
    }

    /**
        Sorts the array using the given callable.

        Params:
            callable = The callable to invoke to determine whether to swap 2 elements.
    */
    void sort(Callable callable) {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "sort_custom", 3470848906)(&this, callable);
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
        Clears the array.
    */
    void clear() {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "clear", 3218959716)(&this);
    }

    /**
        Pops the element at the given index, removing it from the array.

        Params:
            index = The index to pop
        
        Returns:
            The value at that index.
    */
    T popAt(size_t index) {
        return gde_unwrap!T(gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "pop_at", 3518259424, Variant)(&this, cast(GDExtensionInt)index));
    }

    /**
        Pops the first element of the array.

        Returns:
            The value that was at the front.
    */
    T popFront() {
        return gde_unwrap!T(gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "pop_front", 1321915136, Variant)(&this));
    }

    /**
        Pops the last element of the array.

        Returns:
            The value that was at the back.
    */
    T popBack() {
        return gde_unwrap!T(gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "pop_back", 1321915136, Variant)(&this));
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
        Removes the given value from the array.

        Params:
            value = The value to remove all instances of from the array.
    */
    void erase(T value) {
        gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "erase", 3316032543)(&this, gde_wrap(value));
    }

    /**
        Fills the array with the given value.

        Params:
            value = The value to fill the array with.
    */
    void fill(U)(auto ref U value)
    if (isCompatibleWithType!U) {
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
    void pushFront(U)(auto ref U value)
    if (isCompatibleWithType!U) {
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
    void pushBack(U)(auto ref U value)
    if (isCompatibleWithArray!U || isCompatibleWithType!U) {
        static if (isCompatibleWithArray!U) {
            gde_bcall_builtin!(GDEXTENSION_VARIANT_TYPE_ARRAY, "append_array", 2307260970)(&this, value);
        } else static if (is(T == Variant)) {
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
    void insert(U)(auto ref U value, ptrdiff_t at)
    if (isCompatibleWithType!U) {
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
    void opIndexAssign(U)(auto ref U value, size_t index)
    if (isCompatibleWithType!U) {
        static if (is(T == Variant) && is(U == Variant)) {
            if (auto p_variant = cast(Variant*)array_operator_index(&this, index)) {
                *p_variant = value;
            }
        } else {
            if (auto p_variant = cast(Variant*)array_operator_index(&this, index)) {
                *p_variant = gde_wrap!U(value);
            }
        }
    }

    /**
        Appends a value to the array.

        Params:
            value = The value to append, can be another array of compatible type.
    */
    void opOpAssign(string op="~", U)(auto ref U value)
    if (isCompatibleWithType!U || isCompatibleWithArray!U) {
        static if (isCompatibleWithArray!U) {
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
        Constructs a new packed array with a given amount of elements
        reserved.

        Params:
            reserved = The amount of elements to reserve.
    */
    this(size_t reserved) {
        gde_bcall_ctor!(VARIANT_TYPE, 0)(&this);
        if (reserved > 0) {
            this.resize(reserved);
        }
    }

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