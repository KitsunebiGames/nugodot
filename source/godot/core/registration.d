module godot.core.registration;
import godot.core.object;
import godot.core.traits;
import numem;

/**
    The name of the section that GDExtension Type registrations will be put into.
*/
enum GDE_SECTION_NAME = ".gdetyp";

/**
    Registration info for a godot class.
*/
struct GDEClassRegistrationInfo {
@nogc:

    /**
        Name of the class.
    */
    string name;

    /**
        XML documentation of the class.
    */
    string docs;

    /**
        Inheritance depth of the registered class.
    */
    size_t inheritDepth;

    /**
        Registration function for the class.
    */
    extern(C) void function() @nogc nothrow registration;

    /**
        Un-registration function for the class.
    */
    extern(C) void function() @nogc nothrow unregistration;
}

/**
    Fetches all of the registration metadata stored for this GDExtension.

    Returns:
        A slice over all the registered extension types..
*/
GDEClassRegistrationInfo[] gde_get_registrations() @nogc nothrow {
    version(linux) {

        // NOTE:    Linux relies on a linker trick that creates a special
        //          section guard with the structs inside, these structs
        //          are already decorated with the neccesary function pointers.
        GDEClassRegistrationInfo* addr = &__start___gde_registration;
        size_t startAddr = cast(size_t)(cast(void*)&__start___gde_registration);
        size_t stopAddr = cast(size_t)(cast(void*)&__stop___gde_registration);
        size_t length = (stopAddr-startAddr);
        return addr[0..(length/GDEClassRegistrationInfo.sizeof)];
    } else version(Windows) {
        __gshared GDEClassRegistrationInfo[] __registrations;

        // NOTE:    On Windows we manually walk the sections with the Win32 API
        //          then find the section and store it in a temporary variable
        //          for performance.
        if (!__registrations) {
            import core.stdc.stdio;
            import core.sys.windows.winbase;

            HMODULE module_;
            if (GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, cast(LPCWSTR)&gde_get_registrations, &module_)) {

                PESectionInfo[] sections = pe_enumerate_sections(module_);
                foreach(i, sect; sections) {

                    if (sect.name == GDE_SECTION_NAME) {
                        GDEClassRegistrationInfo* addr = cast(GDEClassRegistrationInfo*)sect.start;
                        size_t startAddr = cast(size_t)sect.start;
                        size_t stopAddr = cast(size_t)sect.end;
                        size_t length = (stopAddr-startAddr);
                        __registrations = addr[0..(length/GDEClassRegistrationInfo.sizeof)];
                        break;
                    }
                }

                nu_freea(sections);
            }
        }

        return __registrations;
    }
}

/**
    Registers a class with Godot's type system.
*/
mixin template GodotClass(T)
if (is(T : GDEObject)) {
    import ldc.attributes;
    import godot.core.traits : getInheritanceDepth;
    import godot.core.registration : GDEClassRegistrationInfo, GDE_SECTION_NAME;
    import godot.core.traits : gdeMangleOf, classNameOf, xmldocOf;
    import godot.core.bind : gde_bind_class, gde_unbind_class;

    private __gshared auto _bind_funcinst = &gde_bind_class!T;
    private __gshared auto _unbind_funcinst = &gde_unbind_class!T;

    // Add documentation
    enum XMLDOC = xmldocOf!T;

    @section(GDE_SECTION_NAME)
    pragma(mangle, gdeMangleOf!(T, __registration))
    export __gshared GDEClassRegistrationInfo __registration = GDEClassRegistrationInfo(
        name: classNameOf!T,
        inheritDepth: getInheritanceDepth!T,
        docs: XMLDOC.length > 0 ? XMLDOC : null,
        registration: cast(typeof(GDEClassRegistrationInfo.registration))&gde_bind_class!T,
        unregistration: cast(typeof(GDEClassRegistrationInfo.unregistration))&gde_unbind_class!T,
    );
}




///
///                 IMPLEMENTATION DETAILS.
///
private:

version(linux) {
    extern(C) extern GDEClassRegistrationInfo __start___gde_registration;
    extern(C) extern GDEClassRegistrationInfo __stop___gde_registration;
}

version(Windows) {
    import core.sys.windows.winnt;

    /**
        Information about sections.
    */
    struct PESectionInfo {
    @nogc:

        /**
            Name of the section
        */
        string name;

        /**
            Start address of the section
        */
        void* start;

        /**
            End address of the section
        */
        void* end;
    }

    PESectionInfo[] pe_enumerate_sections(void* base) @nogc nothrow {
        void* handle = pe_module_verify(base);
        if (!handle)
            return null;

        // NOTE:    If a file has no sections we're probably reading a very messed up
        //          PE file, so we'll stop there.
        //
        // NOTE:    shdrs is a slice into existing memory, DO NOT FREE.
        IMAGE_SECTION_HEADER[] shdrs = pe_get_section_header(handle);
        if (shdrs.length == 0)
            return null;
        
        PESectionInfo[] sections;
        sections = nu_malloca!PESectionInfo(shdrs.length);
        foreach(i, ref IMAGE_SECTION_HEADER shdr; shdrs) {
            sections[i] = PESectionInfo(
                pe_module_get_sect_name(shdr.Name),
                base+shdr.VirtualAddress,
                base+shdr.VirtualAddress+shdr.Misc.VirtualSize
            );
        }
        return sections;
    }

    void* pe_rva_to_addr(void* handle, void* rva) @nogc nothrow {
        return handle+cast(ptrdiff_t)rva;
    }

    IMAGE_SECTION_HEADER[] pe_get_section_header(void* handle) @nogc nothrow {
        IMAGE_NT_HEADERS* nthdr = cast(IMAGE_NT_HEADERS*)handle;
        IMAGE_SECTION_HEADER* start = cast(IMAGE_SECTION_HEADER*)(handle+IMAGE_NT_HEADERS.sizeof);
        return start[0..nthdr.FileHeader.NumberOfSections];
    }

    void* pe_module_verify(void* base) @nogc nothrow {
        if (!base) return null;
        ushort magic = *cast(ushort*) base;

        // 'MZ' DOS Header
        if (magic != 0x5A4D)
            return null;


        // NOTE:    e_lfanew is at offset 0x3C, always.
        //          it being reserved in the DOS header, means we can make our
        //          life simpler by simply just passing that in from the start.
        int e_lfanew = *cast(int*)(base + 0x3C);
        void* handle = base + e_lfanew;
        IMAGE_NT_HEADERS* nthdr = cast(IMAGE_NT_HEADERS*) handle;

        // Not a PE file?
        if (nthdr.Signature != 0x00004550)
            return null;

        // No sections? what?
        if (nthdr.FileHeader.NumberOfSections == 0)
            return null;

        return handle;
    }

    string pe_module_get_sect_name(ref ubyte[8] name) @nogc nothrow {
        foreach(i; 0..name.length) {
            if (name[i] == '\0')
                return cast(string)name[0..i];
        }
        return cast(string)name;
    }
}