module generator.types;
import generator.writer;
import generator.utils;
import generator.ddoc;
import std.json;

enum INTERFACE_SCHEMA = 0;
enum API_SCHEMA = 1;

static immutable BASIC_TYPE_NAMES = [
    "size_t",
    "ptrdiff_t",
    "uint8_t",
    "int8_t",
    "uint16_t",
    "int16_t",
    "uint32_t",
    "int32_t",
    "uint64_t",
    "int64_t",
    "float",
    "double",
    "char",
    "dchar",
    "wchar",
    "void"
];

/**
    A registry of GDEType types.
*/
final
class GDETypeRegistry {
private:
    GDEType[] types_;
    ptrdiff_t findIndexOf(string name, ptrdiff_t start = 0) {
        if (start >= types_.length)
            return -1;

        // TODO:    parse the shenanigans that godot does for types
        //          in the API schema.
        foreach(i, type; types_[start..$]) {
            if (type.name == name)
                return i;
        }
        return -1;
    }

public:

    /**
        Constructs a new type registry.
    */
    this() {
        static foreach(basicType; BASIC_TYPE_NAMES) {
            this.basicType(basicType);
        }
    }

    /**
        List of all registered types in the registry.
    */
    @property GDEType[] types() => types_;

    /**
        Finds a type with the given name.

        Params:
            name = The name to look for.
    */
    GDEType find(string name) {
        ptrdiff_t idx = this.findIndexOf(name);
        return idx >= 0 ? types_[idx] : null;
    }

    /**
        Finds a type with the given name.

        Params:
            name = The name to look for.
    */
    GDEType findOrAssumeBasic(string name) {
        ptrdiff_t idx = this.findIndexOf(name);
        return idx >= 0 ? types_[idx] : this.basicType(name);
    }

    /**
        Gets a given basic type.

        Params:
            name =  The name of the basic type to get or create.
    */
    GDEType basicType(string name) {
        ptrdiff_t idx = this.findIndexOf(name);
        if (idx >= 0)
            return types_[idx];
        
        return this.add(new GDEBasicType(name));
    }

    /**
        Gets a given basic type.
    */
    GDEType basicType(T)() {
        return this.basicType(T.stringof);
    }

    /**
        Adds a type to the registry.

        Param:
            type =  The type added.
    */
    GDEType add(GDEType type) {
        types_ ~= type;
        return type;
    }

    /**
        Finds or adds a new type of the given name.

        Params:
            name =  Name of the type to find or add.
            args =  Arguments to pass to the constructor of
                    the type if it couldn't be found.
    */
    T findOrAdd(T, Args...)(string name, Args args)
    if (is(T : GDEType)) {
        ptrdiff_t idx = this.findIndexOf(name);
        do {
            if (cast(T)types_[idx])
                break;

            idx = this.findIndexOf(name, idx);
        } while(idx >= -1);

        if (idx >= 0)
            return cast(T)types_[idx];
        
        return new T(args);
    }

    /**
        Finalizes the registry, making all the types
        within it realized.
    */
    void finalize() {
        foreach(type; types_)
            type.finalize(this);
    }
}

/**
    Base-class of GDExtension type info.
*/
abstract
class GDEType {
private:
    string name_;
    DDOC ddoc_;

protected:

    /**
        Name of the type.
    */
    final @property void name(string value) {
        this.name_ = value;
    }

    /**
        DDOC documentation for the type.
    */
    final @property void ddoc(DDOC value) {
        this.ddoc_ = value;
    }

public:

    /**
        Parses a type from a C type string.
    
        Params:
            typeString =    A C string of a given type.
            registry =      The registry to search.
    */
    static GDEType fromCTypeString(string typeString, GDETypeRegistry registry) {
        GDEType type;

        string buffer = typeString;
        while(buffer.length > 0) {
            buffer.popWhite();
            
            // Const qualifier.
            if (buffer.pop("const ")) {
                type = new GDEConstQualifier(type);
                continue;
            }

            if (buffer.pop("*")) {
                type = new GDEPointer(type);
                continue;
            }

            if (string iden = buffer.popIdentifier()) {
                if (auto qual = cast(GDETypeQualifier)type)
                    qual.setBottomType(registry.findOrAssumeBasic(iden));
                else
                    type = registry.findOrAssumeBasic(iden);
                continue;
            }
        }
        return type;
    }

    /**
        Name of the type.
    */
    @property string name() => name_;

    /**
        DDOC documentation for the type.
    */
    final @property DDOC ddoc() => ddoc_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    abstract void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry);

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    abstract void finalize(GDETypeRegistry registry);

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        return name;
    }
}

/**
    A named member of a type.
*/
abstract
class GDEMember : GDEType {
public:

    /**
        Name of the type of the member.
    */
    abstract @property GDEType type();

    /**
        Name of the value of the member.
    */
    abstract @property string value();

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        
        if (value)
            return "%s %s = %s".format(type.toString(), name, value);
        return "%s %s".format(type.toString(), name);
    }
}

/**
    Base class of type qualifiers.
*/
abstract
class GDETypeQualifier : GDEType {
private:
    GDEType subtype_;

public:

    /**
        The subtype of the qualifier.
    */
    final @property GDEType subtype() => subtype_;
    final @property void subtype(GDEType value) {
        this.subtype_ = value;
    }

    /**
        Creates a new qualifier, qualifying the given type.

        Params:
            subtype =   The subtype being pointed to.
    */
    this(GDEType subtype) {
        this.subtype_ = subtype;
    }

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) { }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override void finalize(GDETypeRegistry registry) { }

    /**
        Sets the bottom type of the type qualifier hirearchy.

        Params:
            type =  The type to set as the bottom level type.
    */
    void setBottomType(GDEType type) {
        GDETypeQualifier iter = this;
        while(cast(GDETypeQualifier)iter.subtype)
            iter = cast(GDETypeQualifier)iter.subtype;
        iter.subtype = type;
    }
}

/**
    Base class of aggregate types.
*/
abstract
class GDEAggregate : GDEType {
public:

    /**
        The members of the aggregate.
    */
    abstract @property GDEMember[] members();

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        foreach(member; members) {
            member.finalize(registry);
        }
    }
}

/**
    A basic type.
*/
class GDEBasicType : GDEType {
public:
    this(string name) {
        this.name = name;
    }

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) { }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override void finalize(GDETypeRegistry registry) { }
}

/**
    A pointer type.
*/
class GDEPointer : GDETypeQualifier {
public:
    
    /**
        Name of the type.
    */
    override @property string name() => subtype.name~"*";

    /**
        Creates a new pointer, pointing to the given type.

        Params:
            subtype =   The subtype being pointed to.
    */
    this(GDEType subtype) {
        super(subtype);
    }
}

/**
    A const type qualifier
*/
class GDEConstQualifier : GDETypeQualifier {
public:
    
    /**
        Name of the type.
    */
    override @property string name() => "const("~subtype.name~")";

    /**
        Creates a new pointer, pointing to the given type.

        Params:
            subtype =   The subtype being pointed to.
    */
    this(GDEType subtype) {
        super(subtype);
    }
}

/**
    Represents an enumeration
*/
class GDEEnum : GDEAggregate {
private:
    GDEMember[] members_;

public:

    /**
        Members of the enum.
    */
    override @property GDEMember[] members() => members_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                foreach(mjson; json["values"].array) {
                    auto member = new GDEEnumMember();
                    member.parse(mjson, schema, registry);
                    this.members_ ~= member;
                }
                return;

            default:
                return;
        }
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        return "(enum %s (%s))".format(name, members.strJoin(", "));
    }
}

/**
    An enum member.
*/
class GDEEnumMember : GDEMember {
private:
    GDEType type_;
    string value_;

public:

    /**
        Type of the member.
    */
    override @property GDEType type() => type_;

    /**
        Value of the type.
    */
    override @property string value() => value_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                if ("value" in json)
                    this.value_ = json["value"].toString();
                
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        this.type_ = registry.basicType!uint;
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        return "%s = %s".format(name, value);
    }
}

/**
    A type alias/typedef.
*/
class GDEAlias : GDEType {
private:
    string pTypeName_;
    GDEType pType_;

public:

    /**
        Parent type of the alias.
    */
    @property GDEType type() => pType_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                this.pTypeName_ = json["type"].str;
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        this.pType_ = GDEType.fromCTypeString(pTypeName_, registry);
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        return "(alias %s = %s)".format(name, type.toString());
    }
}

/**
    A native handle.
*/
class GDEHandle : GDEType {
private:
    bool isConst_;
    GDEType type_;

public:

    /**
        Whether the handle is const.
    */
    @property bool isConst() => isConst_;

    /**
        The type of the handle.
    */
    @property GDEType type() => type_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                this.isConst_ = "is_const" in json && json["is_const"].boolean;
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        GDEType type = registry.basicType("void");
        if (isConst)
            type = new GDEConstQualifier(type);
        
        this.type_ = new GDEPointer(type);
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        return "(handle %s = %s)".format(name, type.toString());
    }
}

/**
    A data structure.
*/
class GDEStruct : GDEAggregate {
private:
    GDEMember[] members_;

public:

    /**
        Members of the struct.
    */
    override @property GDEMember[] members() => members_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                foreach(mjson; json["members"].array) {
                    auto member = new GDEStructMember();
                    member.parse(mjson, schema, registry);
                    this.members_ ~= member;
                }
                return;

            default:
                return;
        }
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)
        import std.format;
        return "(struct %s (%s))".format(name, members_.strJoin(", "));
    }
}

/**
    A struct member.
*/
class GDEStructMember : GDEMember {
private:
    string typeName_;
    GDEType type_;
    string value_;

public:

    /**
        Type of the member.
    */
    override @property GDEType type() => type_;

    /**
        Value of the type.
    */
    override @property string value() => value_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;
                this.typeName_ = json["type"].str;

                if ("value" in json)
                    this.value_ = json["value"].toString();
                
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        this.type_ = GDEType.fromCTypeString(typeName_, registry);
    }
}

/**
    A function protoype.
*/
class GDEFuncPrototype : GDEType {
private:
    string rTypeName_;
    GDEType return_;
    GDEFuncParam[] params_;

public:

    /**
        The type of the return value.
    */
    @property GDEType returnType() => return_;

    /**
        The parameters of the function.
    */
    @property GDEFuncParam[] params() => params_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;

                if ("arguments" in json) {
                    foreach(mjson; json["arguments"].array) {
                        auto param = new GDEFuncParam();
                        param.parse(mjson, schema, registry);
                        this.params_ ~= param;
                    }
                }

                this.rTypeName_ = "return_value" in json ? json["return_value"]["type"].str : null;
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        foreach(param; params_)
            param.finalize(registry);
        
        return_ = rTypeName_ ? GDEType.fromCTypeString(rTypeName_, registry) : registry.basicType("void");
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)

        import std.format;
        return "(func %s (%s) %s)".format(name, params_.strJoin(", "), return_.toString());
    }
}

/**
    A function.
*/
class GDEFunc : GDEType {
private:
    string rTypeName_;
    GDEType return_;
    GDEFuncParam[] params_;

public:

    /**
        The type of the return value.
    */
    @property GDEType returnType() => return_;

    /**
        The parameters of the function.
    */
    @property GDEFuncParam[] params() => params_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        this.ddoc_ = parseDocs(json);

        switch(schema) {
            case INTERFACE_SCHEMA:
                this.name = json["name"].str;

                if ("arguments" in json) {
                    foreach(mjson; json["arguments"].array) {
                        auto param = new GDEFuncParam();
                        param.parse(mjson, schema, registry);
                        this.params_ ~= param;
                    }
                }

                this.rTypeName_ = "return_value" in json ? json["return_value"]["type"].str : null;
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        foreach(param; params_)
            param.finalize(registry);
        
        return_ = rTypeName_ ? GDEType.fromCTypeString(rTypeName_, registry) : registry.basicType("void");
    }

    /**
        Gets a string representation of the type.
    */
    override
    string toString() { // @suppress(dscanner.suspicious.object_const)

        import std.format;
        return "(func %s (%s) %s)".format(name, params_.strJoin(", "), return_.toString());
    }
}

/**
    A function parameter.
*/
class GDEFuncParam : GDEMember {
private:
    string typeName_;
    GDEType type_;
    string value_;

public:

    /**
        Type of the parameter.
    */
    override @property GDEType type() => type_;

    /**
        Default value of the parameter, can be empty.
    */
    override @property string value() => value_;

    /**
        Parses the type.
    
        Params:
            json =      The JSON value to parse.
            schema =    The schema being parsed.
            registry =  The type registry.
    */
    override
    void parse(ref JSONValue json, int schema, ref GDETypeRegistry registry) {
        switch(schema) {
            case INTERFACE_SCHEMA:
                if ("name" in json)
                    this.name = json["name"].str;
                
                if ("type" in json)
                    this.typeName_ = json["type"].str;
                return;

            default:
                return;
        }
    }

    /**
        Finalizes the type.

        Params:
            registry =  The type registry.
    */
    override
    void finalize(GDETypeRegistry registry) {
        
        // If a param has no type name (wasn't parsed)
        // then it's probably void.
        if (!typeName_) {
            this.type_ = registry.basicType("void");
            return;
        }

        this.type_ = GDEType.fromCTypeString(typeName_, registry);
    }
}