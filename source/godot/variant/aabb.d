module godot.variant.aabb;
import godot.core.gdextension.iface;
import godot.variant.vector;
import numem.core.math;

struct AABB {
    union {
        gd_float[6] aabb = 0;
        struct {
            Vector3 position;
            Vector3 size;
        }
        struct {
            gd_float x;
            gd_float y;
            gd_float z;
            gd_float width;
            gd_float height;
            gd_float depth;
        }
    }

    /**
        The volume of the bounding box.
    */
    @property gd_float volume() => width*height*depth;

}