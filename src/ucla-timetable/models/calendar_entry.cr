class UCLA::Timetable
  class CalendarEntry
    include JSON::Serializable
    include Comparable(self)

    property host : String? = nil
    property title : String? = nil
    property subject_code : String? = nil
    property course_number : String? = nil
    property term_code : String? = nil
    property body : String? = nil

    property event_start : Time
    property event_end : Time

    property building_code : String
    property room_code : String

    def initialize(@building_code, @room_code, @event_start, @event_end)
    end

    def <=>(other : self)
      event_start <=> other.event_start
    end

    getter room_key : String do
      "#{self.building_code}-#{self.room_code}".downcase
    end

    def_equals @building_code, @room_code, @event_start, @event_end
  end
end
