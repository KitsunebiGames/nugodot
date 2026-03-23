# NuGodot

NuGodot is numem based bindings to GDExtension, allowing writing Godot extensions in DLang using nogc D constructs.

## Requirements

LDC 1.40 or newer is required to compile the project. `nugodot` uses `@section` from LDC to automate loading
bound classes.

## Building the bindings

To build the bindings an installation of Godot must either be in your `PATH`, or must be specified by setting
the `GODOT_PATH` environment varianble. The bindings will then automatically generate when you build your project.

If you ever need to rebuild the bindings, build nugodot with the `rebuild` configuration.

## Using nugodot
nugodot is built around a mixin called `GodotClass`, to register classes with godot, attach this mixin to the type.

### Example
```d
import godot;
import godot.node2d;

class MyClass : Node2D {
protected:
@nogc:

    override void process_(float delta) {
        this.rotate(0.1);
    }
}
mixin GodotClass!MyClass;
```

This example will register a type called `MyClass` extending from `Node2D`,
this node will proceed to rotate the node whenever the game is running.

Note that various types will be wrapped and unwrapped for you internally in the API.