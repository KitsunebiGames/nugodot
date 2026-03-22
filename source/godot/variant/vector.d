/**
    Binding to Godot's Vector Variants

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.vector;
import godot.core.gdextension.iface;
import numem.core.math;
import godot.variant;
import std.traits;

/**
    A Godot vector.
*/
struct VectorImpl(T, int dims) {
private:
@nogc:

    static if (is(T == gd_float)) {
        alias fromVariantFunc = mixin("vector", dims, "_from_variant");
        enum VARIANT_TYPE = mixin("GDEXTENSION_VARIANT_TYPE_VECTOR", dims);
    } else static if (is(T == int)) {

        alias fromVariantFunc = mixin("vector", dims, "i_from_variant");
        enum VARIANT_TYPE = mixin("GDEXTENSION_VARIANT_TYPE_VECTOR", dims, "I");
    } else {

        static assert(0, typeof(this).stringof~" not supported by Godot.");
    }

public:
    union {
        T[dims] coord = 0;

        struct {
            union {
                T x;
                T width;
            }
            union {
                T y;
                T height;
            }
            static if (dims >= 3) {
                union {
                    T z;
                    T depth;
                }
            }
            static if (dims >= 4) {
                T w;
            }
        }
    }

    /**
        The type of the variant.
    */
    enum VariantType = VARIANT_TYPE;

    /**
        Constructs a vector from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        fromVariantFunc(&this, &variant);
    }

    /**
        Constructs a new vector.
    */
    this(Args...)(Args args) {
        static if (is(typeof(args[0]) == VectorImpl!U, U...)) {
            static foreach(i; 0..nu_min(dims, args[0].dims)) {
                this.coord[i] = cast(T)args[0].coord[i];
            }
        } else static if (allSameType!(Args) && __traits(isScalar, Args[0])) {
            static foreach(i; 0..nu_min(dims, args.length)) {
                this.coord[i] = cast(T)args[i];
            }
        } else {
            static assert(0, "Can't construct Vector with argument types ", Args.stringof);
        }
    }
}

enum Axis {
    AXIS_X = 0,
    AXIS_Y = 1,
    AXIS_Z = 2,
    AXIS_W = 3
}

alias Vector2 = VectorImpl!(gd_float, 2);
alias Vector2i = VectorImpl!(int, 2);
alias Vector3 = VectorImpl!(gd_float, 3);
alias Vector3i = VectorImpl!(int, 3);
alias Vector4 = VectorImpl!(gd_float, 4);
alias Vector4i = VectorImpl!(int, 4);