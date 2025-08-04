require "./pagination"

class UCLA::Timetable
  # pagination helper
  struct ClassResponse < ListResponse
    getter classes : Array(ClassInfo)

    # run through each class that should be displayed
    # grabbing the next page as required
    def each_published(&)
      response = self
      while response
        response.classes.each do |klass|
          next unless klass.published?
          yield klass
        end
        response = response.next_page
      end
    end
  end

  struct ClassInfo
    include JSON::Serializable

    @[JSON::Field(key: "classSessionDisplayFormat")]
    getter display_format : String # "Official Format"

    def published?
      display_format == "Official Format"
    end

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseCatalogNumberDisplay")]
    getter course_catalog_number_display : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter course_start_term : String

    @[JSON::Field(key: "termSessionGroupCollection")]
    getter session_groups : Array(SessionGroup) { [] of SessionGroup }

    # rels:
    # courseDetail: /sis/courses/a%26o%20sci/0001/04f/coursedetail/v1
    getter links : Array(Link)

    # returns a list that can be used to grab the ClassDetails or ClassSection
    def class_details : Array(Tuple(String, String, String, String))
      session_groups.flat_map do |session|
        session.class_numbers.map do |number|
          {offered_term_code, subject_area_code, course_catalog_number, number}.map { |segment| URI.encode_path_segment(segment) }
        end
      end
    end

    def class_details_links : Array(String)
      session_groups.flat_map(&.class_detail_links)
    end

    def class_details(timetable : Timetable) : Array(ClassDetails)
      class_details_links.map do |link|
        timetable.request(NamedTuple(classDetail: ClassDetails), link)[:classDetail]
      end
    end

    def class_section_links : Array(String)
      session_groups.flat_map(&.class_section_links)
    end

    def class_sections(timetable : Timetable) : Array(ClassSection)
      class_section_links.map do |link|
        timetable.request(NamedTuple(classSection: ClassSection), link)[:classSection]
      end
    end

    def class_section_details(timetable : Timetable) : Array(SectionDetail)
      class_sections(timetable).flat_map do |section|
        section.class_section_details(timetable)
      end
    end

    EMPTY_ENTRY = [] of CalendarEntry

    def calendar_events(timetable : Timetable, period_start : Time, period_end : Time) : Array(CalendarEntry)
      class_details(timetable).flat_map do |details|
        next EMPTY_ENTRY unless details.starting < period_end && details.ending > period_start

        title = details.class_title
        description = details.class_description

        details.class_section_details(timetable).flat_map do |section|
          instructors = section.instructors.compact_map do |instruct|
            timetable.get_instructor_details(instruct.ucla_id).try(&.name)
          end

          section.meeting_rooms.flat_map do |room|
            room.expand_range(period_start, period_end).tap(&.each { |entry|
              entry.title = title
              entry.body = description.presence
              entry.host = instructors[0]?
            })
          end
        end
      end
    end
  end

  struct SessionGroup
    include JSON::Serializable

    @[JSON::Field(key: "termsessionGroupCode")]
    getter group_code : String

    @[JSON::Field(key: "termsessionInstructionWeeks")]
    getter instruction_weeks : String

    @[JSON::Field(key: "termsessionGroupWeekCode")]
    getter week_code : String

    @[JSON::Field(key: "classCollection")]
    getter class_collection : Array(ClassNo)

    def class_numbers
      class_collection.map(&.class_number)
    end

    def class_detail_links
      class_collection.map do |klass|
        klass.links.find! { |link| link.rel == "classDetail" }.href
      end
    end

    def class_section_links
      class_collection.map do |klass|
        klass.links.find! { |link| link.rel == "classSections" }.href
      end
    end
  end

  struct ClassNo
    include JSON::Serializable

    @[JSON::Field(key: "classNumber")]
    getter class_number : String

    # rels:
    # classDetail: /sis/classes/25f/a%26o%20sci/0001/001/classdetail/v1
    # classSections: /sis/classsections/25f/a%26o%20sci/0001/001/v1
    getter links : Array(Link)
  end

  struct ClassDetails
    include JSON::Serializable

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter course_start_term_code : String

    @[JSON::Field(key: "classNumber")]
    getter class_number : String

    @[JSON::Field(key: "classNumberDisplay")]
    getter class_number_display : String

    @[JSON::Field(key: "classDescription")]
    getter class_description : String

    @[JSON::Field(key: "classTitle")]
    getter class_title : String

    @[JSON::Field(key: "classSessionCode")]
    getter class_session_code : String

    @[JSON::Field(key: "classSessionDisplayFormat")]
    getter class_session_display_format : String

    @[JSON::Field(key: "classSchedulePrintCode")]
    getter class_schedule_print_code : String

    @[JSON::Field(key: "classStartDate")]
    getter class_start_date : String

    @[JSON::Field(key: "classEndDate")]
    getter class_end_date : String

    @[JSON::Field(key: "classWebsite")]
    getter class_website : String

    # rels:
    # classFinalExam: /sis/classes/25f/a%26o%20sci/0001/001/classfinalexam/v1
    getter links : Array(Link)

    # returns a list that can be used to grab the ClassDetails or ClassSection
    def class_details : Tuple(String, String, String, String)
      {offered_term_code, subject_area_code, course_catalog_number, class_number}.map { |segment| URI.encode_path_segment(segment) }
    end

    def class_section(timetable : Timetable) : ClassSection
      timetable.get_class_section(*class_details)
    end

    def class_section_details(timetable : Timetable) : Array(SectionDetail)
      class_section(timetable).class_section_details(timetable)
    end

    def starting : Time
      Time.parse(class_start_date, "%Y-%m-%d", TIMEZONE)
    end

    def ending : Time
      Time.parse(class_end_date, "%Y-%m-%d", TIMEZONE).at_end_of_day
    end
  end
end
