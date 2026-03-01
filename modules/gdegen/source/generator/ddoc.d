module generator.ddoc;
import generator.writer;
import numem.core.math;
import std.json;

/**
    A DDOC documentation comment.
*/
struct DDOC {

    /**
        Whether this ddoc instance has any documentation within it.
    */
    bool hasDoc() => this != DDOC.init;

    /**
        One-line short description.
    */
    string shortdesc;

    /**
        Long description.
    */
    string description;

    /**
        Description of a parameter.
    */
    DDOCParam[] parameters;

    /**
        Description of a return value.
    */
    string return_;

    /**
        Writes the DDOC documentation to the given writer.

        Params:
            buffer = The writer to write documentation to.
    */
    void writeTo(GDEWriter buffer) {
        if (shortdesc)
            buffer.writeln(shortdesc);
        
        
        if (description) {
            buffer.writenls();
            buffer.writeln(description);
        }
        

        if (parameters) {
            buffer.writenls();
            buffer.writeln("Params:");
            buffer.indent(4);

                size_t indentBy = nu_alignup(parameters.getLongestName() + 3, 4);
                foreach(param; parameters) {
                    size_t paramIndentBy = indentBy - param.name.length; 
                    
                    buffer.writef("%s = ", param.name);
                    buffer.postindent(paramIndentBy);
                    buffer.indent(4);
                        buffer.writeln(param.description);
                    buffer.unindent();
                }

            buffer.unindent();
        }
        
        if (return_) {
            buffer.writenls();
            buffer.writeln("Returns:");
            buffer.indent(4);
                buffer.writeln(return_);
            buffer.unindent();
        }
    }
}

/**
    A DDOC Parameter.
*/
struct DDOCParam {
    
    /**
        Name of the parameter.
    */
    string name;

    /**
        Description of the parameter.
    */
    string description;
}

/**
    Parses documentation for a node in the GDExtension schema.
*/
DDOC parseDocs(ref JSONValue gde) {
    DDOC result;
    if (gde.isGDEInterfaceDocSchema()) {
        
        // General description.
        if ("description" in gde) {
            foreach(line; gde["description"].array)
                result.description ~= line.str ~ "\n";
        }
        
        // Arguments.
        if ("arguments" in gde) {
            foreach(arg; gde["arguments"].array) {
                if ("description" in arg && "name" in arg) {
                    DDOCParam param;
                    param.name = arg["name"].str;

                    foreach(line; arg["description"].array)
                        param.description ~= line.str ~ "\n";
                    
                    result.parameters ~= param;
                }
            }
        }
        
        // Return values.
        if ("return_value" in gde && "description" in gde["return_value"]) {
            foreach(line; gde["return_value"]["description"].array)
                result.return_ ~= line.str ~ "\n";
        }
        return result;
    }

    // API Schema.
    if ("description" in gde) {
        result.description = gde["description"].toString();
    }
    return result;
}

private:

bool isGDEInterfaceDocSchema(ref JSONValue gde) {
    return 
        ("description" in gde && gde["description"].type == JSONType.array) ||
        ("arguments" in gde && gde["arguments"].type == JSONType.array) ||
        ("return_value" in gde);
}

size_t getLongestName(DDOCParam[] params) {
    size_t length;
    foreach(ref param; params) {
        if (param.name.length > length)
            length = param.name.length;
    }
    return length;
}