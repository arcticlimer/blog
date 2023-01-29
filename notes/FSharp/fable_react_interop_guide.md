---
date: 2023-01-25T17:30
title: Fable + React Interop Guide
---

F# has a pretty good interoperability with Javascript when using the Fable
library. When building user interfaces using React, there are multiple
alternatives, but the necessary resources to build solutions using Fable seem
scattered around the internet.

This document aims to provide a solid getting started to both Fable and Feliz,
and how to use both in order to interoperate F# with an existing React library.

# Fable
[Fable](https://fable.io/) is a library that allows one to write F# code while
using existing web solutions in the Javascript ecossystem. It also allows one to
export libraries that can be called from Javascript code.

As seem in the "[Call JS from
Fable](https://fable.io/docs/communicate/js-from-fable.html)", there are
multiple ways of importing generic JS objects into our project, this document
will use `ImportAttribute` to import objects.

Note that by default, we don't have any types when importing and giving data to
JS objects, but we can easily add types on the F# side to have a type-safe
experience when developing with Fable, for example:

```ts
// File.ts

interface MyInterface {
  name: string
  lastName: string
}

let myObject: MyInterface = {name: "john", lastName: "bar"}

export const myObject;
```

```fsharp
// my-file.fs

type Interface = {
  name: string
  lastName: string
}

[<Import("default", from="./my-file.js")>]
let myObject: Interface = jsNative

// Now we can use myObject directly from JS in a type-safe way
```

# Feliz

[Feliz](https://zaid-ajaj.github.io/Feliz/) is a library used to directly
interface React, adding the ability to create new type-safe components directly
by using F# or using already existing components defined in other languages.

We can define new React components in F# using the `ReactComponent` attribute,
for example: 

```fsharp
/// <summary>
/// A stateful React component that maintains a counter
/// </summary>
[<ReactComponent>]
static member Counter() =
    let (count, setCount) = React.useState(0)
    Html.div [
        Html.h1 count
        Html.button [
            prop.onClick (fun _ -> setCount(count + 1))
            prop.text "Increment"
        ]
    ]
```

In order to import existing components from other libraries, we also use
`<ReactComponent>`:

```fsharp
[<ReactComponent(import="default", from="react-markdown")>]
static member Markdown(children: string, remarkPlugins: obj seq) = React.imported()
```

> Note that in this case, we pass import="default" since it is a default export,
> when dealing with named exports, import should receive the name of the
> exported value.

# Asynchronous F# Code in Feliz
Since callbacks can be asynchronous, we use React's `useEffect` to execute
our asynchronous F# code and set the data that we need using `useState`.

Below is an example of a Feliz component that fetches products from a remote API
asynchronously and then renders them on screen.

```fsharp
[<ReactComponent>]
static member ApiCall() =
    let (products, setProducts) = React.useState([| |])

    let fetchProducts = async {
      let! products = fetch "/api/products"
      setProducts(products)
    } |> Async.StartImmediate

    React.useEffect(fetchProducts, [| |])

    let productElements = List.map products (fun p -> 
      Html.div [
        Html.h2 [
          prop.text p.name
        ]
        Html.p [
          prop.text p.description
        ]
      ]
    )

    Html.div productElements
```
