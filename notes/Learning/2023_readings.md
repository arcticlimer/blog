---
date: 2023-01-20T21:55
title: 2023 Readings
---

Instead of making a reading list this year, I will focus on writing summaries
about books that I've read and keep up piling them up in this page, along with
the time period in which I've read them.

# The Little Ecto Cookbook (January 2023)

The *Little Ecto Cookbook* is a short book that focus on leveraging less-known
features of [Ecto](https://hexdocs.pm/ecto/Ecto.html) when building systems that
use it. It shows how Ecto is non an *Object Relational Mapper* (ORM) but rather
just a data mapper that happens to allow you to make queries in your database.
Ecto by itself can be very useful for validating user-inputted data, such as in
API controllers, even when you are not dealing with a database directly. 

It also shows how to make great use of transactions to improve error handling
and how Ecto queries can be composed in order to build specialized query on top
of generic ones. The book showcases different ways of handling database
relationships with Ecto and also introduces the concept of *upserts* for dealing
with concurrency issues and functions such as `Repo.update_all` for batch
updating/inserting different records. 

In the last chapters, it shows how multi-tenancy can be achieved in Ecto and
also how to setup it to read from different replicas.

# Concurrent Data Processing with Elixir (January 2023)

This book is a really cool overview of how Elixir and the BEAM come into play
when the subject is leveraging hardware and CPU cores for maximum performance.
Even though the BEAM is not that fast, this book shows that is incredibly simple
to build simple and complex data processing pipelines that will use 100% of your
CPU if needed (no matter how many cores you have), while handling backpressure
to keep your machine running smooth. 

The book builds some small little projects while showcasing different libraries
for the user, making it a very interactive learning experience. It starts by
showing off processes, which are the basic building blocks of concurrency in the
BEAM and then proceeds to introduce Tasks, a very simple way of handling async
work that can be parallelized and after that introduces `GenStages`. 

`GenStages` the basic building block that the next steps of the book build upon,
being a powerful abstraction to create a consumer-producer architecture, where
the data flow is managed by the consumers (who ask for the data when needed). 

Later on, the `Flow` library is introduced, which is a library that works almost
as a drop-in replacement for the `Enum` module and can use your entire CPU
capacity when working on large sequences of data. 

In the last chapter, the `Broadway` library is shown as a powerful consumer for
multiple kinds of producers, such as messages brokers *(Kafka, RabbitMQ, SQS)*
or even other `GenStage` producers already in your codebase.
