/// @return YAML string that encodes the struct/array nested data
///         WARNING! This script does not cover 100% of the YAML specification. Contact @jujuadams if you'd like to request additional features
/// 
/// @param struct/array          The data to be encoded. Can contain structs, arrays, strings, and numbers.   N.B. Will not encode ds_list, ds_map etc.
/// @param [alphabetizeStructs]  (bool) Sorts struct variable names is ascending alphabetical order as per ds_list_sort(). Defaults to <false>
/// 
/// @jujuadams 2020-05-02

function snap_to_yaml_string()
{
    var _ds          = argument[0];
    var _alphabetise = ((argument_count > 1) && (argument[1] != undefined))? argument[1] : false;
    
    return (new __snap_to_yaml_string_parser(_ds, _alphabetise)).result;
}

function __snap_to_yaml_string_parser(_ds, _alphabetise) constructor
{
    root        = _ds;
    alphabetise = _alphabetise;
    
    result = "";
    buffer = buffer_create(1024, buffer_grow, 1);
    indent = "";
    
    static parse_struct = function(_struct)
    {
        var _names = variable_struct_get_names(_struct);
        var _count = array_length(_names);
        var _i = 0;
        
        if (alphabetise)
        {
            var _list = ds_list_create();
            
            repeat(_count)
            {
                _list[| _i] = _names[_i];
                ++_i;
            }
            
            ds_list_sort(_list, true);
            
            var _i = 0;
            repeat(_count)
            {
                _names[@ _i] = _list[| _i];
                ++_i;
            }
            
            ds_list_destroy(_list);
            var _i = 0;
        }
        
        if (_count > 0)
        {
            indent += "  ";
            buffer_write(buffer, buffer_text, "\n");
            
            repeat(_count)
            {
                var _name = _names[_i];
                value = variable_struct_get(_struct, _name);
                    
                if (is_struct(_name) || is_array(_name))
                {
                    show_error("Key type \"" + typeof(_name) + "\" not supported\n ", false);
                    _name = string(ptr(_name));
                }
                
                buffer_write(buffer, buffer_text, indent);
                buffer_write(buffer, buffer_text, string(_name));
                buffer_write(buffer, buffer_text, ": ");
                write_value();
                buffer_write(buffer, buffer_text, "\n");
                
                ++_i;
            }
                
            indent = string_copy(indent, 1, string_length(indent) - 2);
            buffer_seek(buffer, buffer_seek_relative, -2);
            //buffer_write(buffer, buffer_text, "\n" + indent);
        }
        else
        {
            buffer_write(buffer, buffer_text, "{}");
        }
    }
    
    
    
    static parse_array = function(_array)
    {
    
        var _count = array_length(_array);
        var _i = 0;
        
        if (_count > 0)
        {
            indent += "  ";
            buffer_write(buffer, buffer_text, "\n");
            
            repeat(_count)
            {
                value = _array[_i];
                
                buffer_write(buffer, buffer_text, indent);
                buffer_write(buffer, buffer_text, "- ");
                write_value();
                buffer_write(buffer, buffer_text, "\n");
                
                ++_i;
            }
                
            indent = string_copy(indent, 1, string_length(indent) - 2);
            buffer_seek(buffer, buffer_seek_relative, -2);
            //buffer_write(buffer, buffer_text, "\n" + indent);
        }
        else
        {
            buffer_write(buffer, buffer_text, "[]");
        }
    }
    
    
    
    static write_value = function()
    {
        if (is_struct(value))
        {
            parse_struct(value);
        }
        else if (is_array(value))
        {
            parse_array(value);
        }
        else if (is_string(value))
        {
            //Sanitise strings
            value = string_replace_all(value, "\\", "\\\\");
            value = string_replace_all(value, "\n", "\\n");
            value = string_replace_all(value, "\r", "\\r");
            value = string_replace_all(value, "\t", "\\t");
            value = string_replace_all(value, "\"", "\\\"");
            
            buffer_write(buffer, buffer_text, value);
        }
        else if (is_undefined(value))
        {
            buffer_write(buffer, buffer_text, "null");
        }
        else if (is_bool(value))
        {
            buffer_write(buffer, buffer_text, value? "true" : "false");
        }
        else if (is_real(value))
        {
            //Strip off trailing zeroes, and if necessary, the decimal point too
            value = string_format(value, 0, 10);
            
            var _length = string_length(value);
            var _i = _length;
            repeat(_length)
            {
                if (string_char_at(value, _i) != "0") break;
                --_i;
            }
            
            if (string_char_at(value, _i) == ".") _i--;
            
            value = string_delete(value, _i + 1, _length - _i);
            
            buffer_write(buffer, buffer_text, value);
        }
        else
        {
            buffer_write(buffer, buffer_text, string(value));
        }
    }
    
    
    
    if (is_struct(root))
    {
        parse_struct(root);
    }
    else if (is_array(root))
    {
        parse_array(root);
    }
    else
    {
        show_error("Value not struct or array. Returning empty string\n ", false);
    }
    
    
    
    buffer_seek(buffer, buffer_seek_start, 0);
    result = buffer_read(buffer, buffer_string);
    buffer_delete(buffer);
}