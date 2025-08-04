class UCLA::Timetable
  # https://developer.api.ucla.edu/api/261#/Class%20Sections/ClassSections_GetClassSections
  struct ClassSection
    include JSON::Serializable

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter start_term_code : String

    @[JSON::Field(key: "classNumber")]
    getter class_number : String

    @[JSON::Field(key: "classSectionSessionDisplayFormat")]
    getter class_section_session_display_format : String

    @[JSON::Field(key: "classSectionCollection")]
    getter section_collection : Array(SectionNumber)

    def class_section_numbers
      section_collection.map(&.section_number)
    end

    def class_section_detail_links
      section_collection.map do |klass|
        klass.links.find! { |link| link.rel == "classSectionDetail" }.href
      end
    end

    def class_section_details : Array(Tuple(String, String, String, String))
      class_section_numbers.map do |number|
        {offered_term_code, subject_area_code, course_catalog_number, number}.map { |segment| URI.encode_path_segment(segment) }
      end
    end

    def class_section_details(timetable : Timetable) : Array(SectionDetail)
      class_section_detail_links.map do |link|
        timetable.request(NamedTuple(classSectionDetail: SectionDetail), link)[:classSectionDetail]
      end
    end
  end

  struct SectionNumber
    include JSON::Serializable

    @[JSON::Field(key: "classSectionNumber")]
    getter section_number : String

    # rels:
    # classSectionDetail: /sis/classsections/25f/a%26o%20sci/0001/001e/classsectiondetail/v1
    getter links : Array(Link)
  end

  struct SectionDetail
    include JSON::Serializable

    # ===================
    # Helper methods
    # ===================

    @[JSON::Field(ignore: true)]
    getter period_start : Time { Time.in(TIMEZONE).at_beginning_of_day }

    # period end is limited to
    @[JSON::Field(ignore: true)]
    property period_end : Time { period_start + 7.days }

    # def schedule
    #  meeting_rooms.select
    # end

    # ===================

    @[JSON::Field(key: "offeredTermCode")]
    getter offered_term_code : String

    @[JSON::Field(key: "subjectAreaCode")]
    getter subject_area_code : String

    @[JSON::Field(key: "courseCatalogNumber")]
    getter course_catalog_number : String

    @[JSON::Field(key: "courseStartTermCode")]
    getter start_term_code : String

    @[JSON::Field(key: "classSectionNumber")]
    getter section_number : String

    @[JSON::Field(key: "classSectionNumberDisplay")]
    getter section_number_display : String

    @[JSON::Field(key: "classSectionID")]
    getter class_section_id : String

    @[JSON::Field(key: "classSectionSessionDisplayFormat")]
    getter session_display_format : String

    @[JSON::Field(key: "concurrentEnrollmentFlag")]
    getter concurrent_enrollment_flag : String

    @[JSON::Field(key: "classSectionActivityCode")]
    getter section_activity_code : String

    @[JSON::Field(key: "classSectionActivityEnrollmentSequenceNumber")]
    getter section_activity_enrollment_sequence_number : String

    @[JSON::Field(key: "classSectionPrimaryActivityFlag")]
    getter section_primary_activity_flag : String

    @[JSON::Field(key: "classSectionGradeTypeCode")]
    getter section_grade_type_code : String

    @[JSON::Field(key: "classSectionUnitTypeCode")]
    getter section_unit_type_code : String

    @[JSON::Field(key: "classSectionOnlineFlag")]
    getter section_online_flag : String

    @[JSON::Field(key: "classSectionEnrollmentStatusCode")]
    getter enrollment_status_code : String

    @[JSON::Field(key: "classSectionSchedulePrintCode")]
    getter schedule_print_code : String

    # List of instructors running the course
    @[JSON::Field(key: "instructorUCLAIDCollection")]
    getter instructors : Array(InstructorUCLAID)

    @[JSON::Field(key: "classSectionCombinedMeetingId")]
    getter section_combined_meeting_id : String

    # List of meeting rooms
    @[JSON::Field(key: "classSectionMeetingCollection")]
    getter meeting_rooms : Array(SectionMeetingRoom)
  end

  struct InstructorUCLAID
    include JSON::Serializable

    @[JSON::Field(key: "uclaid")]
    getter ucla_id : String

    # it's called links but only has a single link
    @[JSON::Field(key: "links")]
    getter link : Link
  end

  struct SectionMeetingRoom
    include JSON::Serializable

    @[JSON::Field(key: "classSectionMeetingDaysofWeekCode")]
    getter days_of_week_code : String

    @[JSON::Field(key: "classSectionMeetingStartTime")]
    getter start_time : String

    @[JSON::Field(key: "classSectionMeetingStopTime")]
    getter stop_time : String

    @[JSON::Field(key: "classSectionBuildingCode")]
    getter building_code : String

    @[JSON::Field(key: "classSectionBuildingRoomCode")]
    getter room_code : String

    DAYS_CODE_MAP = {
      'M' => Time::DayOfWeek::Monday,
      'T' => Time::DayOfWeek::Tuesday,
      'W' => Time::DayOfWeek::Wednesday,
      'R' => Time::DayOfWeek::Thursday,
      'F' => Time::DayOfWeek::Friday,
      'S' => Time::DayOfWeek::Saturday,
      'U' => Time::DayOfWeek::Sunday,
    }

    def days_of_week : Array(Time::DayOfWeek)
      days_of_week_code.chars.map { |c| DAYS_CODE_MAP[c]? }.compact
    end

    def expand_range(period_start : Time, period_end : Time) : Array(CalendarEntry)
      entries = [] of CalendarEntry
      days = days_of_week

      # Loop from period_start to period_end, one day at a time
      current_day = period_start.at_beginning_of_day
      while current_day <= period_end
        if days.includes?(current_day.day_of_week)
          # Parse time strings into Time objects on the current day
          begin
            current_date = current_day.to_s("%Y-%m-%d")
            event_start = Time.parse("#{current_date} #{start_time}", "%Y-%m-%d %I:%M%p", TIMEZONE)
            event_end = Time.parse("#{current_date} #{stop_time}", "%Y-%m-%d %I:%M%p", TIMEZONE)

            # Only add if within the overall bounds
            if event_end > period_start && event_start < period_end
              entries << CalendarEntry.new(
                building_code,
                room_code,
                event_start,
                event_end
              )
            end
          rescue ex : Time::Format::Error
            # You could log or raise depending on how you want to handle bad formats
            raise "Invalid time format in start_time (#{start_time}) or stop_time (#{stop_time}): #{ex.message}"
          end
        end
        current_day += 1.day
      end

      entries
    end
  end
end
