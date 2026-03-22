/**
    Binding to Godot's Dictionary Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.dict;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.core.wrap;
import godot.variant.variant;
import godot.variant.array;

/**
    Untyped array.
*/
alias Dictionary = TypedDictionary!(Variant, Variant);

/**
    A dictionary.
*/
struct TypedDictionary(TKey, TValue) {
private:
@nogc:
    void[VARIANT_SIZE_DICTIONARY] data_;

public:

    /**
        The size of the dictionary.
    */
    @property size_t size() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "size", 3173160232, GDExtensionInt)(&this);

    /**
        Whether the dictionary is empty.
    */
    @property bool isEmpty() => cast(size_t)gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "is_empty", 3918633141, bool)(&this);

    /**
        The keys of the dictionary.
    */
    @property TypedArray!TKey keys() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "keys", 4144163970, TypedArray!TKey)(&this);

    /**
        The values of the dictionary.
    */
    @property TypedArray!TValue values() => gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "values", 4144163970, TypedArray!TValue)(&this);

    /**
        Constructs an RID from a variant.

        Params:
            variant = The variant.
    */
    this(ref return scope TypedDictionary!(TKey, TValue) other) {
        gde_bind_and_call_ctor!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, 1)(&this, &other);
    }

    /**
        Constructs an RID from a variant.

        Params:
            variant = The variant.
    */
    this()(auto ref Variant variant) {
        dictionary_from_variant(&this, &variant);
    }

    /**
        Indexes the dictionary.

        Params:
            key = The key to index.
        
        Returns:
            The value for the given key if found,
            $(D TValue.init) otherwise.
    */
    TValue opIndex(TKey key) {
        auto p_key = gde_wrap(key);
        return gde_from_gd!TValue(dictionary_operator_index(&this, &p_key));
    }

    /**
        Assigns a value to keys in the dictionary.

        Params:
            value = The value to set.
            key =   The key to set.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool opIndexAssign(TValue value, TKey key) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "set", 2175348267, bool)(&this, gde_wrap(key), gde_wrap(value));
    }

    /**
        Gets whether the dictionary has a given key.

        Params:
            key = The key to query.
        
        Returns:
            $(D true) if the key is present in the dictionary,
            $(D false) otherwise.
    */
    bool has(TKey key) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "has", 3680194679, bool)(&this, gde_wrap(key));
    }

    /**
        Attempts to erase an entry from the dictionar with a given key.

        Params:
            key = The key to erase.
        
        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    bool erase(TKey key) {
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "has", 1776646889, bool)(&this, gde_wrap(key));
    }

    /**
        Clears the dictionary of values.
    */
    void clear() {
        gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "clear", 3218959716)(&this);
    }

    /**
        Gets the dictionary's hash.
    */
    size_t toHash() const @trusted nothrow {        
        return gde_bind_and_call!(GDEXTENSION_VARIANT_TYPE_DICTIONARY, "hash", 3173160232, GDExtensionInt)(cast(TypedDictionary!(TKey, TValue)*)&this);
    }
}