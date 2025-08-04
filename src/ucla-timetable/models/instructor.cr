class UCLA::Timetable
  struct Instructor
    include JSON::Serializable

    @[JSON::Field(key: "name")]
    getter names : Array(NameCollection)

    def name
      parts = names[0].names[0]
      if parts.middle_name.empty?
        "#{parts.first_name.capitalize} #{parts.last_name.capitalize}"
      else
        "#{parts.first_name.capitalize} #{parts.middle_name[0].upcase}. #{parts.last_name.capitalize}"
      end
    end

    def first_name
      names[0].names[0].first_name.capitalize
    end

    def last_name
      names[0].names[0].last_name.capitalize
    end
  end

  struct NameCollection
    include JSON::Serializable

    @[JSON::Field(key: "nameCollection")]
    getter names : Array(Name)
  end

  # pagination helper
  struct Name
    include JSON::Serializable

    @[JSON::Field(key: "firstName")]
    getter first_name : String

    @[JSON::Field(key: "middleName")]
    getter middle_name : String = ""

    @[JSON::Field(key: "lastName")]
    getter last_name : String
  end
end
