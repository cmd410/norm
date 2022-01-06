import nimib, nimibook


nbInit
nbUseNimibook

nbText: """
# Caveats
There are some caveats when working with norm that you need to consider and strategies to work around them.

## Managing data for Many-To-Many relationships
Support for Many-To-Many relationships has not yet been reached. You will have to set-up and manage the necessary "glue"-models yourself as if they were normal models.

## Fetching data from Many-To-One, Many-To-Many and unidirectional One-To-One relationships
One of the biggest caveats will be around fetching data from relationships where your model does not have a foreign key field to the other model whose data you want to query. There is no direct solution for this, but various ways to work around this.

### Fetching data for simple Many-To-One/Many-To-Many relationships
Say we have a `Producer` that produces various `Products`, a classic One (Producer) to Many (Products) relationship.
If you wanted to query the producer and all of their products in one go, you can still do that, but the other way around. Instead of querying for a producer and fetching all their products, you can query for all products of a given producer and fetch the data of the producer as shown in the Tutorial section.

"""
nbCode: 
  import std/json
  import norm/[model, sqlite]

  type Producer = ref object of Model
      name: string

  proc newProducer(name = ""): Producer = Producer(name: name)
    
  type Product = ref object of Model
      name: string
      producedBy: Producer

  proc newProduct(name = "", producedBy = newProducer()): Product = 
    result = Product(name: name, producedBy: producedBy)

  let dbConn = open(":memory:", "", "", "")

  let producerId = 1
  var producerProducts: seq[Product] = @[newProduct()]
  dbConn.select(producerProducts, "Product.producer = ?", producerId)

  echo %*producerProducts

nbText: """
Keep in mind though, that every `Producer` in a `Product` type will be its own object. Thus, if you were to manipulate the `Producer` object in the first entry in the `producerProducts` seq, that change will not be reflected in any of the other instances within that seq.

### Fetching data for more complex Many-To-One/Many-To-Many relationships
If you have multiple Many-To-X relationships that you want to query at once, you will need to make separate queries for each relationship. To keep the data together, you can make a new object-type that acts as a container for all the various queries. In this case, we add a `Employee` to the mix. We still want the data of the Producer, but now on top of the data of all their `Product`s we also want all of their `Employee`s. You can do this in a total of 3 queries (2 if you combine this with the previous approach, though this might be harder to maintain): 
"""

nbCode: 
  type Employee = ref object of Model
      name: string
      company: Producer
    
  proc newEmployee(name = "", company = newProducer()): Employee =
    result = Employee(name: name, company: company)

  type ProducerContainer = object
    producer: Producer
    products: seq[Product]
    employees: seq[Employee]

  var producer: Producer = newProducer()
  var products: seq[Product] = @[newProduct()]
  var employees: seq[Employee] = @[newEmployee()]
  
  dbConn.select(producer, "Producer.id = ?", producerId)
  dbConn.select(products, "producer = ?", producerId)
  dbConn.select(employees, "producer = ?", producerId)

  let producerContainer = ProducerContainer(
    producer: producer, 
    products: products,
    employees: employees
  )

  echo %*producerContainer

