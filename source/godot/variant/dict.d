module godot.variant.dict;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.variant.variant;

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

}