/**
    Binding to Godot's Color Variant

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.variant.color;
import godot.core.gdextension.iface;
import godot.core.gdextension.variant_size;
import godot.variant.variant;

/**
    A 32-bit RGBA Color
*/
struct Color {
public:
@nogc:

    /**
        Red color channel.
    */
    gd_float r;
    
    /**
        Green color channel.
    */
    gd_float g;
    
    /**
        Blue color channel.
    */
    gd_float b;

    /**
        alpha color channel.
    */
    gd_float a;

    /**
        The type of the variant.
    */
    enum VariantType = GDEXTENSION_VARIANT_TYPE_PLANE;

    /**
        Whether the color is HDR (over 0..1 range)
    */
    @property bool isHDR() => r+g+b > 3.0;
    
    /**
        Constructs a Plane from a variant.

        Params:
            variant = The variant to unwrap.
    */
    this()(auto ref Variant variant) {
        color_from_variant(&this, &variant);
    }

    /**
        Constructs a new color from RGBA color values.

        Params:
            r = Red color value
            g = Green color value
            b = Blue color value
            a = Alpha color value
    */
    this(gd_float r, gd_float g, gd_float b, gd_float a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    /**
        Constructs a new color from RGB color values.

        Params:
            r = Red color value
            g = Green color value
            b = Blue color value
    */
    this(gd_float r, gd_float g, gd_float b) {
        this(r, g, b, 1.0);
    }

    /**
        Constructs a new Color from 8-bit RGBA values.

        Params:
            r = Red color value
            g = Green color value
            b = Blue color value
            a = Alpha color value
    */
    this(ubyte r, ubyte g, ubyte b, ubyte a) {
        this.r = cast(float)r / 255.0;
        this.g = cast(float)g / 255.0;
        this.b = cast(float)b / 255.0;
        this.a = cast(float)a / 255.0;
    }

    /**
        Constructs a new Color from 8-bit RGB values.

        Params:
            r = Red color value
            g = Green color value
            b = Blue color value
    */
    this(ubyte r, ubyte g, ubyte b) {
        this(r, g, b, 255);
    }

    /**
        Constructs a new color from 8-bit RGBA values packed
        into an integer.

        Params:
            rgba = 
    */
    this(uint rgba) {
        this(
            cast(ubyte)((rgba >>  0) & 0xFF),
            cast(ubyte)((rgba >>  8) & 0xFF),
            cast(ubyte)((rgba >> 16) & 0xFF),
            cast(ubyte)((rgba >> 24) & 0xFF)
        );
    }
}