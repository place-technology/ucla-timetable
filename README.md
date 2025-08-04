# ucla-timetable

A crystal lang interface to UCLAs Class Schedule: https://developer.api.ucla.edu/api/261

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ucla-timetable:
       github: place-technology/ucla-timetable
   ```

2. Run `shards install`

## Usage

```crystal
require "ucla-timetable"

period_start = Time.local(UCLA::TIMEZONE).at_beginning_of_day
period_end = period_start.at_end_of_day

timetable = UCLA::Timetable.new("https://qa.api.ucla.edu", "client_id", "client_secret")
page_handler = timetable.list_classes
page_handler.each_published do |klass|
  events = klass.calendar_events(timetable, period_start, period_end)
  puts events
end
```

## Contributing

1. Fork it (<https://github.com/place-technology/ucla-timetable/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stephen von Takach](https://github.com/stakach) - creator and maintainer
