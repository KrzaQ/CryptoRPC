module deserializer;

struct Register
{
	string name;
}

public struct Result(T)
{
	T Result;
}

public string call(string name, string json){
	return registry.call(name, json);
}

private struct Registry
{
	alias func = string function(string);
	
	func[string] map;

	shared void register(string name, func f){
		if(name in map){
			import std.stdio;
			stderr.writefln("Function '%s' already registered.", name);
		}
		map[name] = f;
	}

	shared string call(string name, string json) const {
		if(auto ptr = name in map){
			return (*ptr)(json);
		}else{
			import std.format;
			throw new Exception(`Function '%s' not found!`.format(name));
		}
	}
}

shared Registry registry;

private alias Id(alias T) = T;

private enum functionToName(alias func) = (&func).stringof[2..$];

private string makeParamsStruct(alias func)()
{
	import std.traits;
	alias ParamNames = ParameterIdentifierTuple!func;
	alias ParamTypes = Parameters!func;

	static assert(ParamNames.length == ParamTypes.length);

	string structDef = "static struct ParamStruct{ \n";
	foreach(i, m; ParamNames){
		structDef ~= `	` ~ ParamTypes[i].stringof ~ ` ` ~ m ~ ";\n";
	}

	structDef ~= "}\n";
	return structDef;
}

void registerFunction(alias func)()
{
	import std.traits;
	alias UDAs = getUDAs!(func, Register);

	static if(UDAs.length == 1){
		string name = UDAs[0].name;
	}else{
		string name = functionToName!func;
	}
	mixin(makeParamsStruct!func);

	auto wrapper = function string(string json){
		import painlessjson : fromJSON, toJSON;
		import std.json : parseJSON;
		import std.conv;
		ParamStruct params = fromJSON!ParamStruct(parseJSON(json));

		alias ParamTypes = Parameters!func;
		ParamTypes ps;

		foreach(i, string fldname; FieldNameTuple!ParamStruct){
			ps[i] = __traits(getMember, params, fldname);
		}

		alias ResultOf = ReturnType!func;

		static if(is(ResultOf == void)){
			Result!string res;
			func(ps);
		}else{
			Result!ResultOf res;
			res.Result = func(ps);
		}
		return res.toJSON.to!string;
	};

	registry.register(name, wrapper);
}

public string registerFunctionsImpl(alias Module)()
{
	import std.stdio;
	string res = "shared static this () {\n" ~
		"import std.stdio;\n" ~
		"import std.traits;\n";
	foreach (immutable m; __traits(derivedMembers, Module)) {
		static if (is(typeof(__traits(getMember, Module, m)))) {
			alias mem = Id!(__traits(getMember, Module, m));
			static if (__traits(isStaticFunction, mem)) {
				res ~= "static if(hasUDA!(" ~ m ~ ", Register)) registerFunction!(" ~ m ~ ")();\n";
			}
		}
	}
	res ~= "}\n";
	return res;
}

enum registerFunctions = "static import deserializer; mixin(deserializer.registerFunctionsImpl!(mixin(__MODULE__)));";
