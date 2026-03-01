module generator.utils;
import generator.types;
import std.outbuffer;
import std.format;

/**
    Gets a parameter list from a slice of GDEFuncParam
    parameters.

    Params:
        params =    The parameter list.
        useNames =  Whether names should be added to the list.
    
    Returns:
        An array of parameters formatted as D parameters.
*/
string[] toParamList(GDEFuncParam[] params, bool useNames) {
    string[] result;
    foreach(param; params) {
        if (useNames && param.name)
            result ~= "%s %s".format(param.type.name, param.name);
        else
            result ~= param.type.name;
    }
    return result;
}

/**
    Finds all the types in the given slice that are
    implicitly castable to $(D T).

    Params:
        slice = The slice to search in.
*/
T[] findTypes(T, U)(U[] slice) {
    T[] result;
    foreach(item; slice)
        if (cast(T)item)
            result ~= cast(T)item;
    return result;
}

/**
    Peeks the given amount of characters from the given buffer.

    Params:
        buffer =    The string buffer to peek into.
        count =     The amount of characters to peek.
    
    Returns:
        A slice with as many characters as is requested if possible,
        otherwise as many as can be fetched are fetched.
*/
string peek(string buffer, size_t count) {
    import std.algorithm : min;
    return buffer[0..min(count, buffer.length)];
}

/**
    Pops the given characters off the string if found.
    
    Params:
        buffer =    The string buffer to pop from.
        wanted =    The wanted string.
    
    Returns:
        The wanted string if it was found,
        otherwise an empty string.
*/
string pop(ref string buffer, string wanted) {
    if (buffer.peek(wanted.length) == wanted) {
        buffer = buffer[wanted.length..$];
        return wanted;
    }
    return null;
}

/**
    Pops a valid C identifier from the buffer.
    
    Params:
        buffer =    The string buffer to pop from.
    
    Returns:
        The popped identifier.
*/
string popIdentifier(ref string buffer) {
    if (buffer.length == 0)
        return null;

    static bool isIden(char c, size_t i) {
        import std.ascii : isAlpha, isAlphaNum;
        return (i == 0 ? isAlpha(c) : isAlphaNum(c)) || c == '_';
    }

    size_t i = 0;
    while(i < buffer.length && isIden(buffer[i], i)) {
        i++;
    }
    
    string result = buffer[0..i].dup;
    buffer = buffer[i..$];
    return result;
}

/**
    Pops all the next whitespace characters from the buffer.
    
    Params:
        buffer =    The string buffer to pop from.
    
    Returns:
        The buffer.
*/
ref string popWhite(ref return string buffer) {
    import std.ascii : isWhite;
    size_t i = 0;
    while(i < buffer.length && isWhite(buffer[i])) { i++; }
    buffer = buffer[i..$];

    return buffer;
}

/**
    Converts the given array to strings, then joins them with
    the given joiner.

    Params:
        args =      The arguments to join.
        joiner =    The string to join them with.
    
    Returns:
        The joined string.
*/
string strJoin(T)(T[] args, string joiner) {
    import std.array : join;
    string[] rargs;
    foreach(arg; args) {
        rargs ~= arg.toString();
    }
    return rargs.join(joiner);
}