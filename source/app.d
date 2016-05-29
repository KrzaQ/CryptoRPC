import std.stdio;

import deserializer;


void foo()
{
}

@Register
void bar()
{
}

@Register("bazz")
void baz()
{
}

void main()
{
}


shared static this()
{

}

mixin(registerFunctions);
