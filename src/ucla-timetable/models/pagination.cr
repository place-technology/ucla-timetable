class UCLA::Timetable
  struct Link
    include JSON::Serializable

    getter href : String
    getter rel : String
    getter method : String
  end

  abstract struct ListResponse
    include JSON::Serializable

    @[JSON::Field(key: "totalRecords")]
    getter total_records : Int32

    @[JSON::Field(key: "totalPages")]
    getter total_pages : Int32

    @[JSON::Field(key: "pageNumber")]
    getter page_number : Int32

    @[JSON::Field(key: "pageSize")]
    getter page_size : Int32

    getter links : Array(Link)

    @[JSON::Field(ignore: true)]
    property! timetable : Timetable

    def set_timetable(timetable : Timetable)
      @timetable = timetable
      self
    end

    macro inherited
      def next_page
        link = links.find { |link| link.rel == "nextPage" }
        return unless link
        timetable.request(self.class, link.href, link.method)
      end
    end
  end
end
