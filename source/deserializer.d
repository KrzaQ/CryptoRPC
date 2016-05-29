module cryptorpc;



public
void registerFunctionsImpl(string Module)()
{
	pragma (msg, Module);
	import mixin("import \"" ~ Module ~ "\"");
	foreach(m; __traits(allMembers, mixin(Module))) 
	{
		static if (__traits(isStaticFunction, __traits(getMember, mixin(Module), m))) 
			writeln(m);	 
	}
}

public
string registerFunctions()
{
	return "shared static this() {registerFunctionsImpl!__MODULE__(); }";
}
