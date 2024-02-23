module TestProject

"""Print a "Hello World" message.

```hello_world()```

prints "Hello World"
"""
function hello_world()
    println("Hello World")
end

"""A World

```julia
world = World("Earth")
```
"""
struct World
    name::String
end

"""The `World("Earth")`."""
EARTH = World("Earth")

"""
```julia
hello_world(world)
```

prints a "Hello" message for a specific [`World`](@ref).
"""
function hello_world(world::World)
    println("Hello $(world.name)")
end


end
