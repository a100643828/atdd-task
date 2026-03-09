# DDD Component Patterns

## Entity (實體)

```ruby
# domains/{domain}/{aggregate}/entities/{entity}.rb

module Domain
  module Aggregate
    class Entity
      attr_reader :id, :attributes

      def initialize(id:, **attributes)
        @id = id
        @attributes = attributes
        validate!
      end

      private

      def validate!
        # Domain validation rules
      end
    end
  end
end
```

## Value Object (值物件)

```ruby
# domains/{domain}/{aggregate}/value_objects/{value_object}.rb

module Domain
  module Aggregate
    class ValueObject
      attr_reader :value

      def initialize(value)
        @value = value
        freeze
      end

      def ==(other)
        value == other.value
      end
    end
  end
end
```

## Use Case (使用案例)

繼承 `Boxenn::UseCase`，入口方法為 `def steps`，dependency 用 `option` 宣告。

```ruby
# domains/{domain}/{aggregate}/use_cases/{use_case}.rb

module Domain
  module Aggregate
    class MyUseCase < Boxenn::UseCase
      option :repository, default: -> { Repository.new }

      def steps(param1:, param2:)
        validated = yield validate(param1: param1)
        result = yield execute(validated, param2: param2)
        Success(result)
      end

      private

      def validate(param1:)
        # Return Success or Failure
      end

      def execute(validated, param2:)
        # Business logic
      end
    end
  end
end
```

## Service (服務)

```ruby
# domains/{domain}/{aggregate}/services/{service}.rb

module Domain
  module Aggregate
    class Service
      def initialize(dependencies)
        @dependencies = dependencies
      end

      def call(params)
        # Orchestrate multiple operations
      end
    end
  end
end
```

## Repository Interface (儲存庫介面)

```ruby
# domains/{domain}/{aggregate}/ports/i_{aggregate}_repository.rb

module Domain
  module Aggregate
    module Ports
      class IRepository
        def find(id)
          raise NotImplementedError
        end

        def save(entity)
          raise NotImplementedError
        end
      end
    end
  end
end
```

## Dry::Monads Pattern

All Use Cases must return `Dry::Monads::Result`:

```ruby
# Success
Success(value)

# Failure
Failure(error_hash)

# Using Do notation in steps
def steps(param1:)
  validated = yield validate(param1: param1)  # Returns early if Failure
  result = yield execute(validated)
  Success(result)
end
```
